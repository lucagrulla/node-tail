fs = require('fs')
{exec} = require 'child_process'
prodCoffeeOpts = " --bare --output lib --compile src/tail.coffee"

task 'build', 'generate lib package', (options) ->
  fs.unlink "lib",->
    exec  "./node_modules/coffeescript/bin/coffee #{prodCoffeeOpts}",(err, stdout, stderr) ->
      throw err if err
      console.log("done.")