#tail

[![NPM](https://nodei.co/npm/tail.png)](https://nodei.co/npm/tail/)

To install:

```bash
npm install tail
```

#Use:
```javascript
Tail = require('tail').Tail;

tail = new Tail("fileToTail");

tail.on("line", function(data) {
  console.log(data);
});

tail.on("error", function(error) {
  console.log('ERROR: ', error);
});
````
The only mandatory parameter is the path to the file to tail. You can pass optional parameters passed via a hash:

```javascript
var fileToTail = "/path/to/fileToTail.txt";
new Tail(fileToTail)
```
or

```javascript
var options= {lineSeparator= /[\r]{0,1}\n/, fromBeginning = false, watchOptions = {}, follow = true} //default value, equivalent to not passing
new Tail(fileToTail, options)
```

* `fileToTail` is the name (inclusive of the path) of the file to tail
* `options` is a hash. The following keys are accepted:
  * `lineSeparator`:  the line separator token (default `/[\r]{0,1}\n/` to handle linux/mac (9+)/windows)
  * `watchOptions`:  the full set of options that can be passed to `fs.watch` as per node documentation (default: {})
  * `fromBeginning`: forces the tail of the file from the very beginning of it instead of from the first new line that will be appended (default: `false`)
  * `follow`: simulate `tail -F` option. In the case the file is moved/renamed (or logrotated) if set to `true` `tail` will try to start tailing again after a 1 second delay, if set to `false` it will just emit an error event (default: `true`)

Tail emits two type of events:

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

If you want to stop the tail:

```javascript
tail.unwatch()
```

To start watching again:
```javascript
tail.watch()
```

#Want to fork ?

Tail is written in [CoffeeScript](http://jashkenas.github.com/coffee-script/).

The Cakefile generates the javascript that is then published to npm.

#License
MIT. Please see License file for more details.
