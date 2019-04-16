---
title: Linux主机iptables学习笔记
date: 2019-01-12 11:23:55
categories: 
 - Linux
 - 学习笔记
tags:
  - iptables
randnum: iptables-learning
---

在Linux中使用和核心内建的封包过滤机制Netfilter,Netfilter提供了iptables这个软件作为防火墙封包过滤的指令。
程序控管TCP Wrappers是另一种抵挡封包进入的方法，这种方法是通过服务器程序的外挂tcpd来处置的。与封包过滤不同的是，这种机制主要是分析谁对某程序进行存取，然后透过规则去分析该服务器程序谁能够联机、谁不能。TCP Wrappers是透过客户端想要链接的程序文件名，然后分析客户端的IP地址，看是否放行。
封包过滤式防火墙主要是分析OSI七层协议中的2/3/4层，可以进行的分析工作有：

  - 拒绝让Internet的封包进入主机的某些端口
  - 拒绝让某些来源IP的封包进入
  - 拒绝让某些带有特殊标记Flag的封包进入
  - 分析硬件地址MAC来决定是否允许进入
  
<!--more-->
## TCP Wrappers

TCP Wrappers是透过/etc/hosts.allow /etc/hosts.deny这2个文件来管理的，但是并不是所有的软件都可以用来管控，目前可以管控的程序有：
  - 由super daemon(xinetd)所管理的服务；
    - 配置文件在/etc/xinetd.d里面的服务就是xinetd管控
    - 系统中需要安装xinetd程序，使用chkconfig --list查看xinetd管控的程序
  - 有支持libwrap.so模块的服务；
规则执行的顺序是：先对比hosts.allow中的规则，再对比hosts.deny中的规则，如果2个文件中都不符合，则放行

## iptables

预设iptables至少有3个表格：filter、nat、mangle
- filter主要与进入主机的封包有关
  - INPUT与进入主机的封包有关
  - OUTPUT与主机所要发送的封包有关
  - FORWARD与传递封包到后段的主机中，与nattable相关
- nat主要在进行来源目的ip或port的转换，主要与主机后的局域网内的主机相关
  - PREROUTING在进行路由判断之前所要进行的规则
  - POSTROUTING在进行路由判断后所要进行的规则
  - OUTPUT与发送的封包有关
- mangle与特殊封包的路由标记有关

## iptable语法

### 规则查看

`iptables [-t tables] [-L] [-nv] or iptables-save [-t table]`,后者会列出完整的防火墙规则
  - -t 后接table，默认是filter
  - -L 列出目前的table的规则
  - -n 不进行ip与hostname的反查
  - -v 显示详细信息

- 每个Chain代表1个链，括号内的policy就是预设政策
  - target 代表进行的动作，ACCEPT放行，REJECT拒绝，DROP丢弃
  - prot 代表使用的封包协议，主要有tcp\udp\icmp三种
  - opt 额外的选项说明
  - source 代表规则是针对哪个来源IP进行限制
  - destination 代表规则针对哪个目标IP进行限制
  - *开头的是表格
  - : 开头的是链
  
### 规则清除

`iptables [-t table] [-FXZ]`
  - -F 清除所有的已定的规则
  - -X 杀掉所有使用者自定义的chain
  - -Z 将所有的chain的计数与流量统计归零
- 定义预设政策
  - 在重新定义防火墙时，需要先将规则清除，操作最好是在本机执行；
`iptables [-t table] -P [INPUT,OUTPUT,FORWARD] [ACCEPT,DROP]`
  - -P 定义政策，注意大写
  
### 规则定义

`iptables [-AI 链名] [-io 网络接口] [-p 协议] [-s 来源ip] [--sport port][-d 目标ip] [--dport port] -j [ACCEPT|DROP|REJECT|LOG]`
  - -AI 链名针对某链进行规则的累加或插入，链名有3个:INPUT\OUTPUT\FORWARD
  - -A 新增一条规则到原有规则的最后
  - -I 插入一条规则，如未指定顺序，默认为第一条
  - -io 网络接口，设定封包进出的接口规范
  - -i 封包进入的网络接口
  - -o 封包所传出的网络接口
  - -p 协议
    - 主要的封包格式有:tcp\udp\icmp\all
  - -s 来源ip，设定规则生效的来源，可以是单个ip，也可以是网段，如果是不允许某个ip或网段，则在地址前面加!
    - --sport 限制来源的端口号，端口号可以是连续的n1:n2，如果使用了--sport或--dport必须要加-p参数，否则会出错
  - -d 目的ip或网段
    - --dport 限制到目的的端口号
  - -j 后面接动作，主要的动作有ACCEPT\DROP\REJECT\LOG
- 需要注意的是，网络接口lo需要设置为信任装置iptables -A INPUT -i lo -j ACCEPT
- 规则添加的顺序非常重要，例如我们利用iptables限制ssh的登陆
`iptables -A INPUT -i eth0 -s 192.168.0.100 -p tcp --dport 22 -j ACCEPT`
`iptables -A INPUT i eth0 -p tcp --dport 22 -j REJECT`
- iptables还支持syn的处理方式，一般来说，client启用的端口号都是大于1024的，服务端启用的端口号都是小于1023的，我们使用iptables将从1：1023发起的主动连接到本机的请求全部拒绝
`iptables -A INPUT -i eth0 -p tcp --sport 1:1023 --dport 1:1023 --syn -j REJECT`
- 使用iptables禁用主机的ping响应
`iptables -A INPUT -i eht0 -p icmp --icmp-type 8 -j REJECT` # 禁用所有的主机ping
`iptables -I INPUT -i eht0 -s 192.168.0.100 -p icmp --icmp-type 8 -j ACCEPT` #允许ping的主机
