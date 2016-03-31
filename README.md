#tail

[![NPM](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)

# Installation

```bash
npm install tail
```

# Use:
```javascript
Tail = require('tail').Tail;

tail = new Tail("fileToTail");

tail.on("line", function(data) {
  console.log(data);
});

tail.on("error", function(error) {
  console.log('ERROR: ', error);
});
```

If you want to stop tail:

```javascript
tail.unwatch()
```

To start watching again:
```javascript
tail.watch()
```

# Configuration
The only mandatory parameter is the path to the file to tail. 

```javascript
var fileToTail = "/path/to/fileToTail.txt";
new Tail(fileToTail)
```

Optional parameters can be passed via a hash:

```javascript
var options= {lineSeparator: /[\r]{0,1}\n/, fromBeginning: false, watchOptions: {}, follow: true, logger: console}
new Tail(fileToTail, options)
```

# Available parameters:

* `lineSeparator`:  the line separator token (default `/[\r]{0,1}\n/` to handle linux/mac (9+)/windows)
* `watchOptions`:  the full set of options that can be passed to `fs.watch` as per node documentation (default: {})
* `fromBeginning`: forces the tail of the file from the very beginning of it instead of from the first new line that will be appended (default: `false`)
* `follow`: simulate `tail -F` option. In the case the file is moved/renamed (or logrotated), if set to `true` `tail` will try to start tailing again after a 1 second delay, if set to `false` it will just emit an error event (default: `true`)
* `logger`: a logger object(default: no logger). The passed logger has to respond to two methods:
    * `info([data][, ...])`
    * `error([data][, ...])`

# Emitted events
`Tail` emits two events:

* line
```
function(data){
  console.log(data)
}
```
* error
```
function(exception){}
```

# Want to fork?

Tail is written in [CoffeeScript](http://jashkenas.github.com/coffee-script/).

The Cakefile generates the javascript that is then published to npm.

#License
MIT. Please see License file for more details.