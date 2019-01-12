---
title: 使用HAproxy-Keepalived-MHA搭建高可以用Mysql服务集群
date: 2018-11-22 15:24:33
categories: 
 - Mysql
 - 高可用
tags:
  - Mysql
  - 高可用
  - mha
  - keepalived
  - haproxy
randnum: mha-keepalived-hapoxy-mysql
---


## 环境

![Mysql高可用集群](https://s1.ax1x.com/2018/11/22/FPu4nH.png)

- Mysql
  - 使用Mysql5.7.*版本，在Slave和Master集群中安装
  
- HAproxy
  - 使用HAproxy1.8版本，在CentOS环境中安装，使用单独服务器，以提高性能
  
- Keepalived
  - 使用Keepalived1.3.5版本，在Master和Backup服务器上安装，使用漂移VIP
  
-MHA
  - 使用mha-mangaer-0.55版本，Manager单独安装服务器，Node安装在Master和Back中
  
<!--more-->
  
## 操作

### 安装配置

1. 安装Mysql数据库
  - 分别在slave01-03服务器和master\backup服务器中安装`mysql57-community-server`
  - 安装步骤：导入mysql repo源，使用`yum-config-manager`禁用mysql80源,启用mysql57源，然后使用`yum install mysql-community-server`安装
  
2. 配置数据库主从复制
  - master和slave使用异步主从复制，并在slave服务器中设置`read_only=1` 和 `relay_log_opurge=0`
  - master和backup使用**半同步主从复制**，会用到插件`rpl_semi_sync_master/slave`
  - 在master数据库中授权用户通过服务器haproxy访问的权限
  - 参考文章:
    1. [Mysql数据库配置异步同步主从复制](https://kim1024.github.io/2018/11/02/Mysql%E6%95%B0%E6%8D%AE%E5%BA%93%E9%85%8D%E7%BD%AE%E5%BC%82%E6%AD%A5%E5%90%8C%E6%AD%A5%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6/)
    2. [Mysql数据库配置异步同步主从复制](https://kim1024.github.io/2018/11/02/Mysql%E6%95%B0%E6%8D%AE%E5%BA%93%E9%85%8D%E7%BD%AE%E5%BC%82%E6%AD%A5%E5%90%8C%E6%AD%A5%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6/)
    
  ![master-mysql-configure](https://s1.ax1x.com/2018/11/22/FPGb60.png)
  
3. 安装配置keepalived
  - 分别在master和backup中安装keepalived，设置漂移VIP地址为`192.168.0.110`，master和backup的级别、路由id、认证密码相同，state都设置为**BACKUP**,启用非抢夺模式
  - 首先启动master服务器中的keepalived，再启动backup
  - 参考文章：
    1. [Mysql高可用架构之keepalived and MHA](https://kim1024.github.io/2018/11/20/Mysql%E9%AB%98%E5%8F%AF%E7%94%A8%E6%9E%B6%E6%9E%84%E4%B9%8Bkeepalived%20and%20MHA/)
    
  ![keepalived configure](https://s1.ax1x.com/2018/11/22/FPl12V.png)
  
4. 安装配置MHA
  - 分别在master，backup和slave中安装MHA-Node
  - 在mha服务器中安装MHA-Manager，设置配置文件，修改故障转移脚本
  - 在启用mha之前，使用命令`masterha_check_ssh --conf=/etc/masterha/app1.cnf`检查ssh信任，使用命令`masterha_check_repl --conf=/etc/masterha/app1.cnf`检查mysql的主从同步
  - mha启用后，使用命令`masterha_check_status --conf=/etc/masterha/app1.cnf`检查mha的状态
  - 以daemon的方式启动MHA，使用命令行`nohup masterha_manager --conf=/etc/masterha/app1.cnf --remove_dead_master_conf --ignore_last_failover < /dev/null > /var/log/masterha/app1/app1.log 2>&1 &`
  
  ![mha-manager-configure](https://s1.ax1x.com/2018/11/22/FPG7pn.png)
  
5. 安装配置haproxy
  - 在haproxy服务器上安装haproxy，修改配置文件，启用状态检测
  - 通过端口分离读写，`3306`读，`3307`写
  - 在启用haproxy之前，可以使用命令`haproxy -f /etc/haproxy/haproxy.cfg`检查haproxy的配置是否正确
  - 参考文章：
    1. [HAProxy基础学习笔记](https://kim1024.github.io/2018/11/05/HAProxy%E5%9F%BA%E7%A1%80%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/)

  ![haproxy-configure](https://s1.ax1x.com/2018/11/22/FPNABV.png)
  
## 启用

1. 启用Mysql数据库，检查主从同步复制
2. 启用master中的keepalived，启用backup中的keepalived
3. 启用haproxy，检查haproxy的统计信息
5. 启用MHA-Manager，检查其状态

## 读写简单测试

1. 在本地通过client连接Mysql数据库，使用3307段口号
  - `mysql -u root -p -h haproxy -P 3307`
  
2. 查看Mysql的`server_id`
  - `show global variables like '%server_id%';`
  
3. 在本地通过client连接Mysql数据库，使用3306段口号
  - `mysql -u root -p -h haproxy -P 3307`
  
4. 查看Mysql的`server_id`
  - 多次执行`show global variables like '%server_id%';`查看每次获取的server-id
  
  ![rade-show-serverid](https://s1.ax1x.com/2018/11/22/FPNqC4.png)


