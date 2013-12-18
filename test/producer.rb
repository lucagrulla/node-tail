File.open("log.txt", "w+") do |f|
	(1..1000).each do |i|
		f.write("#{i} 1234567890\n")
	end
end 

