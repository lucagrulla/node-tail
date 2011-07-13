events= require("events")
fs =require('fs')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter

  readBlock:()=>
    block=@queue[0]
    if block.end > block.start
      stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding:"utf-8"})
      stream.on 'error',(error) =>
        console.log("Tail error:#{error}")
        @emit('error', error)
      stream.on 'end',=>
        @queue.shift()
        @internalDispatcher.emit("next") if @queue.length >= 1
      stream.on 'data', (data) =>
        @buffer += data
        parts = @buffer.split(@separator)
        @buffer = parts.pop()
        @emit("line", chunk) for chunk in parts

  constructor:(@filename, @separator='\n') ->    
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
             
    @internalDispatcher.on 'next',=>
      @readBlock()
    
    fs.watchFile @filename, (curr, prev) =>
      if curr.size > prev.size
        @queue.push({start:prev.size, end:curr.size})  
        @internalDispatcher.emit("next") if @queue.length is 1
        
exports.Tail = Tail
