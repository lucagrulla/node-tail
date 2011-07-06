Tail = require('../tail').Tail
fs=require('fs')

@counter = 0
@bytes = 0
msgStart = new Date()
@bytesStart = new Date()
@overallTime = new Date()
    
out = fs.createWriteStream("/Users/lucagrulla/Forward/try/out.log",{encoding:'utf-8'})
    
t = new Tail("/Users/lucagrulla/Forward/try/test1.log")
t.on 'data',(data)=>
   if data?
     @bytes+= data.toString('utf-8').length
     t =(new Date() - @bytesStart)/1000
     if t >= 1
       label = "bytes/s"
       total = @bytes/t
       if total >= 1024
         total /= 1024
         label = "kb/s"
         if total >=1024
           total /=1024
           label = "MB/s"
           if total>=1024
             total /= 1024
             label="GB/s"
       console.log("#{total} #{label} after #{new Date() - @overallTime}")
       @bytes = 0
       @bytesStart = new Date()
     
     out.write("#{data.toString('utf-8')}\n")
  