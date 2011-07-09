Tail = require('../tail').Tail
fs=require('fs')

@counter = 0
@bytes = 0
msgStart = new Date()
@bytesStart = new Date()
@overallTime = new Date()
    
out = fs.createWriteStream("/Users/lucagrulla/Forward/try/out.log",{encoding:'utf-8'})
stats = fs.createWriteStream("/Users/lucagrulla/Forward/try/stats.csv",{encoding:'utf-8'})
    
t = new Tail("/Users/lucagrulla/Forward/try/test1.log")
t.on 'data',(data)=>
   if data?
     @bytes+= data.toString('utf-8').length
     t =(new Date() - @bytesStart)/1000
     if t >= 60
       label = "bytes/s"
       total = @bytes/t
       globalTotal = @bytes/t
       if total >= 1024
         total /= 1024
         label = "kb/s"
         if total >=1024
           total /=1024
           label = "MB/s"
           if total>=1024
             total /= 1024
             label="GB/s"
       
       timeDiff = new Date() - @overallTime
       console.log("#{total} #{label} after #{timeDiff}")
       stats.write("#{Math.floor(timeDiff/60000)},#{(globalTotal/1048576).toString().substr(0,6)}\n") #MB per minutes
       @bytes = 0
       @bytesStart = new Date()
     
     out.write("#{data.toString('utf-8')}\n")
  