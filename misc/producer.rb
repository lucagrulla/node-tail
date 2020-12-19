#!/usr/bin/env ruby

# s = Time.now

counter = 0
limit = ARGV[0].to_i || 200000
puts "producer starting..."
File.open('test.txt', 'w+') do |f|
  while counter < limit
    f.write("aaaaaafsdvfsdfdsfsdjkfhdsfdskfhdsfhdsjfhksd#{counter}\n")
    counter += 1
    #sleep(0.2)
    #puts counter
  end
end
puts "producer done."
# e = Time.now
# puts "perf:#{counter} >#{e-s}"
