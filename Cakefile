fs = require('fs')
{exec} = require 'child_process'
prodCoffeeOpts = " --bare --output release --compile tail.coffee"

task 'build', 'generate release package', (options) ->
  fs.unlink "release",->
    exec  "./node_modules/coffee-script/bin/coffee #{prodCoffeeOpts}",(err, stdout, stderr) ->
      throw err if err
      console.log stdout
      fs.link "README.md", "release/README.md",
      fs.link "package.json", "release/package.json",-> 
        console.log("done.")