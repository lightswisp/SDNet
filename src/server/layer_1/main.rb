#!/usr/bin/ruby

require_relative "../../utils/tls"

LAYER_2_NODES_LIST = File.read("nodes.json")

def handler(tls_connection, logger)
	logger.info("New client #{tls_connection.peeraddr[-1]}".green.bold)
	tls_connection.print(LAYER_2_NODES_LIST)
	tls_connection.close
end


server = TLSServer.new(443)
server.start(:handler)
