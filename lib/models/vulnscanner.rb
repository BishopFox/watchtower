class VulnScanner

	attr_accessor :payloads, :points_of_interest, :points_of_interest_sorted, :scan_dir
	
	# initializer
	def initialize data
		@payloads	= data[:payloads]
		@scan_dir 	= data[:scan_dir]
		@points_of_interest        = []
		@points_of_interest_sorted = {}
	end
	
	# performs a scan of the specified codebase
	def scan
		@payloads.each do |file_type, payload_groups|
			# cast the file_type symbol into a string
			ftype = file_type.to_s	
			# iterate over the payload groups
			payload_groups.each do |payload_group, payloads|
			
				# iterate over each payload
				payloads.each do |payload|
					# assemble a list of directories to ignore
					ignore = ''
					unless $configs[:exclude_dirs].empty?
						$configs[:exclude_dirs].each do |dir|
							ignore += " --ignore-dir='#{dir}'"
						end
					end

					# do an ack-grep scan
					result = `cd #{@scan_dir}; ack-grep '#{payload.shellescape}' --sort --#{ftype} #{ignore}`
					
					# display the matches
					unless result.strip.empty?
						# iterate over the ack results
						result.each_line do |line| 
							# parse the result string into components
							first_colon_pos  = line.index(':')
							second_colon_pos = line.index(':', first_colon_pos + 1)
							
							# parse out the important information
							file_name        = line.slice(0..(first_colon_pos - 1)) 
							line_num         = line.slice((first_colon_pos + 1)..(second_colon_pos - 1)) 
							snippet          = line.slice((second_colon_pos +1), line.length).strip

							# buffer a new point of interest
							data = {
								:file_type   => ftype,
								:file        => file_name,
								:line_number => line_num,
								:match       => payload,
								:snippet     => snippet,
								:group		 => payload_group,
							}
							
							#puts data.to_yaml
							
							@points_of_interest.push(PoI.new(data))
						end
					end
				end	
			end
		end		
	end
	
	# structure the points of interest into a hash
	def sort
		@points_of_interest.each_with_index do |point, index|
			@points_of_interest_sorted[point.file_type.to_sym] ||= {}
			@points_of_interest_sorted[point.file_type.to_sym][point.group.to_sym] ||= {}
			@points_of_interest_sorted[point.file_type.to_sym][point.group.to_sym][point.match.to_sym] ||= []
			@points_of_interest_sorted[point.file_type.to_sym][point.group.to_sym][point.match.to_sym].push point
		end
	end
end