#!/usr/bin/ruby

require "optparse"
require "net/http"
require_relative "utils/proxy"
require_relative "../../webserver/webserver"
include WebServer

ARGV << '-h' if ARGV.empty?
OPTIONS = {}

OptionParser.new do |opts|
  opts.banner = "SDNET Layer 2\n\n".bold + 'Usage: ./server.rb [options]'

  opts.on('-h', '--help', 'Prints help') do
    puts opts
    puts
    exit
  end

  opts.on('-aADDR', '--address=ADDR',
          'Dispatcher address, example: ./server.rb --address 177.68.54.30') do |addr|
    OPTIONS[:addr] = addr
  end

   opts.on('-dADDR', '--dport=ADDR',
          'Dispatcher port, example: ./server.rb --dport 443') do |dport|
    OPTIONS[:dport] = dport.to_i
  end

  opts.on('-pPORT', '--port=PORT',
          'Port for listening, example: ./server.rb --port 443') do |port|
    OPTIONS[:port] = port.to_i
  end

  opts.on('-sSNI', '--sni=SNI', 'TLS SNI, just enter your current server domain name, example: ./server.rb --sni google.com') do |sni|
    OPTIONS[:sni] = sni
  end
end.parse!


PUBLIC_IP = Net::HTTP.get URI "https://api.ipify.org"
MAX_BUFFER = 1024 * 640 # 640KB
CONN_OK = "HTTP/1.1 200 OK\r\nDate: #{Time.now}\r\n\r\n"
CONN_FAIL = "HTTP/1.1 502 Bad Gateway\r\nDate: #{Time.now}\r\n\r\n<h1>502 Bad Gateway</h1>"


def handler(tls_connection, logger)
	logger.info("New client #{tls_connection.peeraddr[-1]}".green.bold)
	request = tls_connection.readpartial(MAX_BUFFER)
	
	if request.nil? || request.empty?
		logger.warn("WARNING Empty request!".yellow.bold)
		tls_connection.close if tls_connection
		Thread.exit
	end

	request_head = request.split("\r\n")
	request_method = request_head.first.split(" ").first
	
	case request_method
		when /CONNECT/
			request_host, request_port = request_head.first.split(' ')[1].split(':')		
			endpoint_connection = TCPSocket.new(request_host, request_port)
	    #endpoint_connection.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
			if endpoint_connection
				tls_connection.puts(CONN_OK)
			else
				tls_connection.puts(CONN_FAIL)
				tls_connection.close
				Thread.exit
			end

			begin
				loop do
					fds = IO.select([tls_connection, endpoint_connection], nil, nil, 15)
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
		when /DISPATCHER_PING/
			logger.info("Received DISPATCHER_PING from #{OPTIONS[:addr]}")
			tls_connection.puts("DISPATCHER_PONG")
			tls_connection.close
		else
			host = request_head[1].downcase.gsub('host:', '').strip
	    request_host, request_port = host.split(':')
	    request_port = 80 if request_port.nil?
	    request_port = request_port.to_i

			if request_host == PUBLIC_IP
				logger.info("New website visitor #{tls_connection.peeraddr[-1]}, lets do some magic :)".green.bold)
				response = WebServer.response(request_head.first, 2, logger)
				tls_connection.puts(response)
				tls_connection.close
				Thread.exit
			end

	    begin
		    endpoint_connection = TCPSocket.new(request_host, request_port)
		    logger.info("#{request_host}:#{request_port}".bold.green)
		    endpoint_connection.puts(request)
		    response = endpoint_connection.readpartial(MAX_BUFFER)
		    tls_connection.puts(response)
		    tls_connection.close
		    Thread.exit
	    rescue StandardError
	      logger.warn("#{request_host}:#{request_port}".bold.yellow)
	      tls_connection.puts(CONN_FAIL)
	      tls_connection.close if tls_connection
	      Thread.exit
	    end

	end

	 
end

server = ProxyServer.new(OPTIONS[:port])
server.notify(OPTIONS[:addr], OPTIONS[:dport], OPTIONS[:sni])
server.start(:handler)

