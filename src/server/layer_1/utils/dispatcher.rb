require "json"
require_relative "../../../utils/tls"

class Dispatcher < TLSServer

	def delete_node(node_to_delete, nodes, nodes_list_path)
		node = nodes.delete(node_to_delete)
		File.write(nodes_list_path, JSON.generate(nodes))
		@logger.info("#{node['ip']} is now removed!".yellow.bold)
	end
	def start_checker(nodes_list_path)
		Thread.new do
			loop do
				sleep(60 * 5) # each five minutes
				nodes = JSON.parse(File.read(nodes_list_path))
				next if nodes.size == 0

				nodes.each do |node|
					client = TLSClient.new(node["ip"], node["port"], "dispatcher.checker")
					connection = client.connect
					if !connection
						@logger.fatal("#{node['ip']} seems to be down. Removing from the list...".yellow.bold)
						delete_node(node, nodes, nodes_list_path)
						next
					end

					connection.puts("DISPATCHER_PING")
					response = nil

					Timeout::timeout(5) {
						response = connection.gets
					}

					if !response
						@logger.fatal("#{node['ip']} seems to be down. Removing from the list...".yellow.bold)
						delete_node(node, nodes, nodes_list_path)
						next
					end

					if response.chomp != "DISPATCHER_PONG"
						@logger.fatal("#{node['ip']} seems to be down. Removing from the list...".yellow.bold)
						delete_node(node, nodes, nodes_list_path)
						next
					end

					@logger.info("Received DISPATCHER_PONG from #{node['ip']}")
					
				end
			end
		end
	end
end
