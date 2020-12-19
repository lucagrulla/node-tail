Tail = require('tail').Tail;

tail = new Tail("test.txt");

const limit = parseInt(process.argv[2]) || 200000
console.log("consumer starting...");
let cnt = 0
tail.on("line", (data) => {
    if (cnt == 0) {
      console.time(`tail-${limit}`);
    }
  cnt++  
  if (cnt == limit) {
    console.timeEnd(`tail-${limit}`);
    tail.unwatch();
    console.log("consumer done.");
    process.exit(1)
  }
});
