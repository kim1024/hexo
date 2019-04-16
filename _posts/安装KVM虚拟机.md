---
title: CentOS安装KVM虚拟机
date: 2018-11-11 14:14:07
categories: 
 - KVM
tags:
  - CentOS
  - KVM
randnum: centos-kvm
---

# CentOS 安装KVM虚拟机

## 环境
- CentOS7
- KVM
- Qemu-kvm

## 安装
1. 安装kvm
  - `yum install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer`
  -  `systemctl enable libvirtd`
  -  `systemctl start libvirtd`
<!--more-->

2. 检查kvm的安装
  - `lsmod | grep -i kvm`
3. 配置桥接网络
  - `brctl show` # 查看本机桥接网络
  -  `virsh net-list --all` # 查看kvm网络
  - `cd /etc/sysconfig/network-scripts && cp ifcfg-enp0s31f6 ifcfg-enp0s31f6.old && vi ifcfg-enp0s31f6` # 添加BRIDGE=br0
  -  `touch ifcfg-br0 && vi ifcfg-br0`
   ```
   DEVICE="br0"
   BOOTPROTO="static"
   IPADDR="192.168.0.100"
   PREFIX="24"
   GATEWAY="192.168.0.1"
   DNS1="192.168.0.1"
   IPV6INIT="no"
   ONBOOT="yes"
   TYPE="Bridge"
   DELAY="0"
   ```
  - `systemctl restart NetworkManager`
  - `ifdown enp0s31f6 && ifup enp0s31f6`
4. 导入虚拟机
  ```
  virt-install \
  --name centos1 --os-variant auto --kvm --memory 2048 --vcpus 2 --graphics vnc --netwok bridge=br0,model=virtio --disk /home/user/kvm/centos1.qcow2 --import
# 或者使用xml文件重新定义一个虚拟机
  virsh dedine centos.xml
# 使用virt-viewer连接到虚拟机
  virt-viewer centos1
  ```
5. 错误
![kvm-permission denied error](https://s1.ax1x.com/2018/11/12/iLJLMn.png)
  - 在创建完成虚拟机后，会出现`Permission denied` 的错误提示，常规的解决方法有以下几个方法：
	1. 关闭selinux
	  - `vi /etc/selinux` /# 将selinux设置为permissive或disabled
	2. 将用户添加到kvm用户组中
	  - `usermod -a -G libvirt username`
	  - `usermod -a -G kvm username`
	  - `usermod -a -G qemu username`
	  - `usermod -a -G wheel username`
	3. 修改libvirt配置文件中定义的用户和用户组
	  - `vi /etc/libvirt/qemu.conf` /# 添加user="username" group="kvm" 
	4. 修改设备文件kvm的用户和用户组
	  - `cd /dev/ && chown root:kvm kvm` /# 用户组要与配置文件中定义的用户组对应

## 参考
1. <https://www.cyberciti.biz/faq/how-to-install-kvm-on-centos-7-rhel-7-headless-server/>
