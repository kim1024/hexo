---
title: 软件磁盘阵列在xfs文件系统中的使用
date: 2018-11-27 16:45:15
categories: 
 - XFS
tags:
  - RAID
  - 磁盘阵列
  - 存储
randnum: raid-with-xfs
---

## 概述

- 磁盘阵列由硬件磁盘阵列(Raid卡)和软件磁盘阵列，RAID可以通过技术，将多个较小的磁盘合成一个较大的磁盘设备;这个磁盘设备除了具有存储功能，还有数据保护功能;
- 根据RAID等级的不同，常见的可以分为RAID0、RAID1、RAID1+0/0+1、RAID5、RAID6，最为常用的是RAID1+0

<!--more-->

## RAID-0等量模式

**RAID-0等量模式(stripe)性能最佳，数据损坏风险高**

- 这种模式是使用相同型号与容量的磁盘来组成时，效果较佳;
- 工作的原理是：磁盘先切除等量的区块(chunk,一般4k-1M)，当文件要写入RAID时，文件会依据chunk的大小切割好，然后依序放到各个磁盘中;
- 每个磁盘会交错的存放数据，文件被写入RAID时，数据会等量的放置在各个磁盘上;因为数据已经被切割并且放置在不同的磁盘中，因此每个磁盘负责的数据量都降低了;
- 使用RAID0存储数据，整个可用的磁盘空间受最小的一颗磁盘限制，当容量最小的一颗磁盘已经写满，那么其他磁盘也不再写入数据;同样的，如果其中一颗磁盘损坏，导致数据丢失了一块，那么存放在RAID中的文件将不能读取

![RAID 0](https://s1.ax1x.com/2018/11/27/FEJfwq.png)



## RAID-1映射模式

**RAID-1映射模式(mirror)完整备份，数据损坏风险低，磁盘可用容量低** 

- RAID-1模式最好使用一模一样的磁盘，磁盘的可用容量由最小的一颗决定;
- 工作的原理是：一份数据传送到RAID-1后，在I/O总线后被复制多份到各个磁盘，每个磁盘都存有同一份文件，整个磁盘的可用容量只有50%;由于每个磁盘内都有一个文件的副本，任何一颗磁盘损坏时，数据还是可以完整的保存下来;
- 使用软件磁盘阵列时，在大量写入的情况下，RAID-1的写入性能会变得很差;

![RAID 1](https://s1.ax1x.com/2018/11/27/FEJ7pF.png)



## RAID 1+0/0+1模式

**RAID 1+0/0+1模式是RAID-0和RAID-1的组合模式**，RAID 1+0就是先让2颗硬盘组成RAID-1模式，这样的设置有2组，再将这2组RAID-1组成一组RAID-0;RAID 0+1就是先组成RAID-0,再组成RAID-1模式。

![RAID 1+0](https://s1.ax1x.com/2018/11/27/FEYSfO.png)

## RAID 5/6

**RAID5需要至少3颗磁盘，类似于RAID0性能和数据备份的均衡考虑**，在每次循环写入的过程中,在每颗磁盘还加入一个同位检查数据，这个数据会记录其他磁盘的备份数据，用于当磁盘损坏时的救援;
- 使用RAID5时，每次循环写入时，都会有部分的同位检查码被记录，并且记录的同位检查码每次都记录在不同的磁盘中，因此，任何一个磁盘损坏时都能由其他磁盘的检查码来重建原本磁盘内的数据;
- RAID5的总可用磁盘数量是总磁盘数量减1，默认仅能支持1颗磁盘的损坏情况，当由2颗以上的磁盘出现损坏时，RAID5的数据就损毁了;
**RAID6是在RAID5的基础上使用2颗磁盘的容量作为检查码的存储，因此整体磁盘就少2颗，允许出错的磁盘数量就可以达到2颗**

## 预备磁盘

- 当磁盘阵列的磁盘损坏时，需要将坏掉的磁盘拔掉，换一颗新的磁盘。更换新的磁盘后并启动磁盘阵列，磁盘阵列会主动开始重建原本坏掉的那颗磁盘上的数据到新的磁盘上。这个过程如果系统支持热插拔，可以直接在线更换，如果不支持需要关机后操作。
- 为了让系统可以实时在硬盘损坏时主动重建，就需要预备磁盘的辅助。所谓预备磁盘就是再1颗或多颗没有包含再原本磁盘阵列等级中的磁盘，平时这颗磁盘不会被磁盘阵列所用，当磁盘阵列中由磁盘损坏时，这颗预备磁盘会主动的进入磁盘阵列，并将坏掉的磁盘移除，然后重建数据。

## RAID对比

![RAID VS](https://s1.ax1x.com/2018/11/27/FEUJAI.png)

## 软件磁盘阵列

- 软件磁盘阵列是使用软件的方式，仿真模拟磁盘阵列的功能，这种方式会损耗系统资源。在CentOS中较为常用的软件磁盘阵列工具是`mdadm`,该工具以partition或disk为磁盘单位，不需要2颗以上的磁盘，只需要2个以上的分区就可以设计出磁盘阵列。

### 设置

- 利用4个partition组成RAID5,每个partition为1G，设置1个partition为预备磁盘，chunk设置为256k(一般为64k或512k)，将RAID5设备挂载到/srv/raid上;
- mdadm命令格式`mdadm --create /dev/md[0-9] --auto=yes --level=[015] --chunk=nK --raid-devices=n --spare-devices=n /dev/sd{n1,n2,n3}`
  - 'create'          创建RAID
  - `auto=yes`        决定创建后面界的软件磁盘阵列设备
  - `chunk=nK`        chunk大小，一般64K、512K
  - raid-devices=n`   使用几个磁盘作为软件磁盘阵列设备
  - `spare-devices=n` 预备磁盘的数量
  - `level[015]`      磁盘阵列的等级，常用的是0,1,5
  - `detail`          显示设备的磁盘阵列详细信息
- 利用mdadm创建磁盘阵列
  - `mdam --create /dev/md0 --auto=yes --level=5 --chunk=256K --raid-devices=4 --spare-devices=1 /dev/vda{5,6,7,8,9}`
  
  ![mdadm-create](https://s1.ax1x.com/2018/11/27/FEyO2R.png)
  
- 查看创建的raid设备信息
  - `mdadm --detail /dev/md0` 还可以使用命令`cat /proc/mdstat`
  
  ![mdadm-detail](https://s1.ax1x.com/2018/11/27/FEyXx1.png)
  
- 格式化与挂载RAID
  - `mkfs.xfs -f -d su=256k,sw=3 -r extsize=768k /dev/md0`
    \# su指定chunk的大小，与创建raid时相同，sw指定可用磁盘容量个数(raid共4个，可用的是4-1)，extsize的计算是256k*3
  - `mount /dev/md0 /srv/raid`
  - `df -Th /srv/raid`
  
  ![mkfs-mount-df](https://s1.ax1x.com/2018/11/27/FE6fFe.png)
  
### RAID的救援
  - RAID管理常用的命令`mdadm --manage /dev/md[0-9] [--add devices] [--remove devies] [-fail devices]`
    - `add`     将设备加入到md中
    - `remove`  将设备从md中移除
    - `fail`    将md中的设备设置为出错状态
  - 写入数据到raid设备md0中
    - `cp ~/test/* /srv/raid`
  - 将磁盘设置为错误状态
    - `mdadm --detail/dev/md0` \# 查看当前raid设备的信息
    ![/dev/md0-detail-old](https://s1.ax1x.com/2018/11/28/FVY3ZR.png)
    - 目前使用的磁盘是5,6,7,8 ，9号磁盘作为预备磁盘，我们将7号磁盘设置为错误
    - `mdadm --manage /dev/md0 --fail /dev/vda7`设置后再查看raid设备的信息，9号预备磁盘已经替换7号磁盘，并重建数据中
    ![/dev/md0-detail-new](https://s1.ax1x.com/2018/11/28/FVYGIx.png)
  - 将出错的磁盘移除并加入新的磁盘
    - 将7号磁盘从raid设备中移除
      - `mdadm --manage /dev/md0 --remove /dev/vda7`
    - 系统关机，将出错的磁盘拔除，并安装新的磁盘替换7号磁盘
    - 将新加入的磁盘加入到raid设备中
      - `mdadm --manage /dev/md0 --add /dev/vda7`
      
### RAID关闭
- 获取raid设备的uuid `mdadm --detail /dev/md0 | grep -i uuid`,从文件夹中卸载设备`umount /srv/raid`
- 编辑`/etc/fstab`文件，将以uuid开头的raid设备相关的注释掉,没有可忽略
- 使用dd命令分别将raid设备中的数据覆盖`dd if=/dev/zero of=/dev/md0 bs=1M count=63`
- 关闭raid设备`mdadm --stop /dev/md0`
- 使用dd命令将磁盘中的数据覆盖或使用fdisk格式化磁盘
![stop raid](https://s1.ax1x.com/2018/11/28/FVNuDJ.png)
