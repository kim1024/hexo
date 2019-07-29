---
title: Hadoop基础学习
date: 2019-07-29 10:02:54
categories: 
 - Hadoop
tags:
  - Hadoop
  - 基础知识
randnum: hadoop_learning
---

## HDFS

HDFS的设计本质是为了大量的数据横跨成百上千台机器，用户看到的是一个文件系统，而不是很多的文件系统。
例如我们引用一个路径中的数据/home/user/hdfs/file,我们引用的是一个路径，但是实际的数据存放在很多不同的机器上。HDFS就用来管理存储在不同机器上的数据。

## 计算引擎

- Mareduce是第一代计算引擎，采用了很简化的计算模型，只有Map和Reduce两个计算过程(中间用Shuffle串联)。例如我们要统计在HDFS中存放的一个很大的文本文件中各个词出现的频率，我们首先会启动一个MapReduce程序，Map阶段会有很多机器读取文件的各个部分，分别把各自读到部分统计出词频;Reduce阶段同样会有很多机器从Mapper机器收到按照Hash分类的词的统计结果，Reducer会汇总相同词的词频，最终会得到整个文件的词频结果。MapReduce的模型比较简单，但是比较笨重。
- 第二代计算引擎Tez/Spark除了有内存、cache之类的新特性，还让Map和Reduce之间的界限模糊，数据交换更加灵活，更少的磁盘读写，更高的吞吐量。
- Pig用接近脚本的方式描述MapReduce，Hive用SQL描述MapReduce，他们用脚本的SQL语言翻印MapReduce程序，然后让计算引擎去计算。
- Hive是Hadoop的数据仓，严格来说不算是数据库，主要用于解决数据处理和计算问题，使用SQL来计算和处理HDFS上的结构化数据，适用于离线的批量数据计算。
- Hbase是面向列的NoSQL数据库，用于快速读/写大量的数据，主要解决实时数据查询问题，应用场景多是海量数据的随机实时查询。
- Storm是最流行的流计算平台，它的计算思路是：在数据流进来的是后就开始统计，好处是无延迟，但是短处是不灵活，要预先知道要统计的东西，毕竟数据流流过后就没有了。

<!--more-->
## 调度系统

![Yarn](https://s2.ax1x.com/2019/07/28/elWPDf.gif)

### 基础知识

- yarn是目前较为流行的调度系统，负责资源调度、作业管理。在Yarn中有2种节点，一种是Resource Manager(master),另一种是Node Manager(slave).
  - Resource Manager是Master上一个独立运行的进程，负责集群统一的资源管理、调度、分配等
    - Scheduler根据各个应用程序的资源需求进行资源分配，资源分配用一个抽象概念Container表示，它是一个动态资源分配单位，将内存、CPU、磁盘、网络等资源封装在一起，从而限定每个任务使用的资源量。
    - Applications Manager负责整个系统中所有的应用程序
    - Resource Tracker负责响应Node Manager的调度，例如节点的增加和删除
  - Node Manager是Slave上一个独立运行的进程，负责上报节点的状态
    - Node Manager是TaskTracker的一种更加普通和高效的版本，它拥有许多动态创建的资源容器。容器的大小取决于它包含的资源量。节点中容器的数量由配置参数与专用于从属后台进程和操作系统资源意外的资源总量共同决定。
  - Application Master运行在Slave上的组件
    - 在用户提交一个应用程序时，Application Master进程实例会启动来协调应用程序内的所有任务的执行，包括监视、重启失败的任务、推测性运行缓慢的任务，以及计算应用程序计数器值的总和。它和它的应用程序均在受Node Manager控制的资源容器中运行。
- Client向Resource Manager提交的每一个应用程序都必须有一个Application Master，它经过Resource Manager分配资源后，运行于某个Slave节点的Container中，具体做事情的Task也同样运行在某个Slave节点的Container中。RM、AM、NM、Container之间的通信，都是使用RPC机制。

### Yarn资源管理和配置参数

#### 内存参数

- Yarn允许用户配置每个节点上Yarn可用的物理内存，使用参数`yarn.nodemanager.resource.memory-mb`,默认大小是8192M
- `yarn.nodemanager.vmem-pmem-ratio`任务使用1M物理内存最多可使用虚拟内存，默认是2.1
- `yarn.nodemanager.peme-check-enabled`是否启用一个线程检查每个任务正使用的物理内存量，如果超出任务分配值，直接kill，默认为true
- `yarn.nodemanager.vmem-check-enabled`是否启用一个线程检查每个任务使用的虚拟内存量，默认true
- `yarn.scheduler.minimum-allocation-mb`单个任务可以使用的最小物理内存量，默认1024M
- `yarn.scheduler.maximum-allocation-mb`单个任务可以使用的最大物理内存量，默认8192M

#### CPU参数

- `yarn.nodemanager.resource.cpu-vcores`yarn在该节点上可使用的虚拟cpu个数，默认是8,推荐该值与物理cpu核数相同，不足8个，需要调小该值
- `yarn.schedulaer.minimum-allocation-vcores`/`yarn.scheduler.maximumallocation-vcores`单个任务可申请的最小/最多cpu,最小为1,不足1的，默认使用1,最大默认是32

