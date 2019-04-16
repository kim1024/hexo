---
title: Centos中安装keepalive和基础使用
date: 2018-11-20 09:13:45
categories: 
 - CentOS
tags:
  - CentOS
  - keepalived
  - 集群
randnum: centos-keepalived
---

# Centos中安装keepalive和基础使用

## 环境
- CentOS7
- keepalived 

## 安装
- 在master和备用master上安装keepalive软件,执行命令`yum install keepalived -y`
- 修改keepalive的配置
  - 编辑配置文件 vi /etc/keepalived/keepalived.conf`,主被服务器的配置相同，不配置`vrrp_script`,使用mha实现vip的自动漂移
  
<!--more-->
  ```
  global_defs {
  # 定义接收邮件的邮箱
  notification_email {
  	test@localhost  
  	}
  # 定义发送邮件的邮箱
  notification_email_from test1@localhost
  # 定义smtp服务器
  smtp_server smtp.localhost
  smtp_connect_timeout 10
  }
  # 定义mysql_a实例
  vrrp_instance mysql_a {
  # 定义服务器状态，在Master服务器中也可以将状态设置为MASTER，不设置的目的是期望在Master宕机后再恢复时，不主动将Master状态抢过来，避免Mysql服务的波动
  state BACKUP
  # 定义使用的网络接口
  interface eth0
  	# 定义虚拟路由id，一组lvs的虚拟路由标志须相同
  	virtual_router_id 51
  	# 服务启动优先级，值越大，优先级越大，但是不能大于MASTER值
  	priority 150
  	# 服务器之间的存活检查时间
  	advert_int 1
  	# keepalived工作模式为非抢占
  	nopreempt
  authentication {
  	# 认证类型
  	auth_type PASS
  	# 认证密码，一组lvs的认证密码须相同
  	auth_pass mysql_pass
  	}
  virtual_ipaddress {
  	# 配置虚拟ip地址
  	192.168.0.110
  	}
  }
  
  ```
- 启动keepalived `systemctl start keepalived`
- 查看Master服务器中的vip `ip addr`
  ![Master Server ip](https://s1.ax1x.com/2018/11/20/Fp6zZR.png)
- 注意
  - vrrp_instance实例有2种工作模式，master-backup,backup-backup。区别：mastterbackup模式下，一旦master宕机，vip会漂移到backup服务器上，当master修复后，keepalived启动后，master会从backup把vip抢占回来，即便设置了非抢占模式;backup-backup模式下，当master宕机后，vip会漂移到backup服务器上，当master修复后，并启动keepalived，master并不会抢占vip，即便master的优先级高于bakcup，也不会发生抢占vip。为了减少vip的漂移次数，通常是把修复好的主库当作新的备用库。

## 测试
1. 将Master Server中的keepalived服务停掉`systemctl stop keepalived`
2. 查看ip地址`ip addr` ,vip已经消失
3. 查看Backup Server中的ip地址，vip已经漂移
  ![Failover ip](https://s1.ax1x.com/2018/11/20/FpcSd1.png)


## 参考
1. <http://www.voidcn.com/article/p-fsekcbpa-mt.html>
