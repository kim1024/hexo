---
title: CentOS使用X11VNC轻量界面并启用SSH加密
date: 2019-06-04 10:29:22
categories: 
 - CentOS
 - VNC
tags:
  - VNC
  - SSH
randnum: centos-install-x11vnc
---

## 安装X11VNC程序

- x11vnc轻量级VNC服务程序
- Xvfb轻量级Xorg服务程序

```
sudo yum install xorg-x11-xauth xterm libXi libXp libXtst libXtst-devel libXext libXext-devel Xvfb x11vnc -y
```
<!--more-->
## 配置SSH服务

- 安装ssh服务，并启用key验证;
- ssh使用的端口号为`9022`

## 配置x11vnc服务

- x11vnc服务使用的端口号为`9033`
- 使用ssh端口转发，为x11vnc服务提供加密服务
  - 在服务器中启用x11nvc服务,并监听本地
  `sudo x11vnc -localhost -rfbport 9033 -passwd VncPasswd -create`
  - 还可以将x11vnc服务在后台中运行
  `nohup x11vnc -localhost -rfbport 9033 -passwd VncPasswd -create > /dev/null 2&>1 &`
  ![start-vnc-service](https://s2.ax1x.com/2019/06/04/VYovL9.png)
  - 本地主机先通过ssh登录到服务器，将VNC服务监听的端口转发到本地主机
  `ssh -p 9022 remote_server -L 9033:localhost:9033`
  ![ssh-login](https://s2.ax1x.com/2019/06/04/VYTSd1.png)
  - 在本地使用VNC Viewer软件连接到本地的9033端口
  ![vnc-viewer](https://s2.ax1x.com/2019/06/04/VYTiRO.png)

## 参考

1. [CentOS 7.2搭建VNC远程桌面服务](https://www.linuxidc.com/Linux/2018-02/151091.htm)
2. [Arch-wiki-x11vnc](https://wiki.archlinux.org/index.php/X11vnc_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
