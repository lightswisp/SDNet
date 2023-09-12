require_relative "tls"

class LocalProxy
	def initialize(port, layer_2_nodes_list, max_buffer, logger)
		@port = port
		@layer_2_nodes_list = layer_2_nodes_list
		@max_buffer = max_buffer
		@logger = logger
		@proxy = TCPServer.new(@port)

		@temp_server = @layer_2_nodes_list.sample
	end

	def is_alive?(ssl, payload)
	  ssl.puts(payload)
	  begin
	    response = ssl.readpartial(@max_buffer)
	  rescue StandardError
	    return nil
	  end
	  response
	end

	def start
		loop do
			connection = @proxy.accept
			Thread.new do
				request = connection.recv(@max_buffer)
				Thread.exit if request.empty? || request.nil?
				request_head = request.split("\r\n")
				request_method = request_head.first.split(" ").first
				request_host, request_port = request_head.first.split(' ')[1].split(':')

				if request_method =~ /CONNECT/

					client = TLSClient.new(@temp_server["ip"], @temp_server["port"], @temp_server["sni"])
					ssl = client.connect
					if !ssl
						@logger.fatal("Failed to connect to #{temp_server['ip']}".bold.red)
						Thread.exit
					end

					if header = is_alive?(ssl, request)
						@logger.info("[CONNECT] #{request_host}:#{request_port}".bold.green)
						connection.puts(header)
					else
						@logger.fatal("[CONNECT] #{request_host}:#{request_port} is unavailable!".bold.red)
						ssl.close
						connection.close
						Thread.exit
					end

					begin
						loop do
							fds = IO.select([connection, ssl], nil, nil, 10)
							if fds[0].member?(connection)
								buf = connection.readpartial(@max_buffer)
								ssl.print(buf)
							elsif fds[0].member?(ssl)
								buf = ssl.readpartial(@max_buffer)
								connection.print(buf)
							end
						end
					rescue StandardError
						@logger.info("Closing the connection with #{request_host}:#{request_port}".bold.red)
						ssl.close
						connection.close
						Thread.exit
					end

				else 
					# NON CONNECT HERE
					client = TLSClient.new(@temp_server["ip"], @temp_server["port"], @temp_server["sni"])
					ssl = client.connect
					if !ssl
						@logger.fatal("Failed to connect to #{temp_server['ip']}".bold.red)
						Thread.exit
					end

					method = request.split("\n")[0] 
					method_type = method.split(" ").first
		      host = request.split("\n")[1].downcase.gsub('host:', '').strip
		      request_host, request_port = host.split(':')
		      request_port = 80 if request_port.nil?
		      request_port = request_port.to_i

		      ssl.puts(request)
		      begin
						response = ssl.readpartial(@max_buffer)
						connection.puts(response)
						@logger.info("#{method_type} #{request_host}:#{request_port}".bold.green)
		      rescue StandardError
						@logger.fatal("[#{method_type}] failed to connect #{request_host}:#{request_port}".bold.red)
					ensure
						connection.close
		      end
				end 
			end
			
		end
	end

	def rotate
		rotated = (@layer_2_nodes_list - [@temp_server]).sample
		@temp_server = rotated
	end
end
