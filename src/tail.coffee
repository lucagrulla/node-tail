events = require("events")
fs = require('fs')
path = require('path')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter
  readBlock: =>
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
          if @flushAtEOF && @buffer.length > 0
            @emit("line", @buffer)
            @buffer = ''
        stream.on 'data', (data) =>
          if @separator is null
            @emit("line", data)
          else
            @buffer += data
            parts = @buffer.split(@separator)
            @buffer = parts.pop()
            @emit("line", chunk) for chunk in parts

  constructor:(filename, options = {}) ->
    super filename, options
    @filename = filename
    @absPath = path.dirname(@filename);
    {@separator = /[\r]{0,1}\n/,  @fsWatchOptions = {},
    @follow = true, @logger, @useWatchFile = false, @flushAtEOF = false, @encoding = "utf-8",fromBeginning = false} = options

    if @logger
      @logger.info("Tail starting...")
      @logger.info("filename: #{@filename}")
      @logger.info("encoding: #{@encoding}")
      try
        fs.accessSync @filename, fs.constants.F_OK
      catch err
        if err.code is 'ENOENT'
          throw err

    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @isWatching = false

    @internalDispatcher.on 'next',=>
      @readBlock()

    @watch(fromBeginning)

  change: (filename) =>
    try
      stats = fs.statSync(filename)
    catch err
      @logger.error("change event for #{filename} failed: #{err}") if @logger
      @emit("error", "change event for #{filename} failed: #{err}")
      return
    @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
    if stats.size > @pos
      @queue.push({start: @pos, end: stats.size})
      @pos = stats.size
      @internalDispatcher.emit("next") if @queue.length is 1

  watch: (fromBeginning) ->
    return if @isWatching
    
    if @logger
      @logger.info("filesystem.watch present? #{fs.watch isnt undefined}")
      @logger.info("useWatchFile: #{@useWatchFile}")
      @logger.info("fromBeginning: #{fromBeginning}")

    @isWatching = true
    try
      stats =  fs.statSync(@filename)
    catch err
      @logger.error("watch for #{@filename} failed: #{err}") if @logger
      @emit("error", "watch for #{@filename} failed: #{err}")
      return
    @pos = if fromBeginning then 0 else stats.size
    @emit("watch", @pos)
    
    if @pos == 0
      @change(@filename)

    if  not @useWatchFile and fs.watch
      @logger.info("watch strategy: watch") if @logger
      @watcher = fs.watch @filename, @fsWatchOptions, (e, filename) => @watchEvent e, filename
    else
      @logger.info("watch strategy: watchFile") if @logger
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev

  rename: (filename) ->
      #MacOS sometimes throws a rename event for no reason.
      #Different platforms might behave differently.
      #see https://nodejs.org/api/fs.html#fs_fs_watch_filename_options_listener
      #filename might not be present.
      #https://nodejs.org/api/fs.html#fs_filename_argument
      #Better solution would be check inode but it will require a timeout and
      # a sync file read.
      if filename is undefined || filename isnt @filename
        @unwatch()
        if @follow
          @filename = path.join(@absPath, filename)
          @rewatchId = setTimeout (=> @watch()), 1000
        else
          @logger.error("'rename' event for #{@filename}. File not available.") if @logger
          @emit("error", "'rename' event for #{@filename}. File not available.")
      else
        # @logger.info("rename event but same filename")

  watchEvent: (e, evtFilename) ->
    if e is 'change'
      @change(@filename)
    else if e is 'rename'
      @rename(evtFilename)

  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @pos = curr.size    # Update @pos so that a consumer can determine if entire file has been handled
      @queue.push({start:prev.size, end:curr.size})
      @internalDispatcher.emit("next") if @queue.length is 1

  unwatch: ->
    if @watcher
      @watcher.close()
    else
      fs.unwatchFile @filename
    if @rewatchId
      clearTimeout(@rewatchId) 
      @rewatchId = undefined
    @isWatching = false
    @queue = []
    @logger.info("Unwatch ", @filename) if @logger

exports.Tail = Tail
