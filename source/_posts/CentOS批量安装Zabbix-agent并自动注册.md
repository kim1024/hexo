---
title: CentOS批量安装Zabbix-agent并自动注册
date: 2019-05-06 17:33:11
categories:
 - Zabbix
tags:
  - Zabbix_Agent
  - auto_registration
randnum: zabbix_auto_registration
---

## 基本信息

使用shell脚本自动安装zabbix-agent，并启用主动模式和自动注册。自动注册主要参数是`ServerActive`和`HostMetadataItem`,主动模式的主要参数是`StartAgents`。

## 操作步骤

1. 将脚本文件和agent配置模板文件上传到服务器中，执行自动化安装
`scp install_agent.sh template.conf user@server:~/`
需要注意的是：**在agent的配置文件中，如果启用自动注册，需要设置HostMetadataItem=system.uname**
2. 使用root用户执行脚本文件
`sh ./install_agent.sh`
3. 打开Zabbix Web界面，添加自动注册动作
操作路径:*Configuration->Actions->Auto registration->create action*
![auto_register](https://s2.ax1x.com/2019/05/06/EDmHuF.png)
<!--more-->
4. 添加动作名称和操作
需要注意的是**在添加条件的时候，需要选择Host Metadata contains Linux**,监控的服务器是Linux的就填写Linux，是Windows是就选择Windows，其他的根据实际情况填写。
![add_action](https://s2.ax1x.com/2019/05/06/EDnt2V.png)
5. 添加自动注册的操作
为自动注册的主机添加相关的操作，例如添加到主机、主机组、连接到监控模板、发送消息等。
![add_operations](https://s2.ax1x.com/2019/05/06/EDnbxf.png)
6. 查看自动注册后添加的主机
路径：*Configation->Hosts*
![check_hosts](https://s2.ax1x.com/2019/05/06/EDu3LD.png)
7. 脚本文件
[install_agent.tar.gz](https://drive.google.com/file/d/1x6zNamOT6tYeQQtgXVAAeOQDHULw3frI/view?usp=sharing)
解压命令：openssl des3 -d -k passwd -salt -in install_agent.tar.gz | tar xzf -
