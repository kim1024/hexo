---
title: iOS平刷工具-Semi-Restore
date: 2018-10-30 12:38:33
categories: 
 - iOS
tags:
  - iOS
randnum: ios-semi-restore
---

# IOS 平刷工具Semi-Restore

- 工具
  - Semi-Restore
    - 下载地址：<https://semi-restore.com>
    - 支持的操作系统有**Windows OSX Linux** ,系统要求必须为64位
     - ![semirestore.png][1]
- 支持的IOS版本
  - IOS 5.0-9.1
- Tips
  - 该平刷工具用于越狱后的设备，即可以保留设备原有的系统版本，同时删除设备的所有数据，恢复到出厂设置；
  - 未越狱的设备，可以直接使用设备自带的`擦除全部数据`来重置设备；
  - 越狱后的设备，不可以使用`擦除全部数据`来重置设备，使用该项操作后，重启会出现白苹果的现象。

## 平刷步骤

1. 本操作以Windows 7为例，首先需要在系统中安装`.NET Freamwork 4.0+`和`Visual C++ Redistributable for Visual Studio 2015` 和`Itunes12+` 
   - .NET下载地址
     - <https://www.microsoft.com/en-us/download/details.aspx?id=53344>
   - Visual运行库下载地址
     - <https://www.microsoft.com/en-us/download/confirmation.aspx?id=48145>
2. 将下载的`Semi-Restore` 工具解压到文件夹中；
   - ![soft-list.png][2]
3. 将设备通过数据线与电脑连接，连接成功后需要关闭`ITunes`，同时需要关闭设备的锁屏密码；
4. 打开解压后的文件夹，找到文件`SemiRestore9`，右键以管理员身份运行，打开平刷工具；
5. 系统中所有必须工具全部安装正确，并且设备已经连接到电脑，打开平刷工具后，会出现设备的相关信息；
   - ![wait.png][3]
6. 点击右侧`SemiRestore`按钮开始平刷，在平刷过程中，设备会出现多次重启的现象，在平刷过程中**切勿操作设备** ；
7. 平刷完成后，会出现`SemiRestore Complete` 的提示，至此，平刷完成；
   - ![complete.png][4]
8. 打开设备，进行相关的初始设置。


  [1]: http://baby-time.cn/usr/uploads/2018/10/113529270.png
  [2]: http://baby-time.cn/usr/uploads/2018/10/3740232122.png
  [3]: http://baby-time.cn/usr/uploads/2018/10/609638867.png
  [4]: http://baby-time.cn/usr/uploads/2018/10/2508623511.png
