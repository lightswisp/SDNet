#!/usr/bin/ruby

require "json"
require_relative "../../utils/tls"

LAYER_2_NODES_LIST = JSON.parse(File.read("nodes.json"))

def handler(tls_connection, logger)
	logger.info("New client #{tls_connection.peeraddr[-1]}".green.bold)
	tls_connection.puts(LAYER_2_NODES_LIST)
	tls_connection.close
end


server = TLSServer.new(443)
server.start(:handler)
