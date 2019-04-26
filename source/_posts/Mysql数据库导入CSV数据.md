---
title: Mysql数据库导入CSV数据
date: 2019-04-21 13:30:36
categories:
 - mysql
tags:
  - mysql
  - csv
randnum: mysql_import_csv
---

## 创建数据库

1. 新建1个数据库
`create database test_db;`
2. 授权用户权限;
`grant all on test_db.* to 'user'@'host' idedntified by 'Paaswd#2019';`

<!--more-->
## 创建基本表

1. 新建一个数据表
```
use test_db;
create table movie (
		id char(10) primary key,
		movie_name char(20),
		movie_star float(1),
		movie_people int,
		movie_time char(20),
		movie_country char(10)
		);
```
2. 查看新创建的数据表
`show columns from movie;`

## 导入数据

```
load data local infile '/home/use/move.csv'
		into table movie
		fields terminated by ','
		lines terminated by '\n'
		ignore 1 rows;
```
如果出现*secure-file-priv*相关的提示需要手动设置*secure-file-priv*;
```
sudo vi /etc/my.cnf
# 添加
secure-file-priv="" 
#NULL表示限制mysql不允许导入导出，/tmp表示只允许导入导出到/tmp目录，为空时表示不限制mysql导入导出到任意目录
# 重启mysql服务
sudo systemctl restart mysqld
```
![load data](https://s2.ax1x.com/2019/04/21/EFP9AS.png)

## 查看导入的数据

`select * from movie where id=1;`

## 参考

1. <https://chartio.com/resources/tutorials/excel-to-mysql/>
