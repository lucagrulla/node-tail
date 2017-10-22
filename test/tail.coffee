path              = require 'path'
Tail              = require('../src/tail').Tail
fs                = require 'fs'
expect            = require('chai').expect

fileToTest        = path.join __dirname, 'example.txt'

describe 'Tail', ->

  beforeEach (done) ->
    fs.writeFile fileToTest, '',done

  afterEach (done) ->
    fs.unlink(fileToTest, done) 

  lineEndings = [{le:'\r\n', desc: "Windows"}, {le:'\n', desc: "Linux"}]

  lineEndings.forEach ({le, desc})->
    it 'should read a file with ' + desc + ' line ending', (done)->
      text = "This is a #{desc} line ending#{le}"
      nbOfLineToWrite = 100
      nbOfReadLines   = 0

      fd = fs.openSync fileToTest, 'w+'

      tailedFile = new Tail fileToTest, {fsWatchOptions: {interval:100}, logger: console}

      tailedFile.on 'line', (line) ->
        expect(line).to.be.equal text.replace(/[\r\n]/g, '')
        ++nbOfReadLines

        if (nbOfReadLines is nbOfLineToWrite)
          tailedFile.unwatch()

          done()

      for index in [0..nbOfLineToWrite]
        fs.writeSync fd, text

      fs.closeSync fd

  it 'should respect fromBeginning flag', (done) ->
    fd = fs.openSync fileToTest, 'w+'
    lines = ['line#0', 'line#1']
    readLinesNumber = 0
    readLines = []

    tailedFile = new Tail(fileToTest, {fromBeginning:true, fsWatchOptions: {interval:100}})
    tailedFile.on 'line', (line) ->
      readLines.push(line)
      if (readLines.length is lines.length) 
        match = readLines.reduce((acc, val, idx)-> 
          acc and (val is lines[idx])
        , true)
        
        if match 
          tailedFile.unwatch()
          done()

    for l in lines
      fs.writeSync fd, l+'\n'

    fs.closeSync fd

  it 'should send error event on deletion of file while watching', (done)->
    text = "This is a line\n"

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, {fsWatchOptions: {interval:100}, logger: console}

    # ensure error gets called when the file is deleted
    tailedFile.on 'error', (line) ->
      # recreate file so that `afterEach` can cleanup
      fd = fs.openSync fileToTest, 'w+'
      done()

    tailedFile.on 'line', (line) ->
      # delete the file
      fs.unlinkSync fileToTest

    fs.writeSync fd, text

    fs.closeSync fd
