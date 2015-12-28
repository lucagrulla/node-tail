events = require("events")
fs = require('fs')

environment = process.env.NODE_ENV || 'development'

class Tail extends events.EventEmitter

  readBlock: =>
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

  constructor: (@filename, @separator=/[\r]{0,1}\n/, @fsWatchOptions = {}, @frombeginning=false) ->
    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @isWatching = false
    @stopWatching = false
    @pos = 0
    @internalDispatcher.on 'next', =>
      @readBlock()

    @tryWatch()

  tryWatch: ->
    self = this

    try
      # Must be sync, otherwise we are not sure that we are missing some lines
      stats = fs.statSync @filename
      @pos = if @frombeginning then 0 else stats.size
      @watch()

      # If pos is not equal to stats.size, we have to trigger a watch event
      if stats.size isnt @pos
        @tryWatchEvent()
    catch err
      process.nextTick ->
        self.emit 'error', err

        # Since file did not exist, we want to read it from the beginning
        self.frombeginning = true

        # If 'unwatch' is called
        if !self.stopWatching
          # File does not exists, retry later
          setTimeout self.tryWatch.bind(self), 500

  watch: ->
    return if @isWatching
    @isWatching = true
    if fs.watch then @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
    else
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev

  tryWatchEvent: ->
    self = this

    try
      # Must be sync, otherwise we are not sure that we are missing some lines
      stats = fs.statSync(@filename)
      @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
      if stats.size > @pos
        @queue.push({start: @pos, end: stats.size})
        @pos = stats.size
        @internalDispatcher.emit("next") if @queue.length is 1
    catch err
      process.nextTick ->
        self.emit 'error', err

        # If 'unwatch' is called
        if !self.stopWatching
          # File does not exists, retry later
          setTimeout self.tryWatchEvent.bind(self), 500

  watchEvent: (e) ->
    self = this

    if e is 'change'
      @tryWatchEvent()
    else if e is 'rename'
      @clearWatch()
      setTimeout (=> @tryWatch()), 500

  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @queue.push({start:prev.size, end:curr.size})
      @internalDispatcher.emit("next") if @queue.length is 1

  clearWatch: ->
    if fs.watch && @watcher
      @watcher.close()
    else fs.unwatchFile @filename
    @isWatching = false

  unwatch: ->
    @clearWatch()
    @stopWatching = true

exports.Tail = Tail
