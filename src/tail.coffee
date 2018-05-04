events = require("events")
fs = require('fs')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter
  readBlock:()=>
    if @queue.length >= 1
      block = @queue[0]
      if block.end > block.start
        stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding: @encoding})
        stream.on 'error',(error) =>
          @logger.error("Tail error: #{error}") if @logger
          @emit('error', error)
        stream.on 'end',=>
          x = @queue.shift()
          @internalDispatcher.emit("next") if @queue.length > 0
        stream.on 'data', (data) =>
          @buffer += data

          parts = @buffer.split(@separator)
          @buffer = parts.pop()
          @emit("line", chunk) for chunk in parts

  constructor:(filename, options = {}) ->
    super filename, options
    @filename = filename 
    {@separator = /[\r]{0,1}\n/,  @fsWatchOptions = {}, @fromBeginning = false, @follow = true, @logger, @useWatchFile = false, @encoding = "utf-8"} = options

    if @logger 
      @logger.info("Tail starting...")
      @logger.info("filename: #{@filename}")
      @logger.info("encoding: #{@encoding}")

    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @isWatching = false
    
    @internalDispatcher.on 'next',=>
      @readBlock()
 
    pos = 0 if @fromBeginning
    @watch(pos)

  watch: (pos) ->
    return if @isWatching
    @isWatching = true
    try
      stats =  fs.statSync(@filename)
    catch err
      @logger.error("watch for #{@filename} failed: #{err}") if @logger
      @emit("error", "watch for #{@filename} failed: #{err}")
      return
    @pos = if pos? then pos else stats.size  

    if @logger
      @logger.info("filesystem.watch present? #{fs.watch isnt undefined}")
      @logger.info("useWatchFile: #{@useWatchFile}")

    if  not @useWatchFile and fs.watch
      @logger.info("watch strategy: watch") if @logger
      @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
    else
      @logger.info("watch strategy: watchFile") if @logger
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev

  watchEvent: (e) ->
    if e is 'change'
      try
        stats = fs.statSync(@filename)
      catch err
        @logger.error("'change' event for #{@filename}. #{@err}") if @logger
        @emit("error", "'change' event for #{@filename}. #{@err}")
        return
      @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
      if stats.size > @pos
        @queue.push({start: @pos, end: stats.size})
        @pos = stats.size
        @internalDispatcher.emit("next") if @queue.length is 1
    else if e is 'rename'
      # @logger.info("rename event for ", @filename) if @logger    
      @unwatch()
      if @follow
        setTimeout (=> @watch()), 1000
      else
        @logger.error("'rename' event for #{@filename}. File not available.") if @logger
        @emit("error", "'rename' event for #{@filename}. File not available.")
      

  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @queue.push({start:prev.size, end:curr.size})
      @internalDispatcher.emit("next") if @queue.length is 1

  unwatch: ->
    if @watcher
      @watcher.close()
    else 
      fs.unwatchFile @filename
    @isWatching = false
    @queue = []
    @logger.info("Unwatch ", @filename) if @logger

exports.Tail = Tail
