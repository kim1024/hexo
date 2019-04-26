---
title: 使用PAM控制登录访问
date: 2019-04-23 14:10:52
categories:
 - 安全
tags:
  - pam_access
  - pam_time
randnum: pam_access_time
---

## 限制访问的来源

**pam_access**模块可以限制登录的用户或用户组的来源。利用该模块，首先需要配置那些需要使用该模块的服务。通过编辑`/etc/pamd.d`中服务的pam配置文件来实现。
1. 将`pam_access`模块添加到login服务中
```
cd /etc/pam.d && sudo cp login login.old
sudo vi login
# 新增一行
account  required  pam_access.so
```
![add_pam_access](https://s2.ax1x.com/2019/04/23/EArbjK.png)
<!--more-->
2. 编辑文件`/etc/security/access.conf`
当一个服务配置文件中的一个条目调用了`pam_access`,它将彻底检查`access.conf`文件，并停留在第一个匹配的行上。`access.conf`文件配置的原则是：具体条目放在前面，通用条目放在后面。
条目格式：
```
permission : users : origins
permission #permission可以为+或-，分别表示授权访问，拒绝访问
 : users   #可以指定用户或用户组，可以使用空格分隔多个用户或组，还可以使用user@host的形式，host表示被登录主机的本地主机名
 : origins #可以使用主机名来表示远程主机源，LOCAL关键字用来表示本地访问，还可以使用ALL和EXCEPT关键字。还可以使用ip地址，域名
```
1. 禁止用户test1本地登录主机
```
cd /etc/security
sudo cp access.conf access.conf.old
sudo vi access.conf
-:test1:ALL
```
![add_user](https://s2.ax1x.com/2019/04/23/EA6LuV.png)
2. 禁止用户kim通过workpc主机ssh登录主机
```
# 启用pam_access
cd /etc/pam.d && sudo cp sshd sshd.old
# 添加pam_access模块
auth  required  pam_access.so
# 添加用户
cd /etc/security/ && sudo vi access.conf
# 添加一行数据
-:kim:workpc
# 只允许通过workpc登录
-:kim:EXCEPT workpc
# 允许workpc和192.168.0.99登录
+:kim:workpc
+:kim:192.168.0.99
-:kim:ALL
```
Login_From_workpc
![login_from_workpc](https://s2.ax1x.com/2019/04/23/EAcjMt.png)
Login_From_192.168.0.99
![login_from_99](https://s2.ax1x.com/2019/04/23/EAg8Q1.png)
Login_From_192.168.0.98
![login_from_98](https://s2.ax1x.com/2019/04/23/EAgndU.png)

## 限制访问时间

限制访问时间使用`pam_time`模块来实现，通过修改文件`/etc/security/time.conf`来进行设置。
配置格式：
`services;devices;users;times`
- service条目可以通过'/etc/pam.d'内的文件获取;
- devices可以使用!ttyp\*表示控制台，ttyp\*用来表示远程设备，tty\*用来表示所有设备
- users列表可以使用符号`|`分隔;
- times每个时间范围由2个字符缩写，前面的用来指示规则应用日期，后面一个用来指示在哪几个小时之间Mo\Tu\We\Th\Fr\Sa\Su，Wk表示工作日，Wd表示周末，A1表示每周的每一天
1. 在需要启用的服务中添加`pam_time`模块
```
cd /etc/pam.d && sudo vi sshd
# 添加模块
account  required  pam_time.so
```
2. 添加详细条目
```
cd /etc/security && sudo cp time.conf time.conf.old
sudo vi time.conf
# 添加条目,禁止用户test1在周二的13：30-14：00期间所有终端登录
sshd;*;test1;!Tu1330-1400
```
