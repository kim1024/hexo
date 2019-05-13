---
title: KVM-QEMU创建支持UEFI启动的虚拟主机
date: 2019-05-08 09:59:07
categories:
 - kvm
tags:
  - kvm
  - uefi
randnum: kvm_uefi
---

## 基本信息

在KVM/QEMU中支持UEFI启动的是OVMF(Open Virtual Machine Firmware),它从EDK2演变而来。

## 操作步骤

1. 从Fedora repo安装UEFI
需要安装的软件是`edk2-ovmf`,如果系统中已经安装了Qemu，并且在系统中有`OVMF_CODE.secboot.fd`文件，系统中就已经安装完成该软件了。
![OVMF](https://s2.ax1x.com/2019/05/08/EyIfl8.png)
如果没有，则执行以下命令完成安装：
<!--more-->
```
sudo dnf install dnf-plugins-core
sudo dnf config-manager --add-repo https://www.kraxel.org/repos/firmware.repo
sudo dnf install edk2.git-ovmf-x64
```
2. 配置libvirtd支持UEFI
在Fedora22版本以后，libvirtd已经配置好对UEFI的支持，如果需要修改可以通过修改文件*/etc/libvirt/qemu.conf*中**nvram**选项。
3. 创建虚拟机
通过命令行创建虚拟机时，操作步骤与其他无二，只需要额外添加一条`--boot uefi`
![create_VM_uefi](https://s2.ax1x.com/2019/05/08/EyI4Og.png)
4. 创建UEFI分区
在安装虚拟机系统时，为UEFI指定单独分区并挂载到*/boot/efi*
5. 注意
在启用了uefi启动模式，在为虚拟机创建snapshot的时候会出错，目前该问题尚未解决：  
*error: Operation not supported: internal snapshots of a VM with pflash based firmware are not supported*  
因此，在启用uefi和使用snapshot功能之间要自行权衡后选择使用。

## 参考

1. [Using UEFI with QEMU](https://fedoraproject.org/wiki/Using_UEFI_with_QEMU)
