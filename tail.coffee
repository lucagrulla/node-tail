events= require("events")
fs =require('fs')

class Tail extends events.EventEmitter
  constructor:(@filename, separator) ->    
    @separator = separator || '\n'
    fs.watchFile @filename, (curr, prev) =>
      if curr.size > prev.size
        stream = fs.createReadStream(@filename, {start:prev.size, end:curr.size, encoding:"utf-8"})
        buffer = ''
    
        stream.on 'error',(error) =>
          @emit('error', error)

        stream.on 'end',=>
          @emit('end')
    
        stream.on 'close',=>
          @emit('close')
        
        stream.on 'fd',(fd)=>
          @emit('fd', fd)
          
        stream.on 'data', (data) =>
          buffer += data
          parts = buffer.split(@separator)
          buffer = parts.pop()
          @emit("data", chunk) for chunk in parts
  
          
exports.Tail= (filename, separator)->
  new Tail(filename, separator)