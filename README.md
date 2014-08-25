#tail

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

Tail constructor accepts few parameters:

```javascript

var fileToTail = "/path/to/fileToTail.txt";
var lineSeparator= "\n";
var fromBeginning = false;
var watchOptions = {}; \\ as per node fs.watch documentations

new Tail(fileToTail, lineSeparator, fromBeginning, watchoptions)
```
The only mandatory one is the first, i.e. the the file you want to tail; the default values for the other 3 parameters are the one documented  in the previous code snippet.


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
