---
title: CentOS主机防火墙Firewalld学习笔记
date: 2019-01-12 11:25:52
categories: 
 - Linux
tags:
  - firewall-cmd
  - 学习笔记
randnum: firewall-cmd-learning
---
目前在CentOS中使用firewalld替代iptables，firewalld是iptables的前段控制器，与iptables的区别是：前者使用区域和服务而不是链式规则，它动态管理规则集，允许更新规则而不破坏现有的会话和连接。
firewalld的配置文件主要存放在2个位置：/usr/lib/Firewalld和/etc/firewalld,前者存放的是默认配置，后者存放的是自定义配置。

<!--more-->
## 基本命令

```
systemctl start/stop/enable/disable/status firewalld # 启动/关闭/开机启动/取消开机启动/状态
firewall-cmd --state # 运行状态
firewall-cmd --get-active-zones # 查看被激活的zone
firewall-cmd --get-zones # 查看预设zone
firewall-cmd --get-zone-of-interface=eth0 # 查看接口eth0的zone信息
firewall-cmd --zone=public --list-all # 查看指定zone的所有信息
firewall-cmd --get-service # 查看所有级别被允许的信息
firewall-cmd --zone=public --get-target --permanent # 获取public的target
```

## 规则管理命令

```
firewall-cmd --panic-on # 终止所有数据包
firewall-cmd --panic-off # 取消终止
firewall-cmd --query-panic # 查看终止状态
firewall-cmd --reload # 更新规则，不重启服务
firewall-cmd --complete-reload # 更新规则，重启服务
firewall-cmd --zone=public --add-interface=eth0 --permanent # 将eth0接口设置为public级别，永久生效
firewall-cmd --set-default-zone=public # 设置public为默认级别
```

## 端口管理命令

```
firewall-cmd --zone=public --list-ports # 现实public级别被允许进入的端口
firewall-cmd --zone=public --add-port=8080/tcp # 允许tcp端口8080至public级别
firewall-cmd --zone=public --add-port=5060-5090/udp --permanent # 允许udp端口5060-5090范围内的端口至public级别，并永久生效
```

## 端口转发命令

```
firewall-cmd --zone=public --add-masquerade # 首先打开端口转发
firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toport=8022 # 将tcp22端口转发到8022
firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toaddr=192.168.0.100 # 将22端口转发到另一个地址上的同一个端口
firewall-cmd --zone=public --add-forward-port=22:prototcp:toport=8022:toaddr=192.168.0.100 # 转发22端口到另一个地址的8022端口
```

## 网卡管理命令

```
firewall-cmd --zone=public --list-interfaces # 显示级别为public的所有网卡
firewall-cmd --zone=public --add-interface=the0 --permanent # 将eth0的级别设置为public，并永久生效
firewall-cmd --zone=dmz --change-interface=eth0 --permanent # 将网卡eth0从原来的级别修改为dmz，并永久生效
firewall-cmd --zone=public --remove-interface=eth0 --permanent # 将网卡eth0从public级别中永久删除
```

## 系统服务管理命令

```
firewall-cmd --zone=public --add-service=smtp # 添加服务smtp到public级别中
firewall-cmd --zone=public --remove-service=smtp # 从public级别中移除smtp服务
```

## zone

firewall能将不同的网络连接归类到不同的信任级别，zong提供以下几个级别

  - drop 丢弃所有进入的包
  - block 拒绝所有外部发起的连接，允许内部发起的连接
  - public 允许指定的连接进入
  - external 一般用于路由转发
  - dmz 允许受限制的连接进入
  - work 允许信任的计算机被限制的进入连接
  - home 家庭网络，仅仅接收经过选择的连接
  - internal 内部网络，仅仅接收经过选择的连接
  - trusted 信任所有连接
  
## 过滤规则

过滤规则的优先顺序是source>interface>firewalld.conf,支持的过滤规则有：

  - source 源地址
  - interface 网卡
  - service 服务名
  - port 端口
  - icmp-block icmp类型
  - masquerade ip地址伪装
  - forward-port 端口转发
  - rule 自定义规则
  
## traget

当区域处理它的源或接口上的一个包时，但是没有处理该包的显式规则时，这时区域目标的target决定了该行为，tariget有以下几种：

  - ACCEPT 通过该包
  - REJECT 拒绝该包
  - DROP 丢弃该包
  - default 不做任何事情
  
## 富文本规则

使用富文本规则，可以用比较直接接口方式更容易理解的方法建立复杂防火墙规则，还可以永久保留设置。

富文本的命令格式和结构：

```
rule [family="<rule family>"]
    [ source address="<address>" [invert="True"] ]
    [ destination address="<address>" [invert="True"] ]
    [ <element> ]
    [ log [prefix="<prefix text>"] [level="<log level>"] [limit value="rate/duration"] ]
    [ audit ]
    [ accept|reject|drop ]
```
- 一个规则是关联某个zone的，一个zone可以有多个分区，如果几个规则相互影响或冲突，则执行和数据包相匹配的第一个规则；

- 规则系列可以限定ipv4或ipv6，如果没有指定，将同时为ipv4和ipv6增加规则；
- 规则命名
  - source
    - 指定源地址,可以使用invert=”True”或invert=”Yes”来颠倒源地址；
  - denstination
    - 指定目的地址，同源地址用法
  - service
    - 服务名称
  - port
    - 端口，可以是单个端口，也可以是端口范围n1-n2,协议可以是tcp或udp
    - `port=8022-8033 protocol=tcp`
  - protocol
    - 协议，可以是协议ID数字，也可以是协议名称
    - `protocol value=icmp`
  - log
    - 注册含有内核记录的新的连接请求到规则中，可以定义一个前缀文本，记录等级可以是emerg/alert/crit/error/warning/notice/info/debug
    - 等级用正的自然数表示，继续时间的单位s/m/h/d,最大限定值是1/d
  - accept/reject/drop
    - 执行的动作可以是accept/reject/drop中的1个，选择drop所有数据包会被丢弃，并且不会向来源地发送任何信息
    
## 操作示例

1. 将ssh服务添加到internal级别中，仅允许192.168.0.0/24通过22端口访问,但是禁止192.168.0.92禁止登陆ssh
```
firewall-cmd --list-all # 查看
firewall-cmd --zone=public --remove-service=ssh --permanent # 从public中永久移除ssh服务
firewall-cmd --zone=internal --add-service=ssh --permanent # 将ssh服务添加到internal级别中
firewall-cmd --zone=internal --add-source=192.168.0.0/24 --permanent # 添加源地址
firewall-cmd --zone=internal --add-rich-rule='rule family="ipv4" source address="192.168.0.92" service name="ssh" drop' --permanent # 添加富文本规则
firewall-cmd --reload
```
2. 将ssh服务从zone中删除，在public中，仅允许192.168.0.100通过22端口访问
```
firewall-cmd --zone=internal --remove-service=ssh --permanent
firewall-cmd --zone=public --add-rich-rule='rule family=ipv4 source address=192.168.0.100 port port=22 protocol=tcp accept' --permanent
firewall-cmd --reload
```
3. 将samba服务添加到internal，允许192.168.0.0/24中的用户访问,samba会使用tcp/139/445、udp/137/138端口
```
firewall-cmd --zone=internal --set-target=default --permanent
firewall-cmd --zone=internal --add-interface=eth1 
firewall-cmd --zone=internal \
 --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port=139 protocol=tcp accept' --permanent
firewall-cmd --zone=internal \
 --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port=445 protocol=tcp accept' --permanent
firewall-cmd --zone=internal \
 --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port=137-138 protocol=udp accept' --permanent
firewall-cmd --reload
```
