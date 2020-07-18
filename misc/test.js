Tail = require('tail').Tail;


tail = new Tail("blah.txt",{logger: console}  );

let cnt = 0
tail.on("line", (data) => {
  console.log(data);
  let s = "aaaaaafsdvfsdfdsfsdjkfhdsfdskfhdsfhdsjfhksd" + cnt;
//  if (data != s) {
//    console.error("ERROR",data, s )
//    process.exit(1)
//   }
  cnt++  
});

// setInterval(() => {
//   if (cnt > 10) {
//     //tail.unwatch();
// //    console.log("stopped:");
//     process.exit()
//   }
// }, 100);

