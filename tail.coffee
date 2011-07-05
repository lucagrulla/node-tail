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
      stream.on 'end',()=>
        @queue.shift()
        console.log("#{@queue.length} queue length on end of stream at #{new Date()}") if environment is 'development'
        @internalDispatcher.emit("next") if @queue.length >= 1
        @emit('end')
      stream.on 'close',()=>
         @emit('close')
      stream.on 'fd',(fd)=>
        @emit('fd', fd)
      stream.on 'data', (data) =>
        @buffer += data
        parts = @buffer.split(@separator)
        @buffer = parts.pop()
        @emit("data", chunk) for chunk in parts

  constructor:(@filename, @separator='\n') ->    
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
             
    @internalDispatcher.on 'next',()=>
      @readBlock()
    
    fs.watchFile @filename, (curr, prev) =>
      @queue.push({start:prev.size, end:curr.size})  
      @internalDispatcher.emit("next") if @queue.length is 1
        
exports.Tail = Tail
