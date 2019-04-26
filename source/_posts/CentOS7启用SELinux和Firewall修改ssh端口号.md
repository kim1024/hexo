---
title: CentOS7启用SELinux和Firewall修改ssh端口号
date: 2019-04-21 08:39:31
categories:
 - CentOS
 - ssh
tags:
  - ssh
  - SELinux
randnum: centos_ssh_port
---

## 基本信息

CentOS：CentOS Linux release 7.6.1810 (Core)
SELinux：enforced
Firewall：enforcing

## 生成ssh密钥对

1. 生成密钥对
`ssh-keygen -t rsa -b 2048` \#默认存放的位置是/home/user/.ssh，使用的是公钥id_rsa.pub
2. 从服务器中将私钥复制到本机
3. 或者使用本地生成的密钥对，把公钥复制到服务器中

<!--more-->

## 修改ssh配置文件

1. 备份原文件
`cd /etc/ssh && sudo cp sshd_config sshd_config.old`
2. 修改ssh配置文件
`sudo vi sshd_config`
对以下选项进行修改：
```
# 修改端口号
port 9022
# 如果服务器有多个网卡，需要修改ssh服务监听地址
ListenAddress 192.168.0.91
# 禁用ssh root登录
PermitRootLogin no
# 错误登录次数
MaxAuthTries 4
# 使用自定义的ssh_key登录
AuthorizedKeysFile /home/user/.ssh/id_rsa.pub
# 禁止使用密码和空密码登录
PasswordAuthencation no
PermitEmptyPasswords no
```

## 添加SELinux策略

1. 如果不添加SELinux策略，启动sshd服务会有*Permission denied*报错;
![journalctl -xe](https://s2.ax1x.com/2019/04/20/ECFzKx.png)
2. 查看ssh的SELinux端口
`sudo semanage port -l | grep ssh`
如果提示没有semanage命令，使用命令`sudo yum whatproides /usr/sbin/semanage`查看需要安装的软件包;
![whatprovides](https://s2.ax1x.com/2019/04/20/ECAATU.png)
安装软件包`sudo yum install policycoreutils-python -y`,之后再重新查看ssh的端口号;
![ssh_port](https://s2.ax1x.com/2019/04/20/ECAvB6.png)
3. 添加策略
`sudo semanage port -a -t ssh_port_t -p tcp 9022`
`sudo semanage port -l | grep ssh`
![add_port](https://s2.ax1x.com/2019/04/20/ECEJbV.png)

## 添加Firewall策略

1. 只允许本机或某个网段通过指定的端口号ssh登录到服务器
```
su root
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.90" port port="9022" protocol="tcp" accept' --permanent
firewall-cmd --reload
firewall-cmd --zone=public --list-all
```
[![add_rule](https://s2.ax1x.com/2019/04/20/ECEIKI.png)](https://imgchr.com/i/ECEIKI)

## 重启sshd服务

1. 使用systemctl重启sshd服务
`sudo systemctl restart sshd`

## 远程ssh登录

1. Linux下ssh登录
`ssh -p 9022 user@server_host`
或者使用Linux本机下的ssh密钥对
`ssh-copy-id user@server_host`
2. Windows下ssh登录
使用putty，配置服务器地址和端口号，选择ssh_key验证登录
