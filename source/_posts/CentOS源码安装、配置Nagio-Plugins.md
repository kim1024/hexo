---
title: CentOS源码安装、配置Nagios+Plugins
date: 2019-05-01 15:21:26
categories:
 - Nagios
tags:
  - nagios
randnum: centos_install_nagios
---

## 禁用SELinux

根据官方的指导文件需要禁用SELinux，首先我们获取SELinux状态，如果处于启用状态，切换为宽容模式permissive。
```
# 获取SELinux状态
getenforce
# 修改为宽容模式
sudo vi /etc/selinux/config
# 修改enforing为permissive
```

## 安装Nagios

1. 安装依赖程序
`sudo yum install gcc glibc glibc-common wget unzip httpd php gd gd-devel perl postfix -y`
2. 下载Nagios core源码文件
`cd ~/ && wget https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.3.tar.gz`
3. 解压源码文件
`cd ~/ && tar -xzvf nagios-4.4.3.tar.gz`
<!--more-->
4. 编译源文件
```
# 切换到源码文件根目录
cd ~/nagios-4.4.3
# 配置
./configure
# 编译文件
sudo make all
```
5. 创建nagios用户和组,并修改apache用户的默认组
`sudo make install-groups-users && sudo usermod -a -G nagios apache`
6. 安装
`sudo make install`
7. 将nagios安装为服务
`sudo make install-daemoninit && sudo systemctl enable httpd.service`
8. 安装命令行模式
`sudo make install-commandmode`
9. 安装配置文件
`sudo make install-config`
10. 安装Apache配置文件
`sudo make install-webconf`
11. 配置防火墙
```
# 切换到root用户
su root
# 添加80端口到public，防蚊源根据实际情况，选择单一ip地址或ip地址范围
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.90" port port="80" protocol=tcp" accept' --permanent
firewall-cmd --reload
# 切换到管理员用户
su kim
```
12. 创建Nagios管理员用户*na_admin*
`sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users na_admin`
需要输入管理员密码，再重新输入一次密码。
创建系统管理员后，如果还需要额外创建其他用户，使用命令`sudo htpasswd /usr/local/nagios/etc/htpasswd.users na_user`,主要不要使用参数`-c`否则会替换原来的系统管理员。
13. 启动Apache服务和Nagios服务
```
# 启动Apache
sudo systemctl start httpd.service
# 启动Nagios
sudo systemctl start nagios.service
```
14. 测试Nagios
打开本地浏览器，输入Nagios服务器的域名或ip地址，*http://ip/nagios*
![nagios_web](https://s2.ax1x.com/2019/04/30/EGEhm4.png)

## 安装Nagios-plugins

Nagios插件的安装目录是*/usr/local/nagios/libexec/*
1. 安装依赖
`sudo yum install gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release -y`
`sudo yum install perl-Net-SNMP -y`
2. 下载plugin源码
```
cd ~/
wget -O nagios-plugins-release-2.2.1.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar -xzvf nagios-plugins-release-2.2.1.tar.gz
```
3. 编译安装
```
cd ~/nagios-plugins-release-2.2.1
# 配置
sudo ./tools/setup
./configure
# 使用多线程编译
sudo make -j10
# 安装
sudo make install
```

## 配置Nagios

### 基本信息

Nagios的配置文件位于`/usr/local/nagios/etc`,配置文件以`.cfg`结尾，主要的文件是`nagios.cfg`。
`check_external_comands`参数控制是否直接通过web接口运行Nagios，参数为**1**为启用。
Nagios的主机、服务等相关的配置文件位于`/usr/local/nagios/etc/object`目录中，关于本机的相关配置位于文件`localhost.cfg`中。
对于Nagios配置文件进行检查可以通过`sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg`。
*cgi.cfg*文件中还需要设定允许哪些用户运行外部命令。
将新添加的Nagios管理员用户添加到*cgi.cfg*文件中，否则Nagios Web会提示用户权限的错误。

### 添加远程监控主机

1. 使用localhost主机的模板文件，添加1个Linux服务器：
```
# 复制localhost模板
cd /usr/local/nagios/etc/object
sudo cp localhost.cfg v-centos.cfg
# 编辑复制的配置文件
sudo vi v-centos.cfg
# 按照实际情况修改文件
# 模板,根据需要从template.cfg中选择或添加
use 		linux-server
hostname 	v-centos
address		192.168.0.91
# hostgroup和service根据实际情况修改
```
2. 将新增的配置文件添加到*nagios.cfg*文件中
`echo "cfg_file=/usr/local/nagios/etc/objects/v-centos.cfg" > /usr/local/nagios/etc/nagios.cfg`
3. 检查Nagios配置文件
`sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg`
4. 配置文件无错误，重启Nagios服务
`sudo systemctl restart nagios`
5. 在远程主机中开启**5666**端口
```
su root
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.92" port port="5666" protocol="tcp" accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.92" port port="5666" protocol="udp" accept' --permanent
firewall-cmd -reload
```
6. 打开Nagios Web界面查看新增的主机
![remote_host](https://s2.ax1x.com/2019/05/01/EJ5PVs.png)
7. 修改检查ssh的默认端口
在我们新增的主机上，ssh的端口被修改为9022,在Nagios默认的命令中，是使用默认的22端口来检查。
修改的方法是在命令后添加`!-p 9022`即可。
```
# 修改v-centos.cfg文件
# 定位到检查ssh的service
define service {

    use                     local-service          
    host_name               v-centos
    service_description     SSH
    check_command           check_ssh!-p 9022
    notifications_enabled   0
}
# 重启Nagios服务
sudo systemctl restart nagios
```
![ssh_status](https://s2.ax1x.com/2019/05/01/EJTJzV.png)

## 参考
1. [Install Nagios on CentOS7](https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html#CentOS)
2. [Nagiso remote monitor](https://lowendbox.com/blog/remote-server-monitoring-with-nagios/)
