# ChinaTownServer
使用skynet实现的桌游《唐人街》服务端

## 规则介绍
文字版：http://news.173zy.com/content/20110718/content-4936-1.html<br>
视频版：https://www.bilibili.com/video/av62419192/<br>

## Build
安装protobuf<br>
ubuntu:<br>
sudo apt-get install protobuf-c-compiler protobuf-compiler<br>
安装lua5.3<br>

1.skynet<br>
cd skynet<br>
make 'PLATFORM'  # PLATFORM can be linux, macosx, freebsd now<br>
详情:https://github.com/cloudwu/skynet

2.clib<br>
cd clib<br>
make<br>

## Proto
cd proto<br>
./gen.sh<br>

## Run
开启：<br>
./shell/all_start.sh [服务器名字，可省略]<br>
关闭：<br> 
./shell/all_kill.sh [服务器名字，可省略]<br>
前台运行：gate server<br>
./skynet/skynet ./config/gs_config 

## Config
lualib/public/serverdefines.lua<br>
GS_GATEWAY_PORTS 对外接口<br>
GAMEDB_SERVICE_COUNT 数据服务数<br>
BATTLE_SERVICE_COUNT 对战服务数<br>
MYSQL_USER 数据库用户名<br>
MYSQL_PWD 数据库密码<br>

## Resources
资源服务器。使用前安装nodejs。<br>
客户端输出的AB包文件夹放到./resources中，用于资源更新。<br>
80端口<br>

开启：<br>
cd ./resources<br>
./start.sh<br>
关闭：<br>
cd ./resources<br>
./kill.sh<br>

## Client
https://github.com/DoreRandom/ChinaTownClient