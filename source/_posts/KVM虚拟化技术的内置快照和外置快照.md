---
title: KVM虚拟化技术的内置快照和外置快照
date: 2019-07-17 14:18:01
categories: 
 - kvm
tags:
  - 虚拟化
  - kvm
  - 内外快照
randnum: kvm-snapshot
---

## 磁盘快照

- 内置磁盘快照

内部磁盘快照使用单个qcow2文件来保存快照和快照之后的改动。这种快照是libvirt默认支持的方式，其缺点是只支持qcow2格式的磁盘镜像，而且过程较慢。

- 内置系统还原点

使用`virsh save/restore`命令，可以在虚拟机开机状态下保存内存状态、设备状态、磁盘装套到指定文件中，还原的是后虚拟机关机，使用`virsh restore`还原。(类似于休眠)

- 外置磁盘快照

外置磁盘快照创建的快照是一个只读文件,成为1个backing-file，快照后改动的内容存放到另一个qcow2文件,成为1个overlay，外置快照可以支持各种格式的磁盘镜像文件，外置快照的结果是形成一个qcow2文件链。快照状态为disk-snapshot的为外置快照。

- 外置系统还原点

虚拟机的磁盘磁盘状态被保存到一个文件中，内存和设备状态被保存到另一个文件中。

<!--more-->
## 快照操作

### 内置快照

#### 创建快照

```
# 创建虚拟机内置快照
virsh snapshot-create-as --domain test --name fresh
# 查看快照
virsh snapshot-list test
# 还原快照
virsh destroy test
virsh snapshot-revert --domain test fresh
# 删除快照
virsh snapshot-delete --domain test fresh
# 创建内置系统还原点
virsh save test /path/test.xml
# 还原
virsh restore /path/test.xml
```

### 外置快照

#### 创建快照

```
# 查看虚拟机当前使用的磁盘文件
virsh domblklist test
# 创建外置快照
virsh snapshot-create-as --domain test --name fresh --disk-only --diskspec vda,snapshot=external,file=/path/test_fresh.qcow2 --atomic
# 查看当前虚拟机使用的磁盘文件按
virsh domblklist test
# 查看虚拟机的backing-file
qemu-img info test_fresh.qcow2
# 查看快照链
qemu-img info --backing-chain test_fresh.qcow2
```
**注意：如果虚拟机存在多硬盘，在创建外置快照时，为保证原子性，需要添加参数atomic**

#### 合并快照

虚拟机的快照链：
```
centos.qcow2(base-image)--test2.qcow2(磁盘镜像)-->test2(虚拟机实例)
-->test2_test(快照1)-->test2_nmap(快照2)-->test2_net-tools(快照3)-->test2_lsof(快照4)
```
外置快照可以用合并的方式缩短快照链，而不能通过删除的方式，因为每个快照中都保存相应的数据。合并快照的方式有2种：blockcommit向下合并和blockpull向上合并。

- blockcommit

blockcommit将top镜像合并至低层的base镜像，一旦合并完成，处在最上面的overlay将自动被指向低层的overlay或base，即合并overlay到backing-file。
```
# 合并快照2-3到快照1
virsh blockcommit --domain test2 --base /path/test2_test.qcow2 --top /path/test2_net-tools.qcow2 --wait --verbose
```
![blockcommit](https://s2.ax1x.com/2019/07/17/ZL9UMt.png)
![pullcommit-snapshot-seq](https://s2.ax1x.com/2019/07/17/ZL9VPJ.png)

- blockpull
blockpull将backing-file向上合并至active。
虚拟机快照链：
centos.qcow2(base-image)--test2.qcow2(磁盘镜像)-->test2(虚拟机实例)
-->test2_test(快照1)-->test2_lsof(快照2)-->test2_vim(快照3)-->test2_htop(快照4)

```
# 合并快照1-3到当前使用的快照4中
virsh blockpull --domain test2 --path /path/test2_htop.qcow2 --base /path/test2.qcow2 --wait --verbose
# 迁移虚拟机，合并base-image到active,合并需要一段时间
virsh blockpull --domain test2 --path /path/test2_htop.qcow2 --wait --verbose
# 清理其他快照
virsh snapshot-delete --domain test2 vim --metadata
```
![blockpull-move](https://s2.ax1x.com/2019/07/17/ZLp7KP.png)
![blockpull-snapshot-seq](https://s2.ax1x.com/2019/07/17/ZL9lVO.png)
![blockpull-move.png](https://s2.ax1x.com/2019/07/17/ZL9Rs0.png)

## Tips

在创建外置快照时出现`Operation not supported: live disk snapshot not supported with this QEMU binary`的错误提示，需要执行以下操作：
```
yum remove qemu-kvm -y
yum install centos-release-qemu-ev -y
yum install qemu-kvm-ev -y
```
KVM的快照之间存在链式关系，快照链中在未执行合并前，不能删除快照链中的任意一个快照。
