fs = require 'fs'
sleep = require 'sleep'
program = require('commander')

if not module.parent
  program
  .option('--output [output file]', 'the output file')
  .option('--batch [num]', 'how many lines to write in batch', parseInt)
  .option('--total [num]', 'how many lines to write out totally',  parseInt)
  .option('--sleep [millisecond]', 'the time to sleep between batch', parseInt)
  .option('--append', 'append to file instead of truncate')
  .option('--rotate', 'rotate file')
  .option('--relink', 'relink file')
  .option('--max [max line]', 'maxinum limitation of per file for rotate or relink', parseInt)
  .parse(process.argv)

  output = program.output
  total = program.total
  batch = program.batch
  sleep_millsec = program.sleep
  max = program.max
  rotate = program.rotate
  relink = program.relink

  flag = if program.append then 'a' else 'w'
  rotate_count = 0
  if relink
    src = output+"."+ rotate_count
    fs.symlinkSync(src, output)
    fd = fs.openSync(output, flag)
  else
    fd = fs.openSync(output, flag)
  s = ''
  for i in [1..total]
    s += ("#{i}:this is produced for test tail\n")
    if (i % batch) == 0 or (max? and i % max == 0)
      buff = new Buffer(s)
      fs.write(fd, buff, 0, buff.length, null)
      s = ''
      sleep.usleep(sleep_millsec * 1000)

    if (max? and i % max == 0)
      rotate_count +=1
      src = output+"."+ rotate_count
      if relink
        fs.unlinkSync(output)
        fd = fs.openSync(src, flag)
        fs.symlinkSync(src, output)
      else
        fs.renameSync(output, src)        
        fd = fs.openSync(output, flag)

  buff = new Buffer(s)
  fs.write(fd, buff, 0, buff.length, null)
