#!/usr/bin/ruby

require_relative "../../utils/tls"

LAYER_2_NODES_LIST = File.read("nodes.json")
PORT = 443

def handler(tls_connection, logger)
	logger.info("New client #{tls_connection.peeraddr[-1]}".green.bold)
	tls_connection.print(LAYER_2_NODES_LIST)
	tls_connection.close
end


server = TLSServer.new(PORT)
server.start(:handler)
