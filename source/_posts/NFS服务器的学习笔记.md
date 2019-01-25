---
title: NFS服务器的学习笔记
date: 2019-01-14 13:15:36
categories:
  - 学习笔记
  - NFS
tags:
  - NFS
randnum: nfs-server-learning
---

## 基础

NFS是Network FileSystem的缩写，用于网络中不同操作系统之间的文件共享，NFS中不同的功能会启用不同的端口(小于1024)，由于这个特性，就需要远程过程调用RPC服务。RPC的主要功能是指定每个NFS功能所对应的端口号，并且回报给客户端，让客户端连接到正确的端口号。
在NFS启动时会随即取用多个端口，并主动向RPC注册，因此RPC可以知道每个端口对应的功能，RPC使用固定的111端口来监听客户端的请求。
NFS服务器主要任务是进行文件的分享，文件系统的分享与权限有关。NFS启动至少需要2个daemons，一个管理客户端能否登录，一个管理客户端能够取得的权限。
<!--more-->

## 安装

- 安装RPC主程序
`yum install rpcbind`
- 安装NFS主程序
`yum install nfs-utils`

## 配置

- NFS配置文件
  - NFS的配置文件位于`/etc/exports`,如果系统中没有该文件，需要自行创建;
  - 在配置文件`exports`中，每一行的最前面代表要分享的**目录**,根据不同的权限可以分配给不同的客户端,在主机或网段后面直接用括号将对应的全县括起来，多个权限的可以使用符号`,`分割，主机名称可以使用通配符号`* ?`；
```
/tmp	192.168.0.0/24(ro) 192.168.0.100(rw) kvm-centos(ro,sync)
# 在192.168.0.0/24网段中对/home/tmp具有读写权限，不在该网段的只有读权限
/home/tmp	192.168.0.0/24(rw) *(ro)
```
  - 主机对应的权限：
    - rw 分享的权限为read和write
    - ro 分享的权限为read only
    - sync 数据会同步写入到内存和磁盘中
    - async 数据会暂存内存中，不写入磁盘
    - `no_root_squash/root_squash` 预设情况下，客户端以root登录的，NFS会由`root_squash`压缩为nfsnobody，如果需要开放客户端root登录，需要设定`no_root_squash`
    - all_squash 不管客户端以什么身份登录，都被压缩为nfsnobody
    
## NFS管理

- 启动NFS
```
# 启动rpc
systemctl start rpcbind
# 开启自启动
systemctl enable rpcbind
# 启动nfs
systemctl start nfs
# 开启自启动
systemctl enable nfs
```
- 查看NFS和rpc启动的端口号
`netstat -tulnp | grep -E '(rpc|nfs)'`
- 查看本机的rpc注册情况
`rpcinfo -p localhost`
- 本机测试联机情况
`showmount -e localhost` \# 可用参数有2个:a/e，前者表示查看主机与客户端的挂载情况
- 修改`exports`文件后需要重新载入
  - 重新载入用到的命令是`exportfs`
    - a 全部挂载/卸载文件内的设定
    - r 重新挂载文件内的设定，同时同步更新`exports /var/lib/nfs/xtab`中的内容
    - u 卸载某一个目录
    - v 将分享的目录输出到屏幕
- 固定NFS使用的端口号
  - 通过修改文件`/etc/sysconfig/nfs`中关于端口号的选项,主要有mountd/rquotad/nlockmgr这三个服务，分别对应的是`RQUOTAD_PORT/LOCKD_TCPPORT/LOCKD_UDPPORT/MOUNTD_PORT`
- 将nfs和rpc服务加入到防火墙中
  - 修改nfs的端口号为固定，使用rpcinfo查询出注册的`mountd|rquotad|nlockmgr`的端口号，将端口号分别加入到防火墙中
  - `rpcinfo -p localhost | grep -E '(mountd|rquotad|nlockmgr)'`
```
firewall-cmd --zone=public --add-service=rpc-bind --permanent
firewall-cmd --zone=public --add-service=nfs --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address=192.168.0.0/24 port port=32802-32804 protocol=tcp accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address=192.168.0.0/24 port port=32802-32804 protocol=udp accept' --permanent
firewall-cmd --reload
```
- NFS的挂载
  - 在客户端中需要启动rpcbind，执行挂载命令`mount -t nfs ip or server_name:/path /mount_path`
  - 使用额外的参数
    - suid/nosuid 挂载/不挂载suid
    - rw/ro 挂载为读写或只读
    - dev/nodev 保留/不保留挂载设备的特殊功能
    - exec/noexec 挂载的文件具有/不具有执行权限
    - user/nouser 允许/不允许用户对文件进行挂载与卸载
    - auto/noauto mount -a 时自动/不自动挂载
