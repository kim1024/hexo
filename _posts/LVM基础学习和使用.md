---
title: LVM基础学习和使用
date: 2018-11-23 15:46:51
categories: 
 - LVM
 - 学习笔记
tags:
  - LVM
  - 基础
randnum: lvm-doc
---

# LVM,PV,PE,VG,LV的学习和基础操作

## LVM

- LVM全名是`Logical Volume Manager`逻辑卷管理，LVM的作法是将几个实体的partitions或disk通过软件组合成为一块看起来是独立的大磁盘(VG),然后将这会大磁盘再经过分区成为可以使用的分区(LV),最终就可以使用了。LVM可以创建和u管理逻辑卷，而不是直接使用物理硬盘，它可以在不损坏已存储的数据的情况下弹性管理逻辑卷的大小，不需要重启系统就可以让系统内核知道分区的存在。

![LVM关系图](https://s1.ax1x.com/2018/11/23/Fi1v5j.png)

<!--more-->

### PV

- PV全名是`Physical Volume`物理卷，我们实际的partitions或disk实体磁盘，需要调整系统识别码system ID成为8e LVM识别码，然后再经过pvceate的指令将他转成LVM最底层的物理卷PV，之后才能将这些PV加以使用。
- 调整系统识别码system ID的方法就是通过`gdisk`
- 常用命令
  - pvcreate  将paritition创建为PV
  - pvscan    搜寻系统中的PV
  - pvdisplay 显示当前系统中PV信息
  - pvremove  移除PV 

### VG

- VG全名是`Volume Group`卷组，它由多个PV组成，类似于非LVM系统中的物理硬盘。
- 常用命令
  - vgcreate  创建VG
  - vgscan    搜寻系统中的VG
  - vgdisplay 显示当前系统中VG信息
  - vgremove  移除VG
  - vgextend  在VG附加新的PV
  - vgreduce  从VG中移除PV
  - vgchange  设置VG是否启动

### PE

- PE全名是`Physical Extent`物理块，每个PV被划分成为PE的基本单元，具有唯一编号的PE是可以被LVM寻址的最小单元。PE的大小是可以被配置的，默认为4M，PV的大小由同等的基本单元PE组成。

### LV

- LV全名是`Logical Volume`逻辑卷，最终的VG会被划分为LV，LV的大小与在此LV内的PE总数有关。
- 常用命令
  - lvcreate  创建LV
  - lvscan    搜寻系统中的LV
  - lvdisplay 显示当前系统中LV信息
  - lvremove  移除LV
  - lvextend  增加LV容量
  - lvreduce  从LV中减少容量
  - lvresize  调整LV容量的大小


## LVM 操作

- 在虚拟机中新增了一个5G的硬盘，使用`fdisk`将硬盘划分2个分区，1个2G，1个3G
- 系统中原有VG `centos`和分区`/boot`，VG分配了3个LV分别是`/dev/centos/root /dev/centos/swap /dev/centos/home`

![lvdisplay](https://s1.ax1x.com/2018/11/23/Fiyk1f.png)

1. 新建PV
  - `pvcreate /dev/vdb{1,2}`
  
2. 查看PV信息
  - `pvscan`
  
  ![pvscan&pvcreate](https://s1.ax1x.com/2018/11/23/Fisxne.png)
  
3. 添加VG 
  - 分别将/dev/sdb1,2添加到当前的VG
    - `vgextend centos /dev/vdb1`
    - `vgextend centos /dev/vdb2`
    
    ![vgdisplay&vgextend](https://s1.ax1x.com/2018/11/23/FiyCtI.png)
    
  - 如果需要新建VG则使用以下命令,-s表示PE大小
    - `vgcreate -s 4M centos1 /dev/vdb{1,2} `
    
4. 添加LV
  - 新建1个LV，用于/tpm，将/home扩容 <sup>1</sup>
    - `lvcreate -L 2G -n tmp centos` 
    \# -L后接容量，单位可以是MGT，最小单位是PE，后面必须是PE的倍数，若不符，系统自动计算相近的容量,i指定PE的个数
    - `lvextend -L +1G /dev/centos/home`
    \# 在参数-L后接的数字，如果在前面加**+**表示增加了多少，如果不添加符号表示增加到多少
    - `xfs_growfs /home` 
    \# home扩容1G
    - 增大LV容量的可以直接使用命令`lvresize -L +1G /dev/centos/home`  如需减少将符号`+`替换为`-`,最后使用命令`xfs_growfs`在线扩容
    
    ![xfs_growfs](https://s1.ax1x.com/2018/11/23/FiyMhq.png)

- 注意：**在xfs文件系统中，只能增加lv的大小，不能减小，在ext4文件系统中则可以**
    
    

    
5. 文件系统
  - 格式化为xfs
    `mkfs.xfs /dev/centos/tmp`
    
    ![mkfs&mount](https://s1.ax1x.com/2018/11/23/FiyeBQ.png)
    
  - 挂载
    `mount /dev/centos/tmp /tmp`
    
    ![lvscan](https://s1.ax1x.com/2018/11/23/FiyAc8.png)
    
## LVM快照

 - 快照就是将当时的系统信息记录下来，未来若是有任何数据变更，则原始数据会被搬移到快照区，没有被变更的区域则由快照区与文件系统共享。
 - 需要注意的是快照区与被快照的设备需要在同一个VG中
 - 目前系统中还有509个PE可分配空间，分配150个PE用于快照/dev/centos/root设备，快照名称root-snap

### 快照操作

 - `lvcreate -s -l 150 -n root-snap /dev/centos/root`
  \# `-s`创建快照设备，`-n` 快照设别名，`/dev/centos/root`要快照的设备
  ![lvcreate-snap](https://s1.ax1x.com/2018/11/24/FF3Ucq.png)
  
 - 查看创建的快照设备，LV Size与要快照的设备相同
  ![lvdisplay-snap](https://s1.ax1x.com/2018/11/24/FF3aj0.png)
  
 - 查看快照设备内的信息，与被快照的设别是一样的
  `mount -o nouuid /dev/centos/root-snap /mnt` \# xfs文件系统中，不允许相同的uuid文件系统挂载
  
### 快照复原

 - 利用快照区复原系统，需要注意的是**要复原的数据量不能高于快照区所有负载的实际容量**，在复原时，设备内的原始数据会被搬移到快照区，如果快照区不够大，若原始数据被变更的实际数据量比快照大，那么快照功能将会失效。
  - 分别创建一个1G的data LV和一个1G的data-snap 快照LV 
   `lvcreate -L 1G -n data centos `
  - 格式化,挂载,创建快照
   `mkfs.xfs /dev/centos/data && mount /dev/centos/data /data`
   `lvcreate -s -L 1G -n data-snap /dev/centos/data`
   `mount /dev/centos/data-snap /mnt`
    
  - 还原操作
   1. 利用快照将原来的文件系统备份<sup>2</sup>
    `xfsdump -l 0 -L lvm2 -M lvm2 -f /home/user/data.dump /mnt`
    \# xfsdump备份级别为0,所有文件全部备份 -f参数指定备份的dump文件位置， /mnt为要备份的文件
    为什么不直接格式化data分区，然后直接恢复快照呢？**如果直接格式化，原本的文件系统所有数据都会被搬移到快照区内，快照区容量不够大，那么部分数据将无法复制到快照区呢，执行快照复原的时候，就会有数据不能还原，所以需要先备份原数据**
   2. 卸载并移除快照区
     `mount /mnt && lvremove /dev/centos/data-snap`
   3. 卸载复原分区
     `umount /data`
   4. 格式化复原分区
     `mkfs.xfs -f /dev/centos/data`
   5. 重新挂载复原分区
     `mount /dev/centos/data /data`
   6. 使用xfsrestore复原分区
     `xfsrestore -f /home/user/data.dump -L lvm2 /data`
  
  
## 参考

1. <http://tldp.org/HOWTO/LVM-HOWTO/extendlv.html>
2. <https://www.systutorials.com/docs/linux/man/8-xfsdump/>