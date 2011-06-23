puts "PID:#{Process.pid}"

@log = true

Signal.trap("USR1") {
  puts "signal received"
  @log = false
  log_it()
}
@i=0
def log_it
  @log = true
  File.open('test1','w+') do |f|
    file_handler = f
    while @log 
      f.write " #{@i} #{Time.now.to_s}, }\n"
      f.flush
      @i+=1
      sleep 0.5
    end
  end
end

log_it()


