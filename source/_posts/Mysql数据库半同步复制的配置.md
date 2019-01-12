---
title: Mysql数据库半同步复制的配置
date: 2018-11-03 11:03:23
categories: 
 - Mysql
 - 学习笔记
tags:
  - Mysql
  - 半同步
rundnum: mysql-rpl_semi
---

# Mysql半同步主从复制

## 环境
- 宿主：CentOS7
- Mysql：使用5.7.23，基于Docker搭建的实验环境
- 其他：在上一篇中已经成功搭建了异步同步主从复制的环境，在该基础上搭建半同步主从复制
- 使用半同步复制，在主机宕机的情况下，可以保证至少有一台从服务器中的数据与主服务器中的数据保持一致。
<!--more-->
## 配置主服务器
1. 进入Mysql数据库，安装插件`rpl_remi_sync_master`
2. 查看插件是否安装`show plugins;`
  - `mysql> install plugin rpl_semi_sync_master soname 'semisynv_mster.so';`
3. 启用插件
   - `set global rpl_semi_sync_master_enabled = 1;` # 注意`=` 与字符和数字之间有空格，否则会报错
4. 安装完成后，查看插件的状态。
    ![Semi_Master状态](https://s1.ax1x.com/2018/11/03/i4KGWj.png)


## 配置从服务器
1. 进入数据库，安装并启用插件`rpl_semi_sync_slave`,相关的操作可以参考*配置主服务器的1&2* 
    ![Slave插件位置](https://s1.ax1x.com/2018/11/03/i4u3x1.png)
  - `mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';` # 需要注意，在Master中使用的是**master** 模块，在从服务器中使用的是**slave**模块
2. 查看semi插件的状态
    ![Semi_Slave状态](https://s1.ax1x.com/2018/11/03/i4KrY4.png)

## 查看是否进行半同步
- 在主服务器中查看半同步复制客户端的数量`show global status like '%semi%';`
  ![半同步客户端数量](https://s1.ax1x.com/2018/11/03/i4lPe0.png)
