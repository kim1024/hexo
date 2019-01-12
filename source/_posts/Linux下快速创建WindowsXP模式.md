---
title: Linux下快速创建WindowsXP模式
date: 2018-10-30 11:34:35
categories: 
 - Linux
tags:
  - Linux
  - WindowsXP
randnum: linux-windowsxp
---
 [![i2WkKx.png](https://s1.ax1x.com/2018/10/30/i2WkKx.png)](https://imgchr.com/i/i2WkKx)

# 在Virtualbox快速安装Windows XP

- Windows XP是微软经典操作系统，目前虽然微软已经停止支持，但是其市场占有量依然很高。有时候我们需要在XP系统中进行测试，那么有什么简单的方法可以搭建Windows XP环境呢？
<!--more-->

## 方法一：Virtuabox+Windows XP iso
- 使用Virtuabox创建一个Windows XP的虚拟机，该方法耗费的时间比较长，安装起来无异于安装一台新电脑。

## 方法二：Windows 7+ XP mode
- 微软已经很贴心的帮我们想好了，在Windows 7中有一种XP模式，启用该模式后可以在系统中搭建出XP环境。

## 方法三：Linux+Virtualbox+XP Mode
- 在Linux系统下，我们也可以很简单的使用XP模式。首先通过地址<https://www.microsoft.com/zh-CN/download/details.aspx?id=8002> 下载XP Mode；
   ![i2WCG9.png](https://s1.ax1x.com/2018/10/30/i2WCG9.png)  
- 下载的文件后缀格式为`exe`,在linux系统中是无法直接运行的，我们使用7zip软件解压2次；
  - `7za x xpmode.exe` //第一次解压，解压后，在文件夹`source`中有一个`xpm`文件
  - `cd ./source && 7za x xpm` //第二次解压，对`xpm`文件解压，解压后会出现一个`VirtualXPVHD`文件
    ![i2Wix1.png](https://s1.ax1x.com/2018/10/30/i2Wix1.png) 

- 打开`Virtualbox`,新建一个虚拟机，创建虚拟磁盘时，选择已经存在的磁盘，选中文件`VirtualXPVHD` ;
    ![i2WP2R.png](https://s1.ax1x.com/2018/10/30/i2WP2R.png)
    
- 创建完成后，打开XP虚拟机，然后安装`Virtualbox`扩展功能，重启后进入系统，此时XP模式已经全部完成，可以随意在系统中测试。

- 注意事项：在第一次启动xp虚拟机后，鼠标不能使用，此时需要使用`Tab+↑+↓`安装替代鼠标完成扩展功能的安装，** 完成安装后不要重启系统否则会出现黑屏**，选择强制关机，再次进入系统后各项功能正常使用。


