File.open('test1','w+') do |f|
  while true 
    f.write "#{Time.now.to_s}, stuff, blah\n"
    # sleep 0.001
  end
end

  