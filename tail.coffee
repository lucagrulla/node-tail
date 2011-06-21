fs = require 'fs'
zmq = require('zeromq')
spawn = require('child_process').spawn

socket = zmq.createSocket('pub')

socket.bind 'tcp://*:5560', (err) -> console.log err

tail_file = (channel,filename) ->
  stream = spawn 'tail', ['-F', filename]
  buffer = ''
  stream.stdout.on "data", (data) ->
    buffer += data
    parts = buffer.split('\n')
    buffer = parts.pop()
    socket.send chunk for chunk in parts