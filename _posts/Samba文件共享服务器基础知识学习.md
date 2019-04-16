---
title: Samba文件共享服务器基础知识学习
date: 2018-10-30 12:22:31
categories: 
 - Samba
tags:
  - Samba
  - 学习笔记
randnum: samba-doc
---

# Samba服务器基础

## Samba服务

- nmbd
  - 用来管理工作组、NetBIOS name解析。利用UDP协议开启137\138端口解析名称。
- smbd
  - 用来管理samba主机分享的目录、档案和打印机等。利用可到的TCP协议传输数据，开放的端口是139\445

## 联机模式

- peer-peer对等模式
  - 局域网中的所有pc均可以在自己的计算机上面管理自己的账号和密码，同时每部计算机都具有独立执行各项软件的能力，只是由网络将各个pc链接在一起。
- domain model主控模式
  - 所有账号密码全都防止在一部主控计算机PDC中，在局域网中，在任何一台计算机中输入账号和密码，都可以根据身份使用不同的计算机资源。

<!--more-->
## 软件

- `samba`
  - 提供samba服务器所需要的各项服务程序、文档、与samba相关的logrotate配置文件、开机默认选项档案。
- `samba-client`
  - samba客户端程序
- `samba-common`
  - 服务器与客户端都会使用到的数据，包括samba的主要配置文件、语法检验指令。
- `/etc/samba/smb.con`
  - samba的主要配置文件，主要设定项目是服务器相关设定`global`
- `/etc/samba/Imhosts`
- 功能类似`/etc/hosts`,设定NetBios name，目前samba预设会使用本机的名称作为NetBIOS name，可不用设定。
- `/etc/sysconfig/samba`
  - 提供启动smbd、nmbd时，需要加入的相关服务参数。

## 常用脚本

### 服务器

- `/usr/sbin/{smbd,bmbd}`
  - 服务器功能，权限管理smbd，NetBIos name查询nmbd
- `/usr/bin/{tdbdump,tdbtool}`
  - 服务器功能，tdbdump可以查看数据库的内容，tdbtool则可以进入数据库操作接口直接手动修改账号密码，但是需要安装软件`tdb-tools`
- `/usr/bin/smbstatus`
  - 服务器功能，可以列出目前samba的联机状况
- `/usr/bin/{smbpasswd,edbedit}`
  - 服务器功能，管理samba用户账号和密码，后期建议使用`pdbedit`管理用户数据
- `/usr/bin/testparm`
  - 检验配置文件`smb.conf`语法是否正确，在编辑过配置文件时，务必使用`testparm`检查一次

### 客户端

- `/sbin/mount.cifs`
  - 使用`mount.cifs`将远程主机分享的档案文件与目录挂载到主机上。
- `/usr/bin/smbclient`
  - 用来查看其他计算机所分享的目录与装置，也可用在本机上查询samba设定是否成功。
- `/usr/bin/nmblookup`
  - 查询NetBIOS name
- `/usr/bin/smbtree`
  - 查询工作组与计算机名称的树状目录分布图

*update:2018-09-29*

## Samba设定流程

1. 服务器设定，在文件`smb.conf`中设定好工作组、NetBios Name、密码使用状态(无密码分享|本机密码)。
2. 规划准备分享的目录参数。
3. 建立所需要的文件系统。
4. 建立可用samba账号，建立所需的Linux实体账号，再以pdbedit建立使用samba的密码
5. 启动服务smbd，nmbd。 。

## smb.conf文件

### 注意事项

- 符号`#` `;`都是批注符号；
- 在该文件中不区分大小写；

### global项目

- `[global]`中设定的是服务器的整体参数，包括工作组、主机的NetBios Name、字符编码的显示、登录文件的设定、是否使用密码以及使用密码验证的机制等；
- 主要参数
  - `workgroup = 工作组名称` //主机群要相同
  - `netbios name = 主机的NetBios name` //每部主机均不相同
  - `server string = 主机的简易说明`
  - `log file = 日志文件` //文件名可能需要使用变量处理
  - `max log size = 最大日志文件kb` 
- 安全参数
  - `security = share|user|domain` //三选一
    - `share` 分享的数据不需要密码，大家均可以使用
    - `user` 使用samba服务器本身的密码数据库，密码数据库与底下的`passdb backend`有关
    - `domain` 使用外部服务器的密码，如果设定为该项，还需要配合`password server = ip`一同使用
  - `encrypt passwords = Yes` //代表密码需要加密
  - `passdb backend = 数据库格式` //为了加快速度，目前密码文件已经使用数据库。默认的数据格式喂`tdbsam` ,预设的数据库文件存放在`/var/lib/samba/private/passwd.tdb`
- 资源分享参数
  - `[分享名称]`
  - `comment` //目录说明
  - `path` //分享资源的实际目录
  - `brosweable` //是否让所有的用户看到这个目录
  - `writeable` //是否可以写入
  - `read ony` //是否为只读
    - 如果`read ony` 与`writeable`同时出现，以最后出现的设定为主要设定
  - `writelist = 用户|@群组` //指定能够进入到此资源的特定使用者，如果使用`@群组`则加入该群组的使用者均可取得使用权限
- 内置变量
  - `%S` 取代目前的设定项目值
  - ![smb.conf内置变量.png][1]

### 检查

- `testparm`使用该命令检查设置的`smb.conf` 是否存在错误
  - `-v` 参数可以查阅完整的参数设定，联通默认值也会显示
- `smbclient -L [//主机或ip] [-U 使用者账号]`
  - `-L` 仅查阅后面接的主机所提供分享的目录资源
  - `-U` 尝试使用账号来取得该主机的可用资源


  [1]: http://kim.baby-time.cn/usr/uploads/2018/09/2879971035.png
