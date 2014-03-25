events= require("events")
fs =require('fs')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter

  readBlock:()=>
    if @queue.length >= 1
      block = @queue.shift()
      if block.end > block.start
        stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding:"utf-8"})
        stream.on 'error',(error) =>
          console.log("Tail error:#{error}")
          @emit('error', error)
        stream.on 'end',=>
          @internalDispatcher.emit("next") if @queue.length >= 1
        stream.on 'data', (data) =>
          @buffer += data
          parts = @buffer.split(@separator)
          @buffer = parts.pop()
          @emit("line", chunk) for chunk in parts

  constructor:(@filename, @separator='\n', @fsWatchOptions = {}, opts = {}) ->
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @internalDispatcher.on 'next',=>
      @readBlock()
    @isWatching = false
    @existsMaxChecks = opts.existsMaxChecks ||    1 # max checks when file does not exist (default check once) - if existsMaxChecks < 0 check forever
    @existsInterval  = opts.existsInterval  ||  500 # millsec between checks
    @existsCounter   = 0                            # times already checked

    @checkExists()


  watch: ->
    return if @isWatching
    @isWatching = true
    @existsCounter = 0
    if fs.watch then @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
    else
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev
  
  watchEvent:  (e) ->
    if e is 'change'
      fs.stat @filename, (err, stats) =>
        if err
          @emit 'error', err
          return
        @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
        if stats.size > @pos
          @queue.push({start: @pos, end: stats.size})
          @pos = stats.size
          @internalDispatcher.emit("next") if @queue.length is 1
    else if e is 'rename'
      @unwatch()
      @checkExists()
  
  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @queue.push({start:prev.size, end:curr.size})
      @internalDispatcher.emit("next") if @queue.length is 1
  
  unwatch: ->
    if fs.watch && @watcher
      @watcher.close()
      @pos = 0
    else fs.unwatchFile @filename
    @isWatching = false
    @queue = []

  checkExists: ->
    # increase check numbers
    if @existsMaxChecks >= 0
      @existsCounter++
      if @existsCounter > @existsMaxChecks
        @emit 'error', new TailError('file does not exist, max checks reached')
        return
    fs.exists @filename, (exists) =>
      if exists
        if @existsCounter is 0
          fs.stat @filename, (err, stats) =>
              if err
                setTimeout ( => @checkExists() ), @existsInterval
              else
                @pos = stats.size
                @watch()
        else
          @pos = 0
          @watch()
      else
        setTimeout ( => @checkExists() ), @existsInterval

class TailError extends Error

  constructor: (@message)->
    self = super
    self.name = 'TailError'
    return self


exports.Tail = Tail
