---
title: bash进站与欢迎信息
date: 2018-12-06 11:06:29
categories:
  - bash
  - 学习笔记
tags:
  - bash
  - 学习笔记
randnum: bash-login-welcome
---
- bash的进站与欢迎信息，通过文件`/etc/issue`和`/etc/motd`2个文件实现
- CentOS默认的进站信息如下：
```
\S
Kernel \r on an \m

```
<!--more-->
  - issue文件中，使用符号`\`调用变量，各个变量的内容如下：
    - `\d` 本地端时间
    - `\l` 显示第几个终端机接口
    - `\m` 现实硬件的等级
    - `\n` 显示主机的网络名称
    - `\O` 显示domain name
    - `\r` 显示操作系统的版本--> `uname -r`
    - `\t` 显示本地端时间
    - `\S` 显示操作系统的名称
    - `\v` 操作系统的版本
    
- 终端登陆CentOS显示的bash进站信息
![login-info](https://s1.ax1x.com/2018/12/06/Flx8qU.png)

- 通过telnet方式登陆主机时，bash的进站的信息通过文件`/etc/issue.net`修改
- 用户通过bash登陆后会有欢迎信息，该信息通过文件`/etc/motd`修改
