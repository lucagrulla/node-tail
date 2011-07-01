Tail = require('../tail').Tail
zmq = require('zeromq')

pub = zmq.createSocket('pub')
pub.bind 'tcp://*:5560', (err) -> console.log err

sub = zmq.createSocket('sub')
sub.connect("tcp://localhost:5560")
sub.subscribe("")

@counter = 0
start = new Date()
sub.on 'message', (channel,data) ->
  @counter++
  t =(new Date() - start)/1000
  if t >= 10
    console.log("#{@counter/t} msg/sec")
    @counter = 0
    start = new Date()
    
    
t = new Tail("/Users/lucagrulla/Forward/try/test1.log")
t.on 'next',->
  console.log "client next"

t.on 'data',(data)->
   if data?
     pub.send "channel",data

  