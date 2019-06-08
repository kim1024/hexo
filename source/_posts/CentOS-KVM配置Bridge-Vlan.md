---
title: CentOS-KVM配置Bridge-Vlan
date: 2019-06-04 15:08:24
categories: 
 - VLAN
 - KVM
tags:
  - vlan
  - bridge
randnum: kvm-bridge-vlan
---
## 基本信息

- 在使用Vlan之前，需要加载`8021q`
`modprobe 8021q`
- 如果系统已经加载可以不用执行以上步骤
`lsmod | grep 8021q`
- 使用epel-release安装vconfig
`sudo yum install vconfig -y `
- 停用NetworkManager服务
`sudo systemctl disable NetworkManager && sudo systemctl stop NetworkManager`

![info](https://s2.ax1x.com/2019/06/04/VtU9MQ.png)
<!--more-->
## 操作步骤

1. 分别创建2个网卡eth0.1,eth0.2和2个网桥br0.1,br0.2
```
cd /etc/sysconfig/network-script
sudo touch ifcfg-eth0.1 ifcfg-eth0.2 ifcfg-br0.1 ifcfg-br0.2
```
2. 分别配置网卡eth0.1和eth0.2
```
TYPE=Ethernet
DEVICE=eth0.1
# DEVICE=eth0.2
ONBOOT=yes
BOOTPROTO=static
VLAN=yes
BRIDGE=br0.1
# BRIDGE=br0.2
```
3. 分别配置网桥br0.1,br0.2
```
TYPE=Bridge
DEVICE=br0.1
# DEVICE=br0.1
ONBOOT=yes
BOOTPROTO=static
DELAY=0
```
4. 分别将创建的网卡和网桥启动
```
sudo ifdown eth0 && sudo ifup eth0
sudo ifup eth0.1
sudo ifup eth0.2
sudo ifup br0.1
sudo ifup br0.2
```
5. 查看网桥信息
`brctl show`
![brctl-show](https://s2.ax1x.com/2019/06/04/Vt8AIS.png)
6. 创建3个虚拟机，分别连接到各自的网桥
```
sudo virt-install \
--name cirros \ # cirros cirros-1 cirros-2
--virt-type qemu \
--os-variant cirros0.4.0 \
--graphics vnc \
--memory 512 \
--vcpus 1 \
--network bridge=br0.1,model=virtio # cirros cirros-1连接br0.1，cirros-2连接br0.2
--disk /path/cirros.qcow2 \
--import
```
7. 分别启动3个vm
```
sudo virsh start cirros
sudo virsh start cirros-1
sudo virsh start cirros-2
```
8. 分别设置vm的ip地址
- cirros:192.168.1.10
- cirros-1:192.168.1.11
- cirros-2: 192.168.2.10
```
cd /etc/network
sudo vi interface
---cirros---
iface eth0 inet static
address 192.168.1.10
netmask 255.255.255.0
-------
---cirros-1---
iface eth0 inet static
address 192.168.1.11
netmask 255.255.255.0
-------
---cirros-2---
iface eth0 inet static
address 192.168.2.10
netmask 255.255.255.0
-------
```
![show-ip](https://s2.ax1x.com/2019/06/04/VtYass.png)
9. 查看网桥信息，可以看到vm的网卡的挂载情况
`brctl show`
![brctl-show](https://s2.ax1x.com/2019/06/04/VtYcz4.png)
10. 测试网络连通情况
cirros<->cirros-1
`ping 192.168.1.12`
cirros<-x-x->cirros-2
`ping 192.168.2.10`
cirros-1<-x-x->cirros-2
![ping-test](https://s2.ax1x.com/2019/06/04/VtNSBR.png)
