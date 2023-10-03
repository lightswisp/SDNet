#!/usr/bin/ruby

require "json"
require 'optparse'
require_relative "utils/dispatcher"
require_relative "../../webserver/webserver"
include WebServer

ARGV << '-h' if ARGV.empty?

OPTIONS = {}
OptionParser.new do |opts|
  opts.banner = "SDNET Layer 1\n\n".bold + 'Usage: ./server.rb [options]'

  opts.on('-h', '--help', 'Prints help') do
    puts opts
    puts
    exit
  end
  
  opts.on('-pPORT', '--port=PORT',
          'Port for listening, example: ./server.rb --port 443') do |port|
    OPTIONS[:port] = port.to_i
  end

end.parse!

MAX_BUFFER = 1024 * 640
SDNET_PATH = "#{Dir.home}/.sdnet"
Dir.mkdir(SDNET_PATH) if !Dir.exist?(SDNET_PATH)
LAYER_2_NODES_LIST = "#{SDNET_PATH}/nodes.json"

def handler(tls_connection, logger)
	
	ip = tls_connection.peeraddr.last
	request = tls_connection.readpartial(MAX_BUFFER)
	request = request.split("\r\n")
	tls_connection.close unless request
	request_head = request.first
	tls_connection.close unless request_head
	request_head = request_head.chomp

	logger.info("DEBUG: #{request_head}")

	case request_head
		when /SERVER_NEW/
			request_head = request_head.split("/")
			logger.info("New server #{ip}".green.bold)
			port = request_head[1].to_s
			sni = request_head[2]
			node = {
				"ip" => ip,
				"port" => port,
				"sni" => sni
			}
			nodes = JSON.parse(File.read(LAYER_2_NODES_LIST))
			if nodes.include?(node)
				logger.warn("#{ip}:#{port} already exists".yellow.bold)
			else
				nodes << node
				File.write(LAYER_2_NODES_LIST, JSON.generate(nodes))
				logger.info("Saved #{ip}:#{port}".green.bold)
			end
		
			tls_connection.close
		when /CLIENT_NEW/
			logger.info("New client #{ip}".green.bold)
			nodes = File.read(LAYER_2_NODES_LIST)
			tls_connection.print(nodes)
			tls_connection.close
		when /GET/
			logger.info("New website visitor #{ip}, lets do some magic :)".green.bold)
			response = WebServer.response(request.first, 1, logger)
			tls_connection.puts(response)
			tls_connection.close
		else
			logger.fatal("Unknown command, closing the connection.".red.bold)
			tls_connection.close
	end

end

File.write(LAYER_2_NODES_LIST, "[]") unless File.exist?(LAYER_2_NODES_LIST)
server = Dispatcher.new(OPTIONS[:port])
server.start_checker(LAYER_2_NODES_LIST)
server.start(:handler)
