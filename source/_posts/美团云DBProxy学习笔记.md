---
title: 美团云DBProxy学习笔记
date: 2019-06-30 09:21:47
categories: 
 - dbproxy
tags:
  - dbproxy 
  - mysql
randnum: dbproxy
---
## 基本信息

DBProxy是美团点评开发和维护的基于Mysql协议的数据中间件，在Atlas基础上做了修改。
提供的主要功能有：<sup>1</sup>
  - 读写分离
  - 从库负载均衡
  - IP过滤
  - 分表
  - DBA平滑上下线DB
  - 自动摘除宕机DB
  - 监控信息完备
  - SQL过滤
  - 从库流量配置

部署架构
![dbproxy](https://s2.ax1x.com/2019/06/30/ZlTmB4.png)

<!--more-->
## 安装

1. 安装依赖
`yum install -y Percona-Server-devel-55.x86_64 Percona-Server-client-55.x86_64 Percona-Server-shared-55 jemalloc jemalloc-devel libevent libevent-devel openssl openssl-devel lua lua-devel bison flex libtool.x86_64 libffi-devel`
2. 安装glib2.4.2.0
```
wget https://src.fedoraproject.org/repo/pkgs/mingw-glib2/glib-2.42.0.tar.xz/71af99768063ac24033ac738e2832740/glib-2.42.0.tar.xz
tar -xJvf glib-2.42.0.tar.xz
cd glib-2.42.0
autoreconf -ivf
./configure --refix=/usr/ --libdir=/usr/lib64/
make -j20 && make install
```
3. 安装DBProxy
```
git clone https://github.com/Meituan-Dianping/DBProxy.git
cd DBProxy
sh autogen.sh
sh bootstrap.sh
make -j20 && make install
# DBProxy默认的安装路径/usr/local/mysql-proxy,如果需要修改，修改文件bootstrap.sh中的--pefix路径
```
4. 配置文件，添加开机启动
```
#!/bin/bash
# chkconfig 23456 90 10
# description: autostart dbproxy service onboot
cd /usr/local/mysql-proxy/bin && ./mysql-proxyd dbproxy start
```
5. 登录管理后台
```
mysql -u dba -p -P 3309 -h 192.168.0.130
# 查看支持的命令
select * from help;
# 查看主从数据库
select * from backends;
# 添加主库，注意：在dbproxy中只能有1个主库
add master 192.168.0.101:3306
# 添加从数据库,可以设置权重
add slave 192.168.0.104:3306@2
# 从库添加|移除标签
add|remove slave tag $tag_name $backend_ndx
# 动态修改从库权重
alter slave weight $backend_ndx $weight
# 上线|下线从库id
set online|offline $backend_ndx;
# 删除从库
remove backend $backend_ndx
# 查看dbproxy中的用户
select * from pwds;
# 对dbproxy操作后需要进行保存配置
save config;
```
![dbproxy_admin](https://s2.ax1x.com/2019/06/30/ZlTeuF.png)

## 参考

1. [DBProxy Github项目地址](https://github.com/Meituan-Dianping/DBProxy)
2. [DBProxy配置手册](https://github.com/Meituan-Dianping/DBProxy/blob/master/doc/USER_GUIDE.md#2)
