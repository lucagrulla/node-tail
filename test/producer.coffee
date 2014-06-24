fs = require 'fs'
sleep = require 'sleep'
program = require('commander')

if not module.parent
  program
  .option('--output [output file]', 'the output file')
  .option('--batch [num]', 'how many lines to write in batch', parseInt)
  .option('--total [num]', 'how many lines to write out totally',  parseInt)
  .option('--sleep [millisecond]', 'the time to sleep between batch', parseInt)
  .parse(process.argv)

  output = program.output
  total = program.total
  batch = program.batch
  sleep_millsec = program.sleep

  fd = fs.openSync(output, 'w')
  # wstream = fs.createWriteStream(output, {flags: 'w', encoding: 'utf8'}) 
  s = ''
  for i in [1..total]
    s += ("#{i}:this is produced for test tail\n")
    if (i % batch) == 0
      buff = new Buffer(s)
      fs.write(fd, buff, 0, buff.length, null)
      s = ''
      sleep.usleep(sleep_millsec * 1000)
