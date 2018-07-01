# Tail

The **zero** dependency Node.js module for tailing a file

[![NPM](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/lucagrulla/node-tail/blob/master/LICENSE)
[![npm](https://img.shields.io/npm/v/tail.svg?style=plastic)](https://www.npmjs.com/package/tail)

Author: [Luca Grulla](https://www.lucagrulla.com) - [www.lucagrulla.com](https://www.lucagrulla.com)

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
var options= {separator: /[\r]{0,1}\n/, fromBeginning: false, fsWatchOptions: {}, follow: true, logger: console}
new Tail(fileToTail, options)
```

# Available parameters:

* `separator`:  the line separator token (default `/[\r]{0,1}\n/` to handle linux/mac (9+)/windows)
* `fsWatchOptions`:  the full set of options that can be passed to `fs.watch` as per node documentation (default: {})
* `fromBeginning`: forces the tail of the file from the very beginning of it instead of from the first new line that will be appended (default: `false`)
* `follow`: simulate `tail -F` option. In the case the file is moved/renamed (or logrotated), if set to `true` `tail` will try to start tailing again after a 1 second delay, if set to `false` it will just emit an error event (default: `true`)
* `logger`: a logger object(default: no logger). The passed logger has to respond to two methods:
    * `info([data][, ...])`
    * `error([data][, ...])`
* `useWatchFile`: if set to `true` will force the use of `fs.watchFile` rather than delegating to the library the choice between `fs.watch` and `fs.watchFile` (default: `false`)
* `encoding`: the encoding of the file to tail (default:`utf-8`)

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

# Why tail was born?

Tail was born as part of a data firehose. Read about it [here](https://www.lucagrulla.com/posts/building-a-firehose-with-nodejs/).

# License
MIT. Please see License file for more details.
