#!/usr/bin/ruby

# TODO
#
# Add random layer 1 node selection
#
# TODO

require "json"
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
# First step, getting the actual nodes list
LOGGER.info("Getting nodes list...".bold)
begin
LAYER_2_NODES_LIST = JSON.parse(connection.readpartial(MAX_BUFFER))
rescue
	# if something went wrong :(
	LOGGER.fatal("Couldn't get any nodes. Shutting down...".red.bold)
	exit
end

LOGGER.info("We got #{LAYER_2_NODES_LIST.size} nodes".green.bold)
LOGGER.info("Closing the connection with Layer 1 node".bold)
sleep_time = (5..10).to_a.sample	# random time between 5 and 10 seconds
LOGGER.info("Waiting #{sleep_time} seconds before closing the connection".bold)
sleep sleep_time
connection.close if connection
LOGGER.info("Connection closed".bold)



