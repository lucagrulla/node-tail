# Tail = require('../always')
Tail = require('../tail').Tail
assert = require('assert')

if not module.parent
  args = process.argv[2..]
  file = args[0]
  total = parseInt(args[1])
  t = new Tail(file)
  count = 0
  t.on('line', (line) ->
    console.log  line
    count += 1 
    line_num = parseInt(line.split(":")[0])
    assert.equal(line_num, count, "line received sequence is wrong")

    # console.log "count=#{count}, total=#{total}"
    if count == total
      memory = t.unwatch()
      console.log "success!"
      console.log memory
  )
