const PORT = 80; 
var http = require('http'); //引入http模块
var fs = require('fs'); //引入fs模块
var url = require('url');//引入url模块
var path = require('path');//引入path模块

// req : 从浏览器带来的请求信息
// res : 从服务器返回给浏览器的信息
var server = http.createServer(function(req,res){
    var pathname = url.parse(req.url).pathname;;
     //客户端输入的url，例如如果输入localhost:8888/index.html，那么这里的url == /index.html 

    var realPath = path.join(".",pathname);
    //完整的url路径
    console.log(realPath);  

    fs.readFile(realPath,function(err,data){
        /*
        realPath为文件路径
        第二个参数为回调函数
            回调函数的一参为读取错误返回的信息，返回空就没有错误
            二参为读取成功返回的文本内容
        */
        if(err){
            //未找到文件
            res.writeHead(404,{
                'content-type':'text/plain;charset="utf-8"'
            });
            res.write('不存在该文件');
            res.end();
        }else{
            //成功读取文件
            res.writeHead(200,{
                'content-type':'application/octet-stream'
            });
            res.write(data);
            res.end();
        }
    })
});
server.listen(PORT); //监听端口
console.log('服务成功开启');