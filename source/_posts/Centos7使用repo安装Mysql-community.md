---
title: Centos7使用repo安装Mysql-community
date: 2019-04-15 11:35:28
categories: 
 - centos
 - mysql
tags:
  - mysql
  - 安装
randnum: centos-install-mysql57
---
## 下载mysql-repo

- 通过<https://dev.mysql.com/downloads/repo/yum/>下载RHL7的repo软件源;
- 如果需要，则上传下载的repo文件到服务器中;
![Download-repo.png](https://s2.ax1x.com/2019/04/15/AXXNWR.png)

<!--more-->
## 在Centos中安装repo

- `rpm -ivh mysql80-community-release-el7-2.noarch.rpm`
- 如果系统中已经安装mysql-community的repo，则使用`rpm -Uvh mysql80-community-release-el7-2.noarch.rpm`来更新;

## 使用yum-config-manager选择mysql版本

- 安装的repo默认启用mysql80-community版本，如果需要安装mysql57-community则使用`yum-config-manager`来启用
- 启用mysql57安装源
  1. 安装`yum-utils` `yum install yum-utils -y`
  2. 禁用mysql80安装源 `yum-config-manager --disable mysql80-community`
  3. 启用mysql57安装源 `yum-config-manager --enable mysql57-community`
  4. 查看启用的mysql安装源 `yum repolist enabled | grep mysql`
![check-repo.png](https://s2.ax1x.com/2019/04/15/AXXrwD.png)

## 安装Mysql57-community-server

- 安装
  - `yum install mysql-community-server -y`
- 启动mysql
  - `systemctl start mysqld`
- 查看mysql默认密码
  - `cat /var/log/mysqld.log | grep passw`
- 修改root密码
  - `mysql -u root -p` \#使用默认的密码登录mysql
  - `alter user 'root'@'localhost' identified by 'NewPasswd2019!';` \#新的密码要符合mysql的密码策略，否则会出错
  - `flush privileges;`
![default_passwd.png](https://s2.ax1x.com/2019/04/15/AXvNKx.png)
- 授权用户
  - `create user db_user identified by 'newPasswd';`
  - `create database test;`
  - `grant all on test.* to 'db_user'@'192.168.0.90' identified by 'newPasswd';`
  - `flush privileges;`
  
## 设置防火墙策略

- 查看防火墙状态
  - `firewall-cmd --zone=public --list-all`
- 添加rich-rule
  - `firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.90/24" port port="3306" protocol="tcp" accept'` --permanent
  - `firewall-cmd --reload`
![add-rich-rule.png](https://s2.ax1x.com/2019/04/15/AXvjdU.png)

## 远程连接数据库

- 使用nmap工具扫描服务器
  - `nmap -A 192.168.0.91`
![anmap-detail.png](https://s2.ax1x.com/2019/04/15/Aj95gH.png)
- 远程连接数据库
  - 使用命令行或者workbench工具连接数据库
![workbench.png](https://s2.ax1x.com/2019/04/15/Aj9LUf.png)

## 参考

1. <https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/>
