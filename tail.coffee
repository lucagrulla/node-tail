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

  clean: () ->
    @queue = [] 

  length : () ->
    @queue.length
  

class Tail extends events.EventEmitter

  _readBlock:(block, cb) =>
    fs.fstat(block.fd, (err, stat) =>
      if err
        return cb()

      start = @bookmarks[block.fd]
      end  = stat.size 
      if start > end
        start = 0

      size = end - start
      if size == 0
        return cb()

      buff = new Buffer(size) 
      fs.read(block.fd, buff, 0, size, start, (err, bytesRead, buff) =>
        if err 
          @emit('error', err)
          return cb()

        @bookmarks[block.fd] += bytesRead        
        data = buff.toString('utf-8')
        @buffer += data
        parts = @buffer.split(@separator)
        @buffer = parts.pop()
        @emit("line", chunk) for chunk in parts

        if (block.type == 'close') 
          fs.close(block.fd);
          delete @bookmarks[block.fd];

        return cb()
      )
    )

  _checkOpen : (start) ->
    try 
      fd = fs.openSync(@filename, 'r')
      stat = fs.fstatSync(fd)
      @current = {fd: fd, inode: stat.ino}
      if start? and start >=0
        @bookmarks[fd] = start
      else
        @bookmarks[fd] = stat.size
    catch e
      if e.code == 'ENOENT'  # file not exists      
        @current = {fd: null, inode: 0}
      else
        throw new Error("failed to read file #{@filename}: #{e.message}") 
    

  constructor:(@filename, @separator='\n', @options = {}) ->    
    @buffer = ''
    @queue = new SeriesQueue(@_readBlock)
    @isWatching = false
    @bookmarks = {}
    @_checkOpen(@options.start)
    @interval = @options.interval || 1000
    @watch()
    
  
  watch: ->
    return if @isWatching
    @isWatching = true
    fs.watchFile @filename, {interval: @interval}, (curr, prev) => @_watchFileEvent curr, prev

    
  _watchFileEvent: (curr, prev) ->
    if curr.ino != @current.inode
      if @current.fd
        @queue.push({type: 'close', fd: @current.fd})
      @_checkOpen(0)

    if @current.fd
      @queue.push({type:'read', fd: @current.fd})

  
  unwatch: ->
    @queue.clean()
    fs.unwatchFile(@filename)
    @isWatching = false
    if @current.fd
      memory = {inode: @current.inode, pos: @bookmarks[@current.fd]} 
    else
      memory = {inode: 0, pos: 0}  

    for fd, pos of @bookmarks
      fs.closeSync(parseInt(fd))
    @bookmarks = {}
    @current = {fd:null, inode:0}
    return memory
  
        
exports.Tail = Tail
