---
title: XFS文件系统中quota的使用
date: 2018-11-27 09:31:25
categories: 
 - XFS
tags:
  - XFS
  - quota
  - 磁盘限额
randnum: quota-with-xfs
---

## 概述

- 在xfs文件系统中，使用quota可以针对用户、群组、文件夹进行磁盘限额;
- 在限额的操作中，使用最多的命令就是`xfs_quota -x -c` ;
- quota的限制是针对文件系统的，跨文件系统是无法实现quota的;
- quota的使用应该尽量避免在根目录下使用，如果前期为规划文件系统，后期需要对某个目录进行限额，可以将**原目录完整的移动到/home下，然后利用`ln -s /home/dir /old/dir`创建一个软连接，在/home下对文件夹进行限额**

## 操作

1. 文件系统
  - xfs文件系统支持quota核心功能，在使用quota限额时，避免在根目录下使用
  - 查看home分区的文件系统信息`df -hT /home`
  
2. 修改ftab
  -xfs文件系统的quota在挂载时就已经宣告，无法使用remount来重新启动quota功能，因此要写入fstab中，或者在初始故在过程中加入这个项目，否则不会生效;
  - 修改fstab文件`cp /etc/fstab /etc/fstab.old && vi /etc/fstab`,找到home分区，在第四段内容后添加`usrquota,grpquota`2项内容;需要注意的是：在修改完成后需要测试，若存在错误需要立刻处理，否则不能开机;在卸载分区前，需要将一般账号全部退出，否则不能卸载，`who`查看当前在线的用户，`pkill -kill -t pts/n`命令强制用户离线。
  
<!--more-->
  
  ![vi-fstab](https://s1.ax1x.com/2018/11/26/FAVyan.png)
  
    - 针对quota限额的使用有3项：
      1. usrquota:针对使用者账号
      2. grpquota:针对群组
      3. prjquota:针对单一目录，但是**不能与grpquota同时存在**
      
3. 重新挂载分区
  - `umount /home && mount -a`
  - `mount | grep home` \# 查看home分区的挂载信息
  
  ![mount-grep](https://s1.ax1x.com/2018/11/26/FAVgP0.png)
  
4. 使用xfs_quota命令查看quota报告
  - xfs_quota命令格式`xfs_quota -x -c "comm" [mount_dir]`
    - `-x`专家模式，只有使用了该参数，才能使用`-c`指定命令
    - `-c`指定命令
      - `print` 列出目前主机内的文件系统参数等数据
      - `df` 与系统的`df`命令一样
      - `report` 列出目前的quota项目，有ugr(user/group/project)及bi等数据
      - `state` 说明目前支持quota的文件系统的信息
      
      ![xfs_quota-report](https://s1.ax1x.com/2018/11/26/FAV4r4.png)
      
5. 限额的设置
- 限额用户和用户组
  - 设定系统中test用户的限额为200M/300M,群组共500M/600M的容量，同时grace time为7天
  - 限额的命令格式`xfs_quota -x -c "limit [-ug] b[soft|hard]=N i[soft|hard]=N name"` `xfs_quota -x -c "timer [-ug] [-bir] Ndays"`
    - `limit` 指定限定的项目，可以针对user和group限制
    - `bsoft|bhard` `isoft|ihard` block(磁盘容量)和inode(文件数量)的hard与soft值 通常hard要比soft限额高，hard表示使用者的用量绝对不会超过这个限额;soft表示在使用者低于限额可以正常使用，若高于soft低于hard，每次登陆系统时，系统会主动发送磁盘即将爆满的警告，并且会有一个宽限时间grace time，如果在grace time时间内不进行任何磁盘关联，soft会取代hard值，达到hard值后，磁盘使用权将会被锁住无法新增文件
  - `xfs_quota -x -c "limit -u bsoft=200M bhard=300M test" /home` \# 限定用户test
  - `xfs_quota -x -c "limit -g bsoft=500M bhard=600M test" /home` \# 限定用户组test
  - `xfs_quota -x -c "timer -u -b 7days"` \# 设定用户宽限时间为7天
  - `xfs_quota -x -c "timer -u -b 7days"` \# 设定用户组宽限时间为7天
  
  ![xfs_quota-limit&timer](https://s1.ax1x.com/2018/11/26/FAtz3F.png)
  
  - 分别测试`bsoft|bhard|grace time`，使用`dd`命令在用户`test`home下写入220M数据，查看quota报告
  
  ![xfs_quota-time-test](https://s1.ax1x.com/2018/11/26/FANiH1.png)
  
- 限额目录
  - 在使用限额目录功能前，需要取消group的限额，取消`grpquota`加入`prjquota`
  - 限定用户test家目录下web文件夹的限额400M/500M
  - 首先取消grpquota,添加prjquota
    - `vi /etc/fstab`
  - 重载分区
    - `umount /home && mount -a`
    - `mount | grep /home` \# 查看home分区的挂载信息
    
    ![mount-grep-home-prjquota](https://s1.ax1x.com/2018/11/26/FABbxf.png)
    
    - `xfa_quota -x -c "state" /home` \# 查看quota状态，grpquota已经关闭
    
    ![grpquota-off](https://s1.ax1x.com/2018/11/26/FADALF.png)
    
  - 限额目录需要指定**项目名称和识别码**，项目名称webquota,识别码26
    - 指定项目识别码与对应目录`echo "26:/home/test/web" >> /etc/projects`
    - 指定项目识别码与名称 `echo "webquota:26" >> /etc/projid`
  - 初始化项目名称
    - `xfs_quota -x -c "project -s webquota"`
    - `xfs_quota -x -c "print" /home`
    - `xfs_quota -x -c "report -pbih" /home`
    
    ![print webquota project](https://s1.ax1x.com/2018/11/26/FADTw4.png)
  
  - 设置项目限额
    - `xfs_quota -x -c "limit -p bsoft=400M bhard=500M webquota" /home`
    - `xfs_quota -x -c "report -pbih" /home`
    
    ![projectlimit](https://s1.ax1x.com/2018/11/26/FADXSx.png)
    
  - 在文件夹web下写入450M的数据，测试quota的project
    - `dd if=/dev/zero of=./project.img bs=1M count=450`
    
    ![project-show](https://s1.ax1x.com/2018/11/27/FEFTzD.png)
    
  - 如果需要限定其他目录的磁盘使用，只需要创建一个项目并将该项目初始化，再执行项目限额的操作即可
  
## xfs_quota的管理

### 常用的管理命令
 
   1. `disable` 暂时取消quota的限制，系统还在计算quota，只是没有管制;
   2. `enabled` 恢复到正常的管理状态，在使用了`disable`后可以使用该命令恢复到正常的状态;
   3. `off`     完全关闭quota的限制，使用了该命令后只有重载文件系统，才能重新启用quota;
   4. `remove`  杂子`off`状态才可以使用该命令，如果要取消webquota项目的限制,可以直接使用`remove -p`,需要注意的是，使用该命令会**移除所有项目的限制**
    
