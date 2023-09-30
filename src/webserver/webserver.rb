#!/usr/bin/ruby

module WebServer
		OK = "HTTP/1.1 200 OK"
		NOT_FOUND = "HTTP/1.1 404 Not Found"

		def response(request, layer, logger)
			logger.info("#{request}".bold)
			path = request.split(" ")[1]
			case layer
				when 1
					begin
					
						if path == "/"
							webpage = File.read(File.join(__dir__, "../templates/layer_1" + path + "index.html"))
						else
							webpage = File.read(File.join(__dir__, "../templates/layer_1" + path))
						end
						response = "#{OK}\r\nDate: #{Time.now}\r\nContent-Type: text/html\r\n\r\n#{webpage}"
						
					rescue Errno::ENOENT, Errno::EISDIR
						webpage = File.read(File.join(__dir__, "../templates/404.html"))
						response = "#{NOT_FOUND}\r\nDate: #{Time.now}\r\nContent-Type: text/html\r\n\r\n#{webpage}"
					end	
				when 2

				begin
									
					if path == "/"
						webpage = File.read(File.join(__dir__, "../templates/layer_2" + path + "index.html"))
					else
						webpage = File.read(File.join(__dir__, "../templates/layer_2" + path))
					end
					response = "#{OK}\r\nDate: #{Time.now}\r\nContent-Type: text/html\r\n\r\n#{webpage}"
					
				rescue Errno::ENOENT
					webpage = File.read(File.join(__dir__, "../templates/404.html"))
					response = "#{NOT_FOUND}\r\nDate: #{Time.now}\r\nContent-Type: text/html\r\n\r\n#{webpage}"
				end	

				else
					logger.fatal("Layer #{layer} is not yet implemented".bold.red)
			end

			return response
		end
end
