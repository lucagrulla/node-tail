path              = require 'path'
Tail              = require('../src/tail').Tail
fs                = require 'fs'
expect            = require('chai').expect

fileToTest        = path.join __dirname, 'example.txt'
lineWindowsEnding = 'This is a windows line ending\r\n'
lineLinuxEnding   = 'This is a linux line ending\n'

describe 'Tail', ->
  before (done) ->
    fs.writeFile fileToTest, '', done

  after (done) ->
    fs.unlink fileToTest, done

  it 'should read a file with windows line ending', (done) ->
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, null, {}

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
    nbOfLineToWrite = 100
    nbOfReadLines   = 0

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, null, {}

    tailedFile.on 'line', (line) ->
      expect(line).to.be.equal lineLinuxEnding.replace(/[\r\n]/g, '')

      ++nbOfReadLines

      if (nbOfReadLines is nbOfLineToWrite)
        tailedFile.unwatch()

        done()

    for index in [0..nbOfLineToWrite]
      fs.writeSync fd, lineLinuxEnding

    fs.closeSync fd