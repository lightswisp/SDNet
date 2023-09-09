require "socket"
require "openssl"
require "colorize"
require "logger"
require "timeout"
require_relative "certificate"

include SelfSignedCertificate

class TLSServer
	
	def initialize(port)
		@logger = Logger.new(STDOUT)
		@logger.info("Initializing...".bold)

		# https://www.w3.org/Daemon/User/Installation/PrivilegedPorts.html
		if (Process.uid != 0 && port < 1024)
			@logger.fatal("You must run it as a root user".red.bold)
			exit
		end

		if !SelfSignedCertificate.exists?
			@logger.warn("Certificate not found".red)
			@logger.info("Generating new self-signed certificate...".bold)
			SelfSignedCertificate.create_self_signed_cert(2048, [["CN", "localhost"]], "")
			@logger.info("Self-signed certificate is created".green.bold)
		end

		@socket = TCPServer.new(port)
		@logger.info("Listening on #{port}".bold)

		@sslContext 								 = OpenSSL::SSL::SSLContext.new
		@sslContext.cert             = OpenSSL::X509::Certificate.new(File.open(File.join(File.dirname(__FILE__), "../certificate/certificate.crt")))
		@sslContext.key              = OpenSSL::PKey::RSA.new(File.open(File.join(File.dirname(__FILE__), "../certificate/private.key")))
		@sslContext.verify_mode      = OpenSSL::SSL::VERIFY_PEER
		@sslContext.verify_depth     = 5
		@sslContext.timeout          = 2
		@sslContext.min_version      = OpenSSL::SSL::TLS1_3_VERSION
	end

	def start(handler)
		loop do
			Thread.new(@socket.accept) do |connection|
				tls = OpenSSL::SSL::SSLSocket.new(connection, @sslContext)
				tls.sync_close = true
				tls_connection = nil

				Timeout.timeout(10) do
					tls_connection = tls.accept
				end

				if tls_connection
					method(handler).call(tls_connection, @logger)
				else
					connection.close
				end
				rescue Timeout::Error
				    connection.close if connection && tls.state == 'PINIT'
				rescue StandardError => e
				    connection.close if connection
			end
		end
	end

end


class TLSClient
	def initialize(host, port, sni)
		@host = host
		@port = port
		@sni = sni
	end

	def connect
		begin
			socket = TCPSocket.new(@host, @port)
			return nil unless socket

			sslContext = OpenSSL::SSL::SSLContext.new
	    sslContext.min_version = OpenSSL::SSL::TLS1_3_VERSION
	    ssl = OpenSSL::SSL::SSLSocket.new(socket, sslContext)
	    ssl.hostname = @sni
	    ssl.sync_close = true
	    ssl.connect
	    return ssl
		rescue StandardError
			return nil
		end	
	end

end

