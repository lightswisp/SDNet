#!/usr/bin/ruby

require_relative "../../utils/tls"

#===============================================================#

PUBLIC_IP = `curl -s ifconfig.me`
MAX_BUFFER = 1024 * 640 # 640KB
PORT = 4433 # Don't change this, because this server imitates the real https server
CONN_OK = "HTTP/1.1 200 OK\r\nDate: #{Time.now}\r\n\r\n"
CONN_FAIL = "HTTP/1.1 502 Bad Gateway\r\nDate: #{Time.now}\r\n\r\n<h1>502 Bad Gateway</h1>"

#===============================================================#

def handler(tls_connection, logger)
	logger.info("New client #{tls_connection.peeraddr[-1]}".green.bold)
	request = tls_connection.readpartial(MAX_BUFFER)
	
	if request.nil? || request.empty?
		logger.warn("[WARNING] Empty request!".red.bold)
		tls_connection.close if tls_connection
		Thread.exit
	end

	request_head = request.split("\r\n")
	request_method = request_head.first.split(" ").first

	if request_method =~ /CONNECT/
		# a bit of parsing
		request_host, request_port = request_head.first.split(' ')[1].split(':')
		
		endpoint_connection = TCPSocket.new(request_host, request_port)
    endpoint_connection.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
		if endpoint_connection
			tls_connection.puts(CONN_OK)
		else
			tls_connection.puts(CONN_FAIL)
			tls_connection.close
			Thread.exit
		end

		begin
			loop do
				fds = IO.select([tls_connection, endpoint_connection], nil, nil, 10)
				if fds[0].member?(tls_connection)
					buf = tls_connection.readpartial(MAX_BUFFER)
					endpoint_connection.print(buf)
				elsif fds[0].member?(endpoint_connection)
					buf = endpoint_connection.readpartial(MAX_BUFFER)
					tls_connection.print(buf)
				end
			end
		rescue StandardError
			logger.info("Closing connection with #{request_host}:#{request_port}".red.bold)
			endpoint_connection.close if endpoint_connection
			tls_connection.close if tls_connection
			Thread.exit
		end

		
	else # NON CONNECT
		host = request_head[1].downcase.gsub('host:', '').strip
    request_host, request_port = host.split(':')
    request_port = 80 if request_port.nil?
    request_port = request_port.to_i

		if request_host == PUBLIC_IP
			# TODO 
			# Show the webpage
			tls_connection.close
			Thread.exit
		end

    begin
	    endpoint_connection = TCPSocket.new(request_host, request_port)
	    logger.info("#{endpoint_host}:#{endpoint_port}".bold.green)
	    endpoint_connection.puts(request)
	    response = endpoint_connection.readpartial(MAX_BUFFER)
	    tls_connection.puts(response)
	    tls_connection.close
	    Thread.exit
    rescue StandardError
      logger.warn("#{endpoint_host}:#{endpoint_port}".bold.red)
      tls_connection.puts(CONN_FAIL)
      tls_connection.close if tls_connection
      Thread.exit
    end
		

	end
	 
end

server = TLSServer.new(PORT)
server.start(:handler)

