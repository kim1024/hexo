---
title: Debian安装配置Bridge网络
date: 2018-11-15 16:07:06
categories: 
 - Debian
 - 网络
tags:
  - Debian
  - 桥接
  - Bridge
randnum: debian-bridge
---

# Debian 安装配置Bridge网络

## 安装

1. 安装桥接网络所需要的软件
  - `apt install bridge-utils`
2. 配置文件`/etc/network/interfaces`
  - 仅保留网络`lo`的配置，其他的全部删除
3. 进入附加网络配置文件夹
  - `cd /etc/network/interfaces.d`
  - 添加桥接网络的配置文件`touch br0 && vi br0`
	```
	bridge_ports enp0s31f6 # enp0s31f6通过网桥连接网络
	bridge_stp off # 不使用生成树协议
	bridge_waitport 0 # 在端口可用前无延迟
	bridge_fd 0 # 无转发延迟
	```
  - 如果本机有多个网卡，需要将多个网卡逻辑到网卡中，还可以使用命令`brctl addif br0 eth1 eth2`
  
<!--more-->
4. 重启网络管理器
  - `systemctl restart network-manager`
  - `systemctl status network-manager`
5. 查看本机的网络，原设置的ip地址已经消失，只剩下网桥的ip地址
  ![show ip addr](https://s1.ax1x.com/2018/11/15/iveA3t.png)

## 参考
1. <https://www.cyberciti.biz/faq/how-to-configuring-bridging-in-debian-linux/>
2. <https://wiki.debian.org/BridgeNetworkConnections>
