---
title: CentOS安装Zabbix监控软件
date: 2019-05-05 15:34:14
categories:
 - Zabbix
tags:
  - Zabbix
  - shell
randnum: install_zabbix_with_shll
---

## 安装

1. 添加Zabbix 安装源
`sudo rpm -ivh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm`
2. 安装zabbix-server,frontend,agent(if need)
`sudo yum install zabbix-server-mysql zabbix-web-mysql zabbix-agent -y`
3. 安装Mysql数据库
4. 初始化数据库
解压create.sql.gz文件`cd /usr/share/doc/zabbix-server-mysql-4.0.7 && sudo gzip -d create.sql.gz`
<!--more-->
```
# login in mysql
mysql-u root -p
# create database for zabbix
create database zabbix character set utf8 collate utf8_bin;
# create user and grant all privileges 
grant all privileges on zabbix.* to 'db_za'@'localhost' identified by 'Zabbix_Passwd@2019';
# flush
flush privileges;
# import create.sql
use zabbix;
source /usr/share/doc/zabbix-server-mysql-4.0.7/create.sql;
```
5. 配置Zabbix数据库
```
# 复制原文件
cd /etc/zabbix/ && sudo cp zabbix_server.conf zabbix_server.conf.old
# 编辑配置文件
sudo vi zabbix_server.conf
# add database info
DBHost=localhost
DBName=zabbix
DBUser=db_za
DBPassword=Zabbix_Passwd@2019
```
6. 配置时区
关于时区的配置文件存放在*/etc/httpd/conf.d/zabbix.conf*中
```
cd /etc/httpd/conf.d/ && sudo cp zabbix.conf zabbix.conf.old
sudo vi zabbix.conf
# timezone
php_value date.timezone Asia/Shanghai
```
7. 配置与Zabbix有关的SELinux <sup>1</sup>
```
su root
grep zabbix_t /var/log/audit/audit.log | audit2allow -M zabbix_server_custom
semodule -i zabbix_server_custom.pp
# 查看zabbix需要启用的策略
yum install policycoreutils-python -y
getsebool -a | grep zabbix
setsebool -P zabbix_can_network=1
setsebool -P httpd_can_connect_zabbix=1
setsebool -P zabbix_run_sudo=1
# 如果使用了远程数据库还需要进行以下设置
setsebool -P httpd_can_network_connect=1
setsebool -P httpd_can_network_connect_db=1
```
7. 启动Zabbix服务
`sudo systemctl start zabbix-server zabbix-agent httpd`
8. 启动界面安装
打开浏览器，输入Zabbix地址`http://ip/zabbix`,输入数据库信息，使用默认的用户名和密码登录Admin/zabbix
9. Zabbix安装脚本
使用tar打包压缩，并使用openssl des3 -salt密码加密->[install_zabbix_shell.tar.gz](https://drive.google.com/file/d/1-e6jgPYNzPVDzb_EhReFGALW9C3ptWZg/view?usp=sharing)
加密压缩：`tar -czvf - install_zabbix.sh zabbix.sql | openssl des3 -salt -k passwd -out install_zabbix_shell.tar.gz`
加密解压：`openssl des3 -d -k passwd -salt -in install_zabbix_shell.tar.gz | tar xzf -`
10. 最新数据中，监控条目出现“no data”
如果Zabbix Agent使用的是主动模式，监控模板使用的是默认的Linux系统监控模板，那么我们需要clone一个模板，并将clone后的模板中的**type**修改为**zabbix agent(acvite)**,这样就可以接收到数据。
![nodata](https://s2.ax1x.com/2019/05/09/EgVR3R.png)
![Zabbix Agent Active](https://s2.ax1x.com/2019/05/09/Egmfvn.png)

## 参考

1. [SELinux And Zabbix](https://www.zabbix.com/forum/zabbix-help/367261-selinux-and-zabbix)
