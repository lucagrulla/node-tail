path              = require 'path'
Tail              = require('../src/tail').Tail
fs                = require 'fs'
expect            = require('chai').expect

fileToTest        = path.join __dirname, 'example.txt'
lineWindowsEnding = 'This is a windows line ending\r\n'
lineLinuxEnding   = 'This is a linux line ending\n'

describe 'Tail', ->
  afterEach (done) ->
    fs.stat fileToTest, (err) ->
      if err?
        done()
      else
        fs.unlink fileToTest, done

  it 'should read a file with windows line ending', (done) ->
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, null, {}

    tailedFile.on 'line', (line) ->
      expect(line).to.contain lineWindowsEnding.replace(/[\r\n]/g, '')

      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, index + lineWindowsEnding

    fs.closeSync fd

  it 'should read a file with linux line ending', (done) ->
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, null, {}

    tailedFile.on 'line', (line) ->
      expect(line).to.contain lineLinuxEnding.replace(/[\n]/g, '')

      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, index + lineLinuxEnding

    fs.closeSync fd

  it 'should send an error when we try to read a non-existing file', (done) ->
    tailedFile = new Tail 'unknown file', null, {}
    callbackOnce = false

    tailedFile.on 'error', (err) ->
      tailedFile.unwatch()
      done()

  it 'should send an error when we are reading a file that is being removed', (done) ->
    @timeout 5000
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'
    tailedFile = new Tail fileToTest, null, {}

    tailedFile.on 'error', (err) ->
      if nbOfReadLines >= nbOfLineToWrite
        tailedFile.unwatch()

        done()

    tailedFile.on 'line', (line) ->
      expect(line).to.contain lineLinuxEnding.replace(/[\n]/g, '')

      ++nbOfReadLines

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, index + lineLinuxEnding

    fs.closeSync fd

    setTimeout ->
      fs.unlinkSync fileToTest
    , 500

  it 'should wait before reading a non-existing file', (done) ->
    @timeout 5000
    nbOfLineToWrite = 100
    nbOfReadLines   = 0
    writeFileOnce   = false

    tailedFile = new Tail fileToTest, null, {}

    tailedFile.on 'error', (err) ->
      if !writeFileOnce
        writeFileOnce = true
        fd = fs.openSync fileToTest, 'w+'

        for index in [0..nbOfLineToWrite]
          fs.writeSync fd, index + lineLinuxEnding

        fs.closeSync fd

    tailedFile.on 'line', (line) ->
      expect(line).to.contain lineLinuxEnding.replace(/[\n]/g, '')

      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()
