---
title: Mysql-master2slave
date: 2018-11-02 15:28:21
categories: 
 - Mysql
 - 学习笔记
tags:
  - Mysql
  - 配置
  - 学习笔记 
---

# Mysql 数据库配置主从复制

## 环境
- 为了实验Mysql数据库的主从复制，我们使用Docker搭建相关的环境；
- 使用Docker-Compose分别创建3个容器，容器名称分别是`mysql-master` `mysql-slave0` `mysql-slave1` `mysql-slave2` ;
- 将Mysql数据库的附加配置文件和数据库文件映射到宿主机中；

<!--more-->
## 异步复制
### 主服务器文件配置
- 找到主服务器的配置文件`${PWD}/mysql/master/my.cnf`
- 对配置文件进行如下修改：

```
[mysqld]
pid-file=/var/run/mysqld/mysqld.pid
socket=/var/run/mysqld/mysqld.sock
datadir=/var/lib/mysql
log-error=/var/log/mysql/mysql-error.log
symbolic-links=0 # 不使用到表的链接符号
lower_case_table_names=1 #表名在硬盘中以小写保存，名称比较对大小写不敏感
server-id=80 #服务器id，在局域网内，该id是唯一的，一般设置为ip的最后一位
log-bin=master-bin #开启二进制文件，名称可以根据需要自定义，默认保存在数据目录下，会自动添加一个数字扩展名用于日志老化，不支持自定义扩展名
log-bin-index=master-bin.index #二进制日志文件对应的日志索引文件，该文件包含所有的二进制日志，文件名与二进制日志文件名相同，扩展名为.index
max_binlog_size=1M # 若当前的日志大小达到1M，则自动创建新的二进制日志。但是，对于大的事物，二进制日志会超过该设定值，将所有事务仅写入一个日志文件
expire_logs_days = 10 #日志保留时间
```
### 主服务器数据库配置

1.  进入容器`mysql-master`:`docker exec -it mysql-master bash`
2.  进入mysql数据库内容进行相关的操作：

```
mysql -uroot -p
mysql>
	grant replication slave ,replication client on *.* to 'slave_db'@'192.168.10.%' identified by 'passwd'; 
	flush privileges;
	flush table with read lock; #锁库，不让数据再进行写操作，这个命令在结束终端会话时自动解锁
	show master status;
```
[![show master status](https://s1.ax1x.com/2018/11/02/ihgYJe.png)](https://imgchr.com/i/ihgYJe)
3.  
### 从服务器文件配置
- 修改从服务器的配置文件的配置文件：

```
[mysqld]
pid-file=/var/run/mysqld/mysqld.pid
socket=/var/run/mysqld/mysqld.sock
datadir=/var/lib/mysql
log-error=/var/log/mysql/mysql-error.log
symbolic-links=0
lower_case_table_names=1
server-id=100 # 其他从服务器依次修改
log-bin=slave0-bin.log # 修改为其他从服务器名称
sync_binlog=3 #控制binlog写入频率，每执行多少次事务写入一次，这个参数性能消耗很大，但是可以减少Mysql崩溃造成的损失
```
### 从服务器数据库配置
- 进入数据库进行相关操作,其他从服务器参考以下内容修改：

```
mysql>
	change master to master_host=`192.168.10.2`,master_port=3306,master_user=`slave_db`,master_password=`20170110`,master_log_file=`master-bin.000001`,master_log_pos=634;
	start slave;
	show slave status;
```
[![show slave status](https://s1.ax1x.com/2018/11/02/ihgtRH.png)](https://imgchr.com/i/ihgtRH)

## 参考
1. <https://juejin.im/post/5a2e4bd66fb9a044fa19cfb7>
2. <https://juejin.im/post/5afed922f265da0ba76ffeab>
