events= require("events")
fs =require('fs')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter

  readBlock:()=>
    if @queue.length >= 1
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
          (@pos += data.length) unless @pos is null
          parts = @buffer.split(@separator)
          @buffer = parts.pop()
          @emit("line", chunk) for chunk in parts

  constructor:(@filename, @separator='\n', @fsWatchOptions = {}) ->    
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @isWatching = false
             
    @internalDispatcher.on 'next',=>
      @readBlock()
    
    @watch()
    
  
  watch: ->
    return if @isWatching
    @pos = 0
    @isWatching = true
    @watcher = fs.watch @filename, @fsWatchOptions, (e) =>
      if e is 'change'
        fs.stat @filename, (e, stats) =>
          if stats.size > @pos
            @queue.push({start: @pos, end: stats.size})
            @internalDispatcher.emit("next") if @queue.length is 1
      else if e is 'rename'
        @unwatch()
        setTimeout(1000, => @watch())
  
  unwatch: ->
    @watcher.close()
    @iswatching = false
    @queue = []
    
  watchFile:->
    return if @isWatching
    @isWatching = true
    fs.watchFile @filename, @fsWatchOptions, (curr, prev) =>
      if curr.size > prev.size
        @queue.push({start:prev.size, end:curr.size})
        @internalDispatcher.emit("next") if @queue.length is 1
  
  unwatchFile:->
    fs.unwatchFile @filename
    @isWatching = false
    @queue = []
  
        
exports.Tail = Tail
