#tail

To install:

```bash
npm install tail
```

#Use:

##General:
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

##Separator:
Tail accepts the line separator as second parameter. If nothing is passed it is defaulted to new line '\n'.

```javascript

var lineSeparator= "-";

new Tail("fileToTail",lineSeparator)
```

##Options
Tail allows further configuration with a third, optional object parameter. This parameter allows you to configure the underlying `fs.watch` / `fs.watchFile` methods and their behaviour.

**Currently supported options:**
- **persistent: true** (fs.watch, fs.watchFile) <br> indicates whether the process should continue to run as long as files are being watched
- **ignoreRename: false** (fs.watch) <br> treats `rename` events as `change` events, rather than rewatching the file and resetting the watch position
- **interval: 5007** (fs.watchFile) <br> indicates how often the target should be polled, in milliseconds

##Events
Tail emits two type of events:

* line 
```
function(data){}
```
* error
```
function(exception){}
```

If you simply want to stop the tail:

```javascript
tail.unwatch()
```

And to start watching again:
```javascript
tail.watch()
```

#Want to fork ?

Tail is written in [CoffeeScript](http://jashkenas.github.com/coffee-script/).

The Cakefile generates the javascript that is then published to npm.

#License
MIT. Please see License file for more details.
