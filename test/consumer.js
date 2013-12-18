Tail = require('tail').Tail;

tail = new Tail("./test/log.txt");

tail.on("line", function(data) {
  console.log(data);
});