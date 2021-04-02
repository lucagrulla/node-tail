# Tail

The **zero** dependency Node.js module for tailing a file

[![NPM](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)](https://nodei.co/npm/tail.png?downloads=true&downloadRank=true)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/lucagrulla/node-tail/blob/master/LICENSE)
[![npm](https://img.shields.io/npm/v/tail.svg?style=plastic)](https://www.npmjs.com/package/tail)
![npm](https://img.shields.io/npm/dm/tail.svg)

Made with ❤️ by [Luca Grulla](https://www.lucagrulla.com) 

1. TOC
{:toc}

## Installation

```bash
npm install tail
```

## Use

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

## Configuration

The only mandatory parameter is the path to the file to tail.

```javascript
var fileToTail = "/path/to/fileToTail.txt";
new Tail(fileToTail)
```

If the file is **missing or invalid** ```Tail``` constructor will throw an Exception and won't initialize.

```javascript
try {
  new Tail('missingFile.txt')
} catch (ex) {
  console.log(ex)
}
```

Optional parameters can be passed via a hash:

```javascript
var options= {separator: /[\r]{0,1}\n/, fromBeginning: false, fsWatchOptions: {}, follow: true, logger: console}
new Tail(fileToTail, options)
```

### Constructor parameters

* `separator`:  the line separator token (default: `/[\r]{0,1}\n/` to handle linux/mac (9+)/windows). Pass `null` for is binary files with no line separator.
* `fsWatchOptions`: the full set of options that can be passed to `fs.watch` as per node documentation (default: {}).
* `fromBeginning`:  tail from the beginning of the file (default: `false`). If `fromBeginning` is true `nLines` will be ignored.
* `follow`: simulate `tail -F` option. In the case the file is moved/renamed/logrotated, if set to `true`  will start tailing again after a 1 second delay; if set to `false` it will  emit an error event (default: `true`).
* `logger`: a logger object(default: no logger). The passed logger should follow the folliwing signature:
  * `info([data][, ...])`
  * `error([data][, ...])`
* `nLines`: tail from the last n lines. (default: `undefined`). Ignored if `fromBeginning` is set to `true`. 
* `useWatchFile`: if set to `true` will force the use of `fs.watchFile` over delegating to the library the choice between `fs.watch` and `fs.watchFile` (default: `false`).
* `encoding`: the file encoding (default:`utf-8`).
* `flushAtEOF`: set to `true` to force flush of content when end of file is reached. Useful when there's no separator character at the end of the file (default: `false`).

## Emitted events

`Tail` emits two events:

* line

```javascript
tail.on('line', (data) => {
  console.log(data)  
})
```

* error

```javascript
tail.on('error', (err) => {
  console.log(err)  
})
```
The error emitted is either the underline exception or a descriptive string.

## How to contribute
Node Tail code repo is [here](https://github.com/lucagrulla/node-tail/)
Tail is written in ES6. Pull Requests are welcome.

## History

Tail was born as part of a data firehose. Read more about that project [here](https://www.lucagrulla.com/posts/building-a-firehose-with-nodejs/).
Tail originally was written in [CoffeeScript](https://coffeescript.org/). Since December 2020 it's pure ES6.

## License

MIT. Please see [License](https://github.com/lucagrulla/node-tail/blob/master/LICENSE) file for more details.
