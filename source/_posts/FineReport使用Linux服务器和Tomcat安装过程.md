---
title: FineReport使用Linux服务器和Tomcat安装过程
date: 2019-07-27 09:06:21
categories: 
 - finereport
tags:
  - finereport
  - 数据分析
randnum: finereport_install
---
# FineReport使用Linux服务器和Tomcat安装过程

![fingerpost_dashboard](https://s2.ax1x.com/2019/07/27/euzfzT.png)

## 准备基础环境

### 下载finereport

- 下载FineReport Linux版本
下载地址:<https://fine-build.oss-cn-shanghai.aliyuncs.com/finereport/10.0/tomcat/tomcat-linux.tar.gz>
在服务器中执行`wget https://fine-build.oss-cn-shanghai.aliyuncs.com/finereport/10.0/tomcat/tomcat-linux.tar.gz`
- 解压文件tomcat-linux.tar.gz
`tar -xzvf tomcat-linux.tar.gz`
- 移动文件
`sudo mv tomcat-linux /opt && cd /opt && sudo mv tomcat-linux finereport`
``

**如果使用finereport自带的tomcat和jre，可以直接启动tomcat，设定防火墙端口后直接使用**，以下操作步骤是使用自行搭建的tomcat和使用mysql数据库。

<!--more-->

### 下载Java

- 下载Java jdk版本
下载地址:<https://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html>
- 安装Java jdk
`sudo rpm -ivh jdk-8u221-linux-x64.rpm`
- 配置java环境变量
```
su
cd /etc
cp profile profile.old
vi profile 
# add
	java_home=/usr/java/jdk1.8.0_221-amd64
	CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
	PATH=$JAVA_HOME/bin:$PATH
	export JAVA_HOME CLASS_PATH PATH
. profile
# show java version
java -version
```

### 下载tomcat

- 下载tomcat
`wget http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-9/v9.0.22/bin/apache-tomcat-9.0.22.tar.gz`
- 解压文件apache-tomcat-9.0.22.tar.gz
`tar -xzvf apache-tomcat-9.0.22.tar.gz`
- 将解压的文件夹移动到/opt下
`sudo mv apache-tomcat /opt && cd /opt && mv apache-tomcat tomcat`
- 启动tomcat
```
cd /opt/tomcat/bin
./startup.sh
```

### 添加防火墙规则

- 添加8080端口
```
su
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-source=192.168.0.0/24 --permanent
firewal-cmd --reload
```

## 部署finereport

### 部署web文件

- 将webroot文件复制到tomcat目录下的webapps中
```
sudo cp -r /opt/finereport/webapps/webroot /opt/tomcat/webapps/
```
- 额外引入JDK的tools.jar
```
cp /usr/java/jdk1.8.0_221-amd64/lib/tools.jar /opt/tomcat/lib
sudo cp /usr/java/jdk1.8.0_221-amd64/lib/tools.jar /opt/tomcat/webapps/webroot/WEB-INF/lib

```
**注意**：如果不执行复制tools.jar的操作，重启完tomcat后打开实例会出现错误`HTTP Status 500 – Internal Server Error`
- 重启tomcat
`cd /opt/tomcat/bin && ./shutdown.sh && ./startup.sh`
- 在本地启动浏览器打开`http://server_name:8080/webroot/decision`

![finereport_home](https://s2.ax1x.com/2019/07/27/euztII.png)

### 数据库部署

- 在数据库服务器中创建数据库
`create database finedb_t character set utf8;`
- 授权数据库
`grant all on finedb_t.* to 'dba'@'finereport' identified by 'passwd';`
- 在web配置中，配置外接数据库

![configure_mysql](https://s2.ax1x.com/2019/07/27/euzcon.png)

- 等待数据库配置完成,使用帐号密码登录

## 参考

1. [部署应用至Linux上的tomcat](https://help.finereport.com/doc-view-822.html)
