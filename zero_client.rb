require 'rubygems'
require 'ffi-rzmq'

context = ZMQ::Context.new(1)

subscriber = context.socket(ZMQ::SUB)
subscriber.connect("tcp://127.0.0.1:5560")

subscriber.setsockopt(ZMQ::SUBSCRIBE, "")

count = 0
start = Time.now

while true do   
  body = subscriber.recv_string
  puts body
end