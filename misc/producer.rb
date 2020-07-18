s = Time.now

counter = 0
limit = 200000
File.open('blah.txt', 'w+') do |f|
  while counter < limit
    f.write("aaaaaafsdvfsdfdsfsdjkfhdsfdskfhdsfhdsjfhksd#{counter}\n")
    counter += 1
    #sleep(0.2)
    #puts counter
  end
end

e = Time.now
puts "perf:#{counter} >#{e-s}"
