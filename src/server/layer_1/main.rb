#!/usr/bin/ruby

require_relative "../../utils/tls"

def handler(tls_connection, logger)
	logger.info("Hello there!")
	tls_connection.close
end

server = TLSServer.new(443)
server.start(:handler)
