---
title: Linux操作环境target与runlevel等级
date: 2019-01-12 11:14:43
categories: 
 - Linux
tags:
  - runlevel
  - root密码
randnum: target-runlevel
---

在核心载入完毕、完成硬件侦测与驱动载入后，核心会主动调用第一个程序systemd。systemd的主要功能是准备软件执行的环境，包括系统的主机名称、网络设置、语系设置、文件系统及其他服务的启动。所有的动作都会通过systemd的默认启动服务集合/etc/systemd/system/default.target来规划。
默认的操作环境default.target主要项目有：multi-user.target和graphical.target;
使用命令`systemctl get-default`获取当前的运行级别；
使用命令`systemctl set-default [target]` 设置系统的默认运行级别

<!--more-->
## runlevel与systemd的对应关系


| System V | systemd |
| :------: | :-----: |
| init 0 | poweroff |
|init 1 | rescue |
| init [234] | multi-user.target |
| init 5 | graphical.target |
| init 6 | reboot |

## 忘记root密码

新版本的systemd，默认的rescue模式无法直接取得root权限，所以无法通过rescue模式重置root密码。可以通过rd.break核心参数来处理，该核心参数是Ram Disk里面的操作系统状态，不能直接取得原本的操作系统环境，还需要chroot的支持。

## 重置root密码流程

1. 按下电源启动，进入开机画面后，选择开机菜单，按下e进入编辑模式,找到第一个linux16开头的内容，在末尾添加`rd.break`,ctrl+x执行开机；

2. 进入Ram Disk环境，原本的系统被挂载到/sysroot目录下;
  - 首先检查挂载点，找到原系统的挂载目录`mount`
  - 将系统目录重新挂载为可读写`mount -o remount,rw /sysroot`
  - 使用chroot切换到根目录`chroot /sysroot`
  - 重置root密码`passwd --stdin root`
  - 新建.autorelabel文件`touch /.autorelabel` 很重要的一步
  - 因为修改了root用户的密码，文件`/etc/shadown`文件内容发生改变，所以这个文件的SELinux安全文本会被取消，如果没有让系统开机时自动的回复SELinux的安全文本，将会出现无法登陆的问题；
  - 退出`/sysroot exit`
  - 重启`reboot`
