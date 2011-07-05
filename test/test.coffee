Tail = require('../tail').Tail
zmq = require('zeromq')

pub = zmq.createSocket('pub')
pub.bind 'tcp://*:5560', (err) -> console.log err

sub = zmq.createSocket('sub')
sub.connect("tcp://localhost:5560")
sub.subscribe("")

@counter = 0
@bytes = 0
msgStart = new Date()
@bytesStart = new Date()

sub.on 'message', (channel,data) =>
  @counter++
  t =(new Date() - msgStart)/1000
  if t >= 10
    console.log("#{@counter/t}")
    
    @counter = 0
    msgStart = new Date()
    
    
t = new Tail("/Users/lucagrulla/Forward/try/test1.log")
t.on 'next',->
  console.log "client next"

t.on 'data',(data)=>
   if data?
     @bytes+= data.toString('utf-8').length
     t =(new Date() - @bytesStart)/1000
     if t >= 1
       console.log("#{@bytes/t} bytes/s => #{@bytes/t/1024} MB/s")
       @bytes = 0
       @bytesStart = new Date()
     
     pub.send "channel",data

  