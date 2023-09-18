#!/usr/bin/ruby

require "json"
require "optparse"
require_relative "../utils/tls"
require_relative "../utils/proxy"

ARGV << '-h' if ARGV.empty?
OPTIONS = {}

OptionParser.new do |opts|
  opts.banner = "SDNET Client\n\n".bold + 'Usage: ./client.rb [options]'

  opts.on('-h', '--help', 'Prints help') do
    puts opts
    puts
    exit
  end

  opts.on('-aADDR', '--address=ADDR',
          'Dispatcher address, example: ./client.rb --address 177.68.54.30') do |addr|
    OPTIONS[:addr] = addr
  end

   opts.on('-dADDR', '--dport=ADDR',
          'Dispatcher port, example: ./client.rb --dport 443') do |dport|
    OPTIONS[:dport] = dport.to_i
  end

  opts.on('-pPORT', '--port=PORT',
          'Local port for listening, example: ./client.rb --port 8080') do |port|
    OPTIONS[:port] = port.to_i
  end

  opts.on('-sSNI', '--sni=SNI', 'TLS SNI extension spoof, or just enter the Layer 1 server domain name, example: ./client.rb --sni google.com') do |sni|
    OPTIONS[:sni] = sni
  end
end.parse!

LOGGER = Logger.new(STDOUT)
MAX_BUFFER = 1024 * 640

LOGGER.info("Connecting...".bold)
client = TLSClient.new(OPTIONS[:addr], OPTIONS[:dport], OPTIONS[:sni])
connection = client.connect

if !connection
	LOGGER.fatal("Failed to connect!".red.bold)
	exit
end

LOGGER.info("Connected!".green.bold)
# First step, getting the actual nodes list
LOGGER.info("Getting nodes list...".bold)

connection.puts("CLIENT_NEW") # notify the server that we are a client

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


LOGGER.info("Starting the local proxy at #{OPTIONS[:port]}".bold)
proxy = LocalProxy.new(OPTIONS[:port], LAYER_2_NODES_LIST, MAX_BUFFER, LOGGER)
proxy.rotate
proxy.start


