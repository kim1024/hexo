---
title: 文件特殊权限SUID、SGID、SBIT
date: 2019-04-29 10:39:23
categories:
 - Linux
tags:
  - SUID
  - SGID
  - SBIT
randnum: linux_SUID_SGID_SBIT
---

## SUID

SUID的标识符为`s`,当该符号出现在文件拥有者权限的x位置时，表明该文件具有SUID权限。SUID的权限仅对二进制程序有效，对shell脚本是无效的，并且SUID仅在执行过程中有效。
![passwd_SUID](https://s2.ax1x.com/2019/04/29/El0USS.png)
SUID的权限数字为4,设置的方法是在原来wrx的权限数字前再加上1个4,例如：原文件权限为511,加SUID的权限则4511。

<!--more-->
## SGID

当符号`s`出现在文件拥有者群组x位置时，则称为SGID。SGID可以设置二进制程序，也可以设置目录，如果对目录设置了SGID权限，使用者可以在具有rx权限时进入该目录;使用者在该目录下的有效群组将会变成**该目录的群组**;使用者在该目录具有w权限，新建的文件群组与该目录的群组相同。
![locate_SGID](https://s2.ax1x.com/2019/04/29/El0LlD.png)
SGID的权限数字为2,设置方法同SUID。

## SBIT

SBIT仅对目录有效，对文件无效。对目录的作用是：使用者对目录有wx权限，在该目录下创建文件或目录时，仅有自己和root有权限删除。
SGID的权限数字为1,设置方法同SUID。

## 查找

1. 查找根目录下的特殊文件(SUID和SGID)
`find / \(-perm -4000 -o -perm -2000\) -exec ls -la {} \;`
- 'perm -4000' find命令中根据文件权限查找，`-4000`表示所有包括`SUID`权限的文件
