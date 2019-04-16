---
title: 使用KVM创建Windows虚拟环境
date: 2019-01-12 11:38:54
categories:
  - KVM
tags:
  - KVM
  - Windows
randnum: kvm-windows
---
-  经过测试，使用kvm创建的Windows环境，在使用体验和性能上不如Virtualbox，如非特殊需求，可以在Virtualbox中虚拟Windows环境。

<!--more-->
## 创建kvm

- 通过命令行模式创建基于kvm的全虚拟化Windows XP环境:
```
virt-install \
	--name winxp \
	--virt-type kvm \
	--hvm \
	--os-variant winxp \
	--memory 2048 \
	--vcpus 2 \
	--graphics vnc \
	--network bridge=br0,model=virtio \
	--cdrom /home/user/ios/winxp.iso \
	--disk path=/home/user/kvm/disk/winxp25G.qcow2,size=25,bus=ide
```
- 在创建虚拟环境时，有以下几点需要注意：
 1. 关于全虚拟化，可以根据需要选择性开启，如果开启，添加`--hvm`,如果不开启，则将`--hvm`移除；
 2. 设置网络时，注意添加网络模式`virtio`;
 3. 在添加磁盘时，格式选择为qcow2,同时要指定bus模式为ide，如果指定为virtio模式，启动虚拟环境时，会出现蓝屏；
 4. 安装完成后，需要安装Windows的网络驱动:
   1. 首先需要下载virtio iso格式的驱动 ，驱动的下载地址<https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/>;
   2. 将下载的iso格式的驱动文件挂载到虚拟机中`virsh edit winxp`编辑虚拟机的文件，找到`cdrom`选项，将驱动的iso文件路径替换掉原来的，在进行编辑之前，首先要将原来的xml文件备份`virsh dumpxml winxp > /home/user/kvm/winxp.xml`;
   ![edit_cdrom](https://s2.ax1x.com/2019/01/11/FXZIZq.png)
   3. 启动虚拟机，安装网卡驱动，测试网络；
   ![install_netkvm](https://s2.ax1x.com/2019/01/11/FXZod0.png)
