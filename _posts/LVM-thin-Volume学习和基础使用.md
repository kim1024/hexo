---
title: LVM-thin-Volume学习和基础使用
date: 2018-11-24 10:12:43
categories: 
 - LVM
 - 学习笔记
tags:
  - LVM
  - thinpool
randnum: lvm-thin-pool
---


## thin Volume 导图

![LVM thin pool](https://s1.ax1x.com/2018/11/24/FF3SpR.png)

<!--more-->

## 操作

1. 创建thin pool设备
  - `lvcreate -L 2G -T centos/thinpool`
  \# 在centos卷组中创建一个实际存储空间为2G，设备名为thinpool
  
  ![lvcreate](https://s1.ax1x.com/2018/11/24/FF1opn.png)
  
2. 查看设备使用信息
  - `lvs centos`
  
  ![lvs centos](https://s1.ax1x.com/2018/11/24/FF1Tlq.png)
  
3. 创建1个虚拟空间为4G的设备
  - `lvcreate -V 4G - T centos/thinpool -n thin-tmp`
  
  ![lvcreate-thinlv](https://s1.ax1x.com/2018/11/24/FF1HXV.png)
  
4. 创建文件设备
  - `mkfs.xfs /dev/centos/thin-tmp`
  
5. 挂载到系统
  - `mount /dev/centos/thin-pool /tmp`
  
6. 向新建的设备中分别写入500M、1G的数据
  - `dd if=/dev/zore of=/tmp/test.img bs=1M count=500`
  
  ![dd](https://s1.ax1x.com/2018/11/24/FF1qmT.png)
