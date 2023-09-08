#!/usr/bin/ruby

# require "socket"
# require "colorize"
# require "openssl"
# require "logger"
# require
require_relative "../utils/tls"

LOGGER = Logger.new(STDOUT)
PORT = 8080
MAX_BUFFER = 1024 * 640


LOGGER.info("Connecting...".bold)
client = TLSClient.new("127.0.0.1", 443, "google.com")
connection = client.connect

if !connection
	LOGGER.fatal("Failed to connect!".red.bold)
	exit
end

LOGGER.info("Connected!".green.bold)

puts connection.gets

