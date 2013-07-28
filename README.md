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
````

Tail accepts the line separator as second parameter. If nothing is passed it is defaulted to new line '\n'.

```javascript

var lineSeparator= "-";

new Tail("fileToTail",lineSeparator)
```

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
