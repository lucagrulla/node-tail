events= require("events")
fs =require('fs')

environment = process.env['NODE_ENV'] || 'development'

class SeriesQueue

  next : () ->
    if @queue.length >= 1 && not @lock
      element = @queue.shift()
      @lock = true # acqure lock
      @task(element, () =>
        @lock = false ## release lock
        if @queue.length >= 1
          setImmediate(() => @next() )
      ) 

  constructor:(@task) ->
    @queue = [] 
    @lock = false

  push: (element) ->
    @queue.push element

    setImmediate(() =>
      @next()      
    )  

  length : () ->
    @queue.length
  
  


class Tail extends events.EventEmitter

  readBlock:(block, cb)=>
    if block.end > block.start
      stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding:"utf-8"})
      stream.on 'error',(error) =>
        console.log("Tail error:#{error}")
        @emit('error', error)
        cb()
      stream.on 'end',=>
        cb()
      stream.on 'data', (data) =>
        @buffer += data
        parts = @buffer.split(@separator)
        @buffer = parts.pop()
        @emit("line", chunk) for chunk in parts

  constructor:(@filename, @separator='\n', @fsWatchOptions = {}) ->    
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = new SeriesQueue(@readBlock)
    @isWatching = false
    stats =  fs.statSync(@filename)
    @pos = stats.size
    @internalDispatcher.on 'next',=>
      @readBlock()
    
    @watch()
    
  
  watch: ->
    return if @isWatching
    @isWatching = true
    if fs.watch then @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
    else
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev
  
  watchEvent:  (e) ->
    if e is 'change'
      fs.stat @filename, (err, stats) =>
        @emit 'error', err if err
        @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
        if stats.size > @pos
          @queue.push({start: @pos, end: stats.size})
          @pos = stats.size
    else if e is 'rename'
      @unwatch()
      setTimeout (=> @watch()), 1000
  
  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @queue.push({start:prev.size, end:curr.size})
  
  unwatch: ->
    if fs.watch && @watcher
      @watcher.close()
      @pos = 0
    else fs.unwatchFile @filename
    @isWatching = false
    @queue = new SeriesQueue()
  
        
exports.Tail = Tail
exports.SeriesQueue = SeriesQueue
