---
title: Fedora使用Proxychains代理终端程序
date: 2019-01-16 10:50:56
categories:
  - 工具
tags:
  - proxychains
randnum: proxychains_fedora
---

## 基础

Proxychins以下简称Pcs，是全局代理服务，可以在命令行中通过Pcs代理各种软件，支持的协议有：http/https/socks4/socks5。
在Fedora中使用的是`proxychains-ng`,使用命令查看软件包的相关信息`dnf info proxychains-ng`.

<!--more-->

## 安装与配置

- 安装
`dns install proxychains -y`
- 配置
Pcs默认的配置文件是`proxychains.conf`,默认存放的位置是`/etc/proxychains.conf`,配置文件查找的先后顺序是:
  1. `./proxychains.conf`
  2. `~/.proxychains/proxychains.conf`
  3. `/etc/proxychains.conf`
Pcs支持多种代理模式，默认的是`strict_chain`:
  1. `dynamic_chain`:动态模式，按照代理列表先后顺序，逐级连接，组成一条连接，如有失效服务器，自动排除；
  2. `strict_chain`:严格模式，严格按照代理列表先后顺序，逐级连接，组成一条连接，所有服务器必须有效；
  3. `round_robin_chain`:轮询模式，自动跳过不可用代理；
  4. `random_chain`:随即模式，随机使用代理列表中的服务器；
代理列表：
```
[ProxyList]
socks5 127.0.0.1 1080
https  127.0.0.1 1090
```

## 使用

PCS的使用主要在命令行中，使用的语法是`proxychains4 command options`
在当前bansh中执行的任意命令都通过Pcs`proxychains4 -q /bin/bash`
还可以通过别名的方式，缩短程序名称`alias pcs4='proxychains4'`
