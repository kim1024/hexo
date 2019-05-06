---
title: Nagios使用check_mysql_health插件监控Mysql主机
date: 2019-05-03 14:31:23
categories:
 - Nagios
tags:
  - nagios
  - nagios_plugins
  - check_mysql_health
randnum: nagios_plugins_check_mysql_health
---

## 基本信息
 - Nagios：Nagios core 4.4.3
 - Nagios Plugins：check_mysql_health 2.2.2
 - Mysql-server: 192.168.0.91
 - db user：db
 - 操作流程：下载插件->安装插件->配置command->添加主机->添加服务

## 安装插件

1. 下载
`wget https://labs.consol.de/assets/downloads/nagios/check_mysql_health-2.2.2.tar.gz`
2. 配置、编译、安装
```
tar -xzvf check_mysql_health-2.2.2.tar.gz
cd check_mysql_health-2.2.2
# configure
./configure --prefix=/usr/local/nagios/libexec --with-nagios-user=nagios --with-nagios-group=nagios --with-perl=/usr/bin/perl
# make
sudo make
# install
sudo make install
```
<!--more-->
## 配置

### 配置插件

1. 添加check命令
```
cd /usr/local/nagios/etc/objects/
sudo vi commands.cfg
## add
define command {
    command_name check_mysql_health
    command_line $USER1$/check_mysql_health -H $ARG1$ --username $ARG2$ --password $ARG3$ --port $ARG4$ --mode $ARG5$	
}
```
2. 创建主机配置文件
```
cd /usr/local/nagios/etc/objects
sudo touch mysql92\1.cfg && sudo chown nagios:nagios mysql91.cfg
# add
# define a host use template linux-server
define host {
    use			linux-server
    host_name		mysql91
    alias		mysql server 91
    address		192.168.0.91
}
# define a new hostgroup
define hostgroup {
    hostgroup_name	mysql-server
    alias		mysql-server
    members		mysql91
}
# define services with template generic-service
# mysql_conn_time
define service {
    use			generic-service
    host_name		mysql91
    service_description	mysql_conn_time
    check_command	check_mysql_health!192.168.0.91!db!MysqlPasswd2019!3306!connection-time!
}
# mysql_threads_connected
define service {
    use			generic-service
    host_name		mysql91
    service_description	mysql_threads_connected
    check_command	check_mysql_health!192.168.0.91!db!MysqlPasswd2019!3306!threads-connected!
}
# mysql_slow_queries
define service {
    use			generic-service
    host_name		mysql91
    service_description mysql_slow_queries
    check_command	check_mysql_health!192.168.0.91!db!MysqlPasswd2019!3306!slow-queries!
}
# mysql_encde
define service {
    use			generic-service
    host_name		mysql91
    service_description mysql_sql
    check_command	check_mysql_health!192.168.0.91!db!MysqlPasswd2019!3306!encode!
}
# mysql_open_files
define service {
    use			generic-service
    host_name		mysql91
    service_description mysql_open_files
    check_command	check_mysql_health!192.168.0.91!db!MysqlPasswd2019!3306!open-files!
}
```
3. 更多Mysql检查
`check_mysql_health`插件通过修改`--mode`的参数来设定检查项，其他检查可以参考[check_mysql_health mode参数](https://labs.consol.de/nagios/check_mysql_health/)
4. 检查Nagios配置文件
`sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg`
![check_nagios_cfg](https://s2.ax1x.com/2019/05/03/ENvf56.png)
5. 重启Nagios服务，打开web界面查看新增的主机和服务
`sudo systemctl restart nagios`
![service](https://s2.ax1x.com/2019/05/03/ENvBCT.png)
6. 测试报警
将被监控主机的mysql服务关闭，查看Nagios Web平台中的报警。
![alarm](https://s2.ax1x.com/2019/05/03/ENzkOH.png)

## 参考

1. [check_mysql_health website](https://labs.consol.de/nagios/check_mysql_health/)
