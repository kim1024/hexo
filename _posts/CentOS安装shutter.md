---
title: CentOS安装shutter
date: 2018-11-12 14:52:50
categories: 
 - CentOS
tags:
  - CentOS
  - shutter
randnum: centos-shutter
---

# 使用Nux-dextop软件源安装软件
## 简介

- Nux-dextop是类Rhel的的第三方软件源，同样对CentOS也有很好的支持。Shutter是Linux上强大的截图工具，在系统默认的repo中，未包含该软件。
- 在使用Nux-dextop之前需要安装`repel-release` repo源，可以通过执行命令`yum install repel-release`完成安装。

<!--more-->

## 安装

1. `yum -y install epel-release && rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm` /# 安装reel-release和nux-dextop
2. `yum makecache`
3. `yum install shutter --enablerepo=nux-dextop` /# 安装shutter

## 参考
1. <https://www.2daygeek.com/install-enable-nux-dextop-repository-on-centos-rhel-scientific-linux/>
