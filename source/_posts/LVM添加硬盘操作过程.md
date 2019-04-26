---
title: LVM添加硬盘操作过程
date: 2019-04-24 12:16:10
categories:
 - lvm
tags:
  - lvm
randnum: lvm_add_partition
---


## 基本信息

系统中原有一个lvm0的卷组，卷组中有3个lv，名称和挂载分别是:home->/home,root->/,swap->swap
新添加的硬盘是*/dev/sdb*大小为465.8G，需要新增1个卷组，名称为lvm1,划分为2个lv，名称和大小分别是work->200G,personal-->200G,分区格式为xfs，分别挂载到~/work和~/personal
![lvs](https://s2.ax1x.com/2019/04/24/EV94WF.png)
<!--more-->

## 操作过程

1. 新建分区
```
# 使用fdisk分区
sudo fdisk /dev/sdb
# 创建1个分区，大小分别是401G
按p输出当前分区信息，d删除当前分区，g创建1个新的GPT分区表，n新建1个主分区，p查看分区信息，w保存推出
```
![add_partition](https://s2.ax1x.com/2019/04/24/EV95z4.png)

2. 新建pv分区
```
# 查看pv分区
sudo pvscan
# 将新分区添加到pv分区
sudo pvcreate /dev/sdb{1,2}
# 查看新pv分区
```
![pvcreate](https://s2.ax1x.com/2019/04/24/EVCqXj.png)

3. 新建逻辑卷组lvm1
`sudo vgcreate -s 4M lvm1 /dev/sdb{1,2}`
![vgcreate](https://s2.ax1x.com/2019/04/24/EVPK3D.png)
4. 创建lv
```
# 新建lv用于work,增加到200G，添加到lvm1卷组
sudo lvcreate -L 200G -n work lvm1
# 新建lv用于personal,增加到200G，添加到lvm1卷组
sudo lvcreate -L 200G -n personal lvm1
# 查看lv分区
sudo lvdisplay
```
![lvdisplay](https://s2.ax1x.com/2019/04/24/EVivWT.png)
5. 格式化lv分区
```
# 分别将lv分区格式化为xfs格式
sudo mkfs.xfs /dev/lvm1/work
sudo mkfs.xfs /dev/lvm1/personal
```
![mkfs.xfs](https://s2.ax1x.com/2019/04/24/EVFMmd.png)
6. 自动挂载分区
```
# 备份原文件
cd /etc && sudo cp fstab fstab.old
# 编辑fstab文件
sudo vi fstab
# 将lv分区添加
/dev/mapper/lvm1-work /home/kim/work xfs defaults 0 0
/dev/mapper/lvm1-personal /home/kim/personal xfs defaults 0 0
```
![add_fstab](https://s2.ax1x.com/2019/04/24/EVkC38.png)
7. 新建挂载目录
`cd ~ && mkdir work personal`
重启进入系统后，可以分别到work和personal目录下查看磁盘空间`df -BG ./`
![df](https://s2.ax1x.com/2019/04/24/EVkO2T.png)
需要注意的是**如果移除了某个lv分区，并且该分区在fstab文件中，同时需要在fstab文件中，将该分区移除，否则启动时会报错**
