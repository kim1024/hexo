---
title: CentOS下使用openswan配置IPsec
date: 2019-04-30 09:30:28
categories:
 - Linux
tags:
  - ipsec
  - openswan
randnum: openswan_ipsec
---
## 基础信息

使用开源的openswan搭建*Host_to_Host*基于Ipsec RSA加密的Tunnel，用于保障主机之间数据传输的机密性。
openswan由2个组建构成：KLIPS和Pluto。KLIPS是执行加密解密数据的内核级代码，同时管理SPD(Security Policy Databases,安全策略数据库);Pluto是用户登录守护进程，控制IKE(Internet Key Exchange,因特网密钥交换)协商。
<!--more-->
## 安装Openswan

1. 使用yum安装
`sudo yum whatprovides openswan`
`sudo yum install libreswan-3.25-4.1.el7_6.x86_64 -y`

## 启动/检查IPsec

1. 启动ipsec服务
`sudo systemctl start ipsec`
2. 检查ipsec
`sudo ipsec verify`
对**[FAILED]**条目进行检查
![ipsec_verify](https://s2.ax1x.com/2019/04/29/ElRwC9.png)
  - 启用ip_forward
  `echo 1 > /proc/sys/net/ipv4/ip_forward`
  - 禁用send_redirects
  `cd /proc/sys/net/ipv4/conf/default && echo 0 > send_redirects`
  - 禁用其他选项，使用`echo 0 >`到其他文件中
3. 重新检查ipsec
`sudo ipsec verify`
![ipsec_re_verify](https://s2.ax1x.com/2019/04/29/El4HQs.png)

## 配置openswan

配置文件：*/etc/ipsec.conf*和*/etc/ipsec.secrets*
初始化NSS数据库:
```
cd /etc/ipsec.d
rm -fr ./*.db
ipsec initnss
```

### 两个主机之间的机密隧道

1. 生成rsa密钥
在left主机中生成密钥`/usr/libexec/ipsec/newhostkey --output /etc/ipsec.d/v_to_test.secrets`
![newhostkey](https://s2.ax1x.com/2019/04/29/E1xSTe.png)
查看生成的密钥id`ipsec showhostkey --list`
2. 配置文件`v_to_test.conf`

```
conn v_to_test
     left=192.168.0.91
     leftid=@v-centos
     lefersasigkey=lef_rsa_key
     #leftnexthop=%defaultroute
     right=192.168.0.92
     rightid=@centos-test
     rightrsasigkey=right_rsa_key
     authby=rsasig
     #rightnexthop=%defaultroute
     auto=start
```
3. 将生成的密钥添加到配置文件中
```
# 查看密钥的id
ipsec showhostkey --list
# 根据id查看rsa公钥-left
ipseck showhostkey --left --ckaid ckaid_id
# 根据id查看rsa公钥-right
ipseck showhostkey --right --ckaid ckaid_id
```
![showhostkey](https://s2.ax1x.com/2019/04/30/E8En3T.png)
4. 在left端启动v_to_host的ipsec
`ipsec auto --up v_to_host`
![isec_auto](https://s2.ax1x.com/2019/04/30/E8VWJx.png)
5. 连同测试
```
# 在right端启动tcpdump抓取网络端口enp0s3上的esp标签数据包
tcpdump -n -i enp0s3 esp
# 在left端启动ping测试
ping centos-test
# 查看right端数据包抓取情况
```
![ping_test](https://s2.ax1x.com/2019/04/30/E8EZ40.png)
6. tunnel使用状况
`ipsec whack --trafficstatus`

## 参考

1. <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-securing_virtual_private_networks>
