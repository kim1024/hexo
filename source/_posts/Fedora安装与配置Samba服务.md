---
title: Fedora安装与配置Samba服务
date: 2019-01-12 11:45:51
categories: 
 - fedora
 - samba
tags:
  - samba
  - fedora
randnum: fedora-samba
---
- 安装
`dnf install samba -y`
- 配置
  - samba的配置文件位于`/etc/samba/smb.conf`
  - 需要配置的文件有2部分`[global]`和`[share]`
<!--more-->
```
[global]
	workgroup=samba
	netbios name=samba_server #需要与workgroup不同
	server string=samba_server
	log file=/var/log/samba/%T_%I_%m.log
	max log size=50
	load printers=no
	security=USER
	passdb backend=tdbsam
	lanman auth=yes
	ntlm auth=yes	#xp使用samba需要开启以上2个认证
	hosts allow=192.168.0. 	# 仅允许192.168.0.0/24网段的用户访问
[share]
	comment=home
	path=/path
	browseable=yes
	writetable=yes
	writelist=user1,@group1
	create mode=0644
	director mode=0755
```
  - 测试配置文件`testparm`
  - 将系统中的用户添加到samba中
  `pdbedit -a -u user`
  - 添加防火墙规则
  `firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address=192.168.0.0/24 port port=139 protocol=tcp --accept' --permanent`
  `firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address=192.168.0.0/24 port port=445 protocol=tcp --accept' --permanent`
  `firewall-cmd --reload`
  - 添加SELinux配置
```
setsebool -P samba_export_all_ro=1 samba_export_all_rw=1
getsebool –a | grep samba_export
semanage fcontext –at samba_share_t "/finance(/.*)?"
restorecon /finance
```
  - 启动samba服务
  `systemctl start smb.service`
  `systemctl enable smb.service`
  - 在Windows系统中映射网络磁盘
  - 在Linux中挂载磁盘:
```
# 使用smbclient观察samba服务
smbclient -L server_ip -U user_name
# 以FTP的方式的登陆
smbclient '//ip/share' -U user_name
# 以网络磁盘的方式挂载
mount -t cifs //ip/share /mnt -o username=user,password=passwd,vers=1.0
*如果出现不能挂载的情况，需要指定vers版本号为1.0*
```
