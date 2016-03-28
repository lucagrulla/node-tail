path              = require 'path'
Tail              = require('../src/tail').Tail
fs                = require 'fs'
expect            = require('chai').expect

fileToTest        = path.join __dirname, 'example.txt'

describe 'Tail', ->

  beforeEach (done) ->
    fs.writeFile fileToTest, '',done

  # before (done) ->
  #   console.log("a", fs.statSync(fileToTest))
  #   fs.writeFile fileToTest, '', done

  # after (done) ->
  #   fs.unlink fileToTest, done
  
  afterEach (done) ->
    fs.unlink(fileToTest, done) 

  it 'should read a file with windows line ending', (done) ->
    lineWindowsEnding = 'This is a windows line ending\r\n'
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest

    tailedFile.on 'line', (line) ->
      expect(line).to.be.equal lineWindowsEnding.replace(/[\r\n]/g, '')
      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, lineWindowsEnding

    fs.closeSync fd

  it 'should read a file with linux line ending', (done) ->
    lineLinuxEnding   = 'This is a linux line ending\n'
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest

    tailedFile.on 'line', (line) ->
      expect(line).to.be.equal lineLinuxEnding.replace(/[\r\n]/g, '')

      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, lineLinuxEnding

    fs.closeSync fd

  it 'should respect fromBeginning flag', (done) ->
    fd = fs.openSync fileToTest, 'w+'
    lines = ['line#0', 'line#1']
    readLinesNumber = 0
    readLines = []

    tailedFile = new Tail(fileToTest, {fromBeginning:true})
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