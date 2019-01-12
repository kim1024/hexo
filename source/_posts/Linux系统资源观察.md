---
title: Linux系统资源观察
date: 2018-12-03 16:39:05
categories: 
  - 学习笔记
tags:
  - Linux
  - 命令
  - 学习笔记
randnum: linux-sys-cmd
---

## 内存观察

-  使用命令`free`可以观察内存的使用情况，命令格式如下：
  - `free [-bmgh] [-t] [-sNc]`
    - b 直接输入free命令时，显示的单位是K，可以使用的单位有b(bit),m(M),k(KB),g(G),除此之外还可以使用-h让系统自动指定单位
    - t 在输出最终结果的时候，显示实体内存与swap总量
    - s 可以让系统以每几秒输出一次，不间断输出
    - c 通常与参数s一起使用，表示连续输出多少次
    
![free](https://s1.ax1x.com/2018/12/03/FMkRAO.png)

<!--more-->
    
 ## 网络观察
 
 - 使用命令`netstat`可以观察系统和程序的网络信息，命令格式如下：
  - `netstat -[atunlp]`
    - a 使用inactive/active取代buffer/cache
    - t 列出tcp数据
    - u 列出udp命令
    - n 列出程序的段口号
    - l 列出目前正在 监听的服务
    - p 列出网络程序的pid

![netstat](https://s1.ax1x.com/2018/12/03/FMkWND.png)
   
 ## 开机信息的观察
 
 - 使用dmesg命令可以查看，系统开机时的信息，例如查看开机时cpu信息：
  -  `dmesg | grep cpu`
  
 ### 系统资源观察
 
 - 使用命令`vmstat`可以观察系统资源的运行情况，命令格式如下：
  - `vmstat [-a] [延迟 [总计侦次数]]` \# cpu/内存信息
    - 使用inactive/active活跃与否取代baffer/cache的内存输出信息 
  - `vmstat -fs` \# 内存相关
    - f 开机到现在,系统复制fork的程序数
    - s 开机后的哦呵之内存变化的情况列表
    - S 指定显示数据的单位，支持k/K m/M
  - `vmstat -d` \# 磁盘信息
  -  `vmstat -p` \# 分区信息
  - `vmstat -a 1 3` \# 每秒输出1次，共输出3次
  
 ![vmstat](https://s1.ax1x.com/2018/12/03/FMkojI.png)
  
 - 字段
   - procs 程序字段： r表示等待运行中的程序数量；b表示不可被唤醒的程序数量。这2个项目越多，代表系统越繁忙
   - memory 内存字段： swpd虚拟内存被使用的容量；free未被使用的内存容量；buffer用于缓冲内存；cache用于高速缓存内存
   - swap内存交换：si由磁盘中将程序取出的量；so由于内存不足而将没用到的程序写入到磁盘的swap的容量。如果si/so数值太大，表示内存的数据常常得在磁盘与内存之间传递，性能会变差
   - system系统项目：in每秒被中断的程序次数;cs每秒进行的事件切换次数；in/cs数值大，达标系统与周边设备的沟通非常频繁，周边设备包括磁盘、网卡、时间钟等
   - CPU项目：us非核心层的cpu使用状态；sy和下层使用的cpu状态；id闲置的状态；wa等待IO所耗费的cpu状态;st被虚拟机盗用的cpu
