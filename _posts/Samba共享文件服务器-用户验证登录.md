---
title: Samba共享文件服务器-用户验证登录
date: 2018-10-30 12:24:24
categories: 
 - Samba
tags:
  - Samba
  - 学习笔记
  - 验证登录
randnum: samba-account
---

# Samba设定需要密码访问资源

1. 设定一个系统用户,并加入到系统原有账户`kim`的群组中

   1. `sudo useradd -G kim -d /home/smb_kim -s /bin/bash smb_kim`  //新建用户smb_kim，使用/bin/bash,home目录为/home/smb_home，群组为kim
   2. `sudo passwd smb_kim` //修改密码
<!--more-->

2. 设置配置文件`smb.conf`

   ```
   [global]
   	workgroup = kimhome
   	netbios name = kimserver
   	server string = This is a file share server!
   	log file= /var/log/samba/log.%m-%I@%T # 变量m代表客户端NetBiso name，变量I代表客户端ip地址，变量T代表当前系统时间
   	max log size = 50
   	load printers = no 
   	security = user
   	passdb backend = tdbsam # 使用tdb数据库格式
   
   [share]
   	comment = smb_kim\'s share 
   	browseable = no # 除了使用者外，其他人不可浏览
   	writeable = yes
   	create mode = 0664 # 建立文件的权限为664
   	directory mode = 0775 # 建立目录的权限为775
   	write list = @kim # kim 群组下的用户都可以使用
   ```

3. 检查配置文件`testparm`

4. 将系统中的用户添加到samba中

   1. `sudo pdbedit -a -u smb_kim` //需要单独输入samba的密码
      1. `pdbedit -a|-r|-x -u user` 分别代表增加|修改|删除用户
   2. `sudo pdbedit -L [-vw]` //显示当前数据库中的账号信息
      1. `-v` 搭配`-L`使用，列出更多信息
      2. `-w` 搭配`-L`使用，使用旧版的smbpasswd格式显示数据
