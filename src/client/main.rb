#!/usr/bin/ruby

require "json"
require_relative "../utils/tls"
require_relative "../utils/proxy"

LOGGER = Logger.new(STDOUT)
PORT = 8080
MAX_BUFFER = 1024 * 640
LAYER_1_SERVER = "127.0.0.1"
LAYER_2_CONFIG_PATH = "#{Dir.home}/.nodes_list.json"


if !File.exist?(LAYER_2_CONFIG_PATH)
	LOGGER.info("Connecting...".bold)
	client = TLSClient.new(LAYER_1_SERVER, 443, "google.com")
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
	File.write(LAYER_2_CONFIG_PATH, JSON.generate(LAYER_2_NODES_LIST))
	LOGGER.info("Nodes were saved at #{LAYER_2_CONFIG_PATH}".bold)
else
	LOGGER.info("Nodes were found at #{LAYER_2_CONFIG_PATH}".green.bold)
	LAYER_2_NODES_LIST = JSON.parse( File.read(LAYER_2_CONFIG_PATH) )
end

LOGGER.info("Starting the local proxy at #{PORT}".bold)
proxy = LocalProxy.new(PORT, LAYER_2_NODES_LIST, MAX_BUFFER, LOGGER)
proxy.rotate
proxy.start


