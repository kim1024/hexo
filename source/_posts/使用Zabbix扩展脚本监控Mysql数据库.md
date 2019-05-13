---
title: 使用Zabbix扩展脚本监控Mysql数据库
date: 2019-05-07 14:10:05
categories:
 - Zabbix
tags:
  - Zabbix_Agent
  - Mysql
randnum: zabbix_agent_monitoring_mysql
---

## 基本信息  

使用扩展的脚本监控Mysql数据库，脚本中包含10项较为常用的Mysql指标监控，并且该脚本是独立的，在Zabbix Server安装即用。  
在使用脚本之前，需要在受监控的Mysql服务器中安装jq，支持的版本号是1.5+。

## 操作  

### Mysql服务器中进行的操作

1. 安装jq  
```
sudo yum whatprovides jq
sudo yum install jq-1.5-1.el7.x86_64 -y
```
2. 配置Zabbix-Agent配置文件  
在文件*/etc/zabbix/zabbix_agentd.conf* 中添加以下内容：
```
UserParameter=Mysql.Server-Status, mysql --defaults-file=/etc/zabbix/.my.cnf --defaults-group-suffix=_monitoring -N -e  "show global status" |   jq  -c '.  | split("\n")[:-1]  | map (split("\t") | {(.[0]) : .[1]}  ) | add  ' -R -s
```
<!--more-->
需要注意的是：**mysql的认证登录信息默认存储位置设置为/etc/zabbix/.my.cnf，zabbix用户需要对mysql的passwd文件具有读的权限。**  
*.my.cnf*文件的所有者属于`mysql:mysql`,可以将zabbix用户附加到mysql用户组中，将该文件的权限设置为`640` 。  
3. 将用户和密码信息加入文件*.my.cnf*中,并设置用户/组和权限  
```
cd /etc/zabbix
sudo touch .my.cnf
sudo vi .my.cnf
# add
[mysql]
socket=/var/lib/mysql/mysql.sock
user=db
password=MysqlPasswd@2019
[client]
socket=/var/lib/mysql/mysql.sock
user=db
password=MysqlPasswd@2019
# set owner
sudo chown mysql:mysql .my.cnf
sudo chmod 640 .my.cnf
sudo usermod -a -G mysql zabbix
```
4. 重启Agent服务
`sudo systemctl restart zabbix-agent`

### Zabbix监控服务器中进行的操作

1. 下载扩展脚本并导入  
`wget https://raw.githubusercontent.com/nitzien/zabbix-misc/master/templates/mysql/mysql_template.xml`
打开Zabbix Web导入脚本，操作路径：*Configuration->Templates->Import*  
2. 将导入的脚本链接到需要监控的Mysql服务器  
3. 查看最新的监控数据  
![latest_data](https://s2.ax1x.com/2019/05/07/ErvEaF.png)

## 遇到的坑

在操作完成后，在Web中查看最新数据时，总是提示*ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (13)*,但是在Agent端Mysql的服务是正常启动的，而且在本地都可以登录，重试了几次都没有解决，最后尝试将SELinux设置为pemissive,重启后问题得到解决。  
![error_13](https://s2.ax1x.com/2019/05/07/Erj0N4.png)
如果启用SELinux需要安装Zabbix-Agent的SELinux模块，具体操作：  
```
# show SELinux
grep zabbix_agent_t /var/log/audit/audit.loggrep zabbix_agent_t /var/log/audit/audit.log | audit2allow -M zabbix_agent_custom
# set
semodule -i zabbix_agent_custom.pp
```

## 参考

1. [Mysql and Mysql Slave Monitoring Zabbix Template](https://tachniki.blogspot.com/2019/03/mysql-and-mysql-slave-monitoring-zabbix.html)
2. [zabbix-misc](https://github.com/nitzien/zabbix-misc/tree/master/templates/mysql)
