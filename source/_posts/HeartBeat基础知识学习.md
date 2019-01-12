---
title: HeartBeat基础知识学习
date: 2018-11-04 16:00:31
categories: 
 - HA
tags:
  - HeartBeat
  - 学习笔记
randnum: heartbeat-doc
---

# HeartBeat 软件基础知识学习笔记

- HeartBeat是Linux-HA项目中的一个组件，集成了HA软件中多需要的基本功能：心跳检测、资源监管、检测群集系统服务、集群节点转移。

- 心跳检测可以通过网络链路和串口进行，而且支持冗余链路。几点之间相互通过发送报文来告诉对方自己当前的状态，如果在指定的时间内没有收到对方发送的报文，那么就认定对方失效，这时启动资源接管模块来接管运行在对方节点上的资源或服务。

- HeartBeat主要由以下部分组成：

  ![HeartBeat组成部分](https://s1.ax1x.com/2018/11/04/i5f0je.png) 

  <!--more-->

  - HeartBeat节点间通信检测模块
    - 检测主次节点的运行状态，以决定节点是否失效
  - Ha-Logd 集群事件日志服务
    - 用于记录集群中所有模块和服务的运行信息
  - CCM 集群成员一致性管理模块
    - 用于管理集群节点，同时管理成员之间的关系和节点间资源的分配
  - CRM 集群资源管理模块
    - 处理节点和资源之间的依赖关系，管理节点对资源的使用，一般由CRM守护进程crmd、Cluster Policy Engine、Cluster Transition Engine组成
  - LRM 本地资源管理模块
    - 负责本地资源的启动、停止、监控，一般由LRM守护进程lrmd和节点监控进程Stonith Daemon组成，lrmd负责节点间的通讯，Stonith Daemon通常时一个Fence设备，用于监控节点状态，当节点出现问题时处于正常状态的节点会通过Fence设备将其关机或重启以释放IP、磁盘等资源，保证资源被一个节点拥有，防止资源争用
  - Stonith Daemon 使出现问题的节点从集群环境中脱离
  - Cluster Policy Engine 集群策略引擎
    - 具体实施节点资源间的管理和依赖
  - Cluster Transition Engine 集群转移引擎
    - 当节点出现故障时，负责协调另一个节点上的进程进行合理的资源接管

- HeartBeat为了监视它控制的资源或应用程序是否正常运行，需要通过第三方插件来扩展功能。HeartBeat自带了`ipfail,Stonith,Ldirector`插件。

  - `ipfail`: 用于检测网络故障并做出合理反应，使用ping节点或ping接电阻来检测网络是否出现故障；
  - `Stonith`: 在失效的节点恢复后，合理接管集群服务资源，放置数据冲突；节点失效后，会从集群中删除该节点，保证共享存储环境中的数据完整性。如果不使用`Stonith`，那么失效的节点不被删除，就导致服务在多于1个节点中运行，会造成数据冲突；
  - `Ldirector`: 监控集群服务节点运行状态，Ldirector如果检测到集群中节点出现故障，会屏蔽此节点的对外连接功能，同时将后续请求转移到正常的节点中，继续提供服务；
