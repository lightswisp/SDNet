require_relative "../../../utils/tls"

class ProxyServer < TLSServer
		def notify(layer_1_server, layer_1_server_port, sni)
			client = TLSClient.new(layer_1_server, layer_1_server_port, sni)
			ssl = client.connect
			if !ssl
				@logger.fatal("Couldn't connect to dispatcher at #{layer_1_server}".red.bold)
				exit
			end
			ssl.puts("SERVER_NEW/#{@port}/#{sni}")
			@logger.info("Successfully notified layer 1 dispatcher".green.bold)
			@logger.info("Sleeping for 5 seconds before disconnecting".bold)
			sleep 5
			ssl.close
	end
end
