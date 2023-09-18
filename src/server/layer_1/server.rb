#!/usr/bin/ruby

require "json"
require 'optparse'
require_relative "../../utils/tls"

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

SDNET_PATH = "#{Dir.home}/.sdnet"
Dir.mkdir(SDNET_PATH) if !Dir.exist?(SDNET_PATH)
LAYER_2_NODES_LIST = "#{Dir.home}/.sdnet/nodes.json"

def handler(tls_connection, logger)
	
	ip = tls_connection.peeraddr.last
	cmd = tls_connection.gets
	p cmd
	cmd = cmd.chomp
	tls_connection.close unless cmd
	
	case cmd
		when /SERVER_NEW/
			cmd = cmd.split("/")
			logger.info("New server #{ip}".green.bold)
			port = cmd[1]
			sni = cmd[2]
			node = {
				"ip" => ip,
				"port" => port,
				"sni" => sni
			}
			nodes = JSON.parse(File.read("#{SDNET_PATH}/#{LAYER_2_NODES_LIST}"))
			if nodes.include?(node)
				logger.warn("#{ip}:#{port} already exists".yellow.bold)
			else
				nodes << node
				File.write("#{SDNET_PATH}/#{LAYER_2_NODES_LIST}", JSON.generate(nodes))
				logger.info("Saved #{ip}:#{port}".green.bold)
			end
		
			tls_connection.close
		when /CLIENT_NEW/
			logger.info("New client #{ip}".green.bold)
			nodes = File.read("#{SDNET_PATH}/#{LAYER_2_NODES_LIST}")
			tls_connection.print(nodes)
			tls_connection.close
		when /GET/
			logger.info("New website visitor #{ip}, lets do some magic :)".green.bold)
			webpage = File.read(File.join(__dir__, "../../templates/layer_1/index.html"))
			response = "HTTP/1.1 200 OK\r\nDate: #{Time.now}\r\nContent-Type: text/html\r\n\r\n#{webpage}"
			tls_connection.puts(
				response
			)
			tls_connection.close
		else
			logger.fatal("Unknown command, closing the connection.".red.bold)
			tls_connection.close
	end

end

File.write("#{SDNET_PATH}/#{LAYER_2_NODES_LIST}", "[]") unless File.exist?("#{SDNET_PATH}/#{LAYER_2_NODES_LIST}")

server = TLSServer.new(OPTIONS[:port])
server.start(:handler)
