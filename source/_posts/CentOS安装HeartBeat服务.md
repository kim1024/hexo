---
title: CentOS安装HeartBeat服务
date: 2018-11-16 15:09:05
categories: 
 - CentOS
 - HA
tags:
  - HeartBeat
randnum: centos-heartbeat
---

# CentOS安装HeartBeat服务

## 环境

- 主机：CentOS9
- 依赖
  - Cluster Glue
  - Resource Agents

<!--more-->

## 安装

### 安装Cluster Glue

1. 下载软件源码
   - 下载地址：<http://www.linux-ha.org/wiki/Downloads>
2. 安装编译所需依赖
   - `yum install glib2-devel libtool-ltdl-devl net-snmp-devel bzip2-devel ncurses-devel openssl-devel libtool libxml2 libxml2-devel gettext bison flex zlib-devel mailx which libxslt docbook-dtds docbook-style-xsl PyXML shadow-utils opensp autoconf automake bzip2 e2fsprogs-devel libxslt-devel libtool-ltdl-devel make asciidoc libuuid-devel`
3. 配置编译软件
   - `./autogen.sh`
   - `./configure --prefix=/usr/local/heartbeat`
   - `make -j 20`
4. 安装
   - `make install`

### 安装Resource Agent

1. 下载软件源码，并上传到服务器中
2. 解压软件源码压缩包
3. 配置编译软件
   - `./autogent.sh`
   - `export CFLAGS="${CFLAGS} -I/usr/local/heartbeat/include -L/usr/local/heartbeat/lib"`  **注意-I与-L与后接字段间无空格，如出现错误需要unset变量CFLAGS**
   - `./configure --prefix=/usr/local/heartbeat`
   - `ln -s /usr/localheartbeat/lib/* /lib/`
   - `ln -s /usr/local/heart/lib/* /lib64/`
   - `make -j20`
4. 安装
   - `make install`

### 安装HeartBeat

1. 下载软件源码，并上传到服务器中
2. 解压软件源码
3. 配置编译软件
   - `./bootstrap`
   - `./configure --prefix=/usr/local/heartbeat`
   - `make -j20`
     - 编译会出现一个`HA_HBCONF_DIR" redefined [-Werror]`的错误提示，说明在`glue.conf.h`中，宏`HA_HBCONF_DIR`被定义多次，编辑文件`glue_conf.h`,将代码`define HA_HBCONF_DIR "/usr/local/heartbeat/etc/ha.d/"`删除掉，重新编译。文件位置`/usr/local/heartbeat/include/heartbeat`
4. 安装
   - `make install`
   - `cd doc cp -a ha.cf authkeys haresources /usr/local/heartbeat/etc/ha.d/`
   - `ln -svf /usr/local/heartbeat/lib64/heartbeat/plugins/RAExec/* /usr/local/heartbeat/lib/heartbeat/plugins/RAExec/`
   - `ln -svf /usr/local/heartbeat/lib64/heartbeat/plugins/* /usr/local/heartbeat/lib/heartbeat/plugins/`
   - `groupadd haclient`
   - `useradd -r -s /bin/nologin -g haclient hacluster`



## 配置

- 编辑HeartBeat的配置文件

  - `cd /usr/local/heartbeat/etc/ha.d && cp ha.cf ha.cf.old && vi ha.cf`

  - 修改以下内容

    ```
    # 保存调试信息文件
    debugfile /var/log/ha-debug 
    # 日志文件
    logfile /var/log/ha-log
    # 使用系统日志
    logfacility local0
    # 心跳的时间间隔，单位秒
    keeplive 2
    # 超出该时间未收到对方节点的心跳，则判定对方死亡
    deadtime 30
    # 超出改时间未收到对方节点的心跳，则发出警告记录日志
    warntime 10
    # 在某系统上，系统启动或重启后需要经过一段时间网络才能正常工作，该参数就是为解决这个问题，取值至少时deadtime的2倍
    initdead 120
    # 设置广播通信使用的端口，默认694
    udpport 694
    # 传播心跳的广播网卡
    bcast eth0
    # 对方服务器心跳检测ip
    ucast eth0 192.168.0.82
    # 设置为on表示一旦主节点恢复运行，则自动获取资源并取代从节点
    auto_failback off
    # 配置主从节点
    node centos-kvm
    node centos1106-kvm
    # 如果ping不通该地址，就认为当前断网
    ping 192.168.0.1
    # 指定与HeartBeat一同启动和关闭的进程，该进程自动监视，遇到故障则重新启动。
    # 最常用的经常是ipfail，该进程用于检测和处理网络故障需要配合ping语句指定的ping
    respawn heartbeat /usr/local/heartbeat/libexec/heartbeat/ipfail
    # 指定用户和组
    apiauth ipfail gid=haclient uid=hacluster
    ```

  - 在其他节点中配置HeartBeat时，只需要修改广播网卡和对方心跳检测的ip

- 编辑认证文件,并修改权限为600

  - `auth 2`
  - `2 sha1 HI`

- 编辑资源配置文件haresources

  - `centos1 Ipaddr::192.168.0.80/24/eth0:0 mysqld` \# centos1作为主结点，192.168.0.80作为vip，mysql是主机启动后执行的脚本，脚本所在目录与资源配置文件相同
  - 脚本mysqld内容`/etc/init.d/mysqld`



## 参考

1. <https://blog.csdn.net/wzy0623/article/details/81188814#%E4%BA%8C%E3%80%81%E5%AE%89%E8%A3%85Heartbeat> 