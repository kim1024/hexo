---
title: KVM虚拟机常用命令 
date: 2018-10-30 14:23:22
categories: 
 - KVM
tags:
  - KVM
  - 虚拟化
randnum: kvm-cmd
---

# KVM 维护常用命令

- kvm虚拟机的配置文件位置：`/etc/libvirt/qemu`
- 修改虚拟机的相关配置
  - `sudo virsh edit virt_host_name`
- 备份虚拟机的配置文件
  - `sudo virsh dumpxml virt_host_name > backup _path/virt_host_name_backup.xml`
- 查看正在运行的虚拟机
  - `sudo virsh list [-all]`
- 启动虚拟机
  - `sudo virsh start virt_host`
- 关闭、重启虚拟机
  - 如果使用`virsh`关闭或重启虚拟机，需要在虚拟机中安装`acpi` `scpid-sysvinit` 2个软件包,并启动相关的服务
  - `sudo virsh shutdown|reboot virt_host`
<!--more-->
- 强制关机与挂机、恢复
  - `sudo virsh destroy|suspend|resume virt_host`
- 移除虚拟机，该方法只删除虚拟机的配置文件，磁盘文件保留
  - `sudo virsh undefine virt_host`
  - `sudo virsh define virt_host_new.xml` #导入虚拟机
- 彻底删除虚拟机
  - `sudo virsh destroy virt_host` #强制关闭
  - `sudo virsh undefine virt_host` #解除标记虚拟机
  - 删除虚拟机的磁盘文件
- 开机启动虚拟机
  - `sudo virsh autostart virt_host`
  - `sudo virsh autostart --disable virt_host` #取消开机启动
- 克隆虚拟机
  - `sudo virt-clone -o virt_host -n new_host -f /disk path/new.qcow2 `
- 虚拟机快照
  - 创建虚拟机快照，要求虚拟机的磁盘格式为qcow2，如果不是，需要使用`qemu-img` 进行转换
    - `sudo qemu-img info virt_host` #查看虚拟机磁盘格式
    - `sudo qemu-img convert -f raw disk.raw -o qcow2 convert_new.qcow2`
    - `sudo qemu-img create -f qcow2 /disk_path/name.qcow2 size` #新建一个虚拟机镜像磁盘
    - `sudo virsh attach-disk virt_host_name /disk_path/name.qcow2 vdb --cache=none --subdriver=qcow2` #在线追加虚拟机镜像磁盘
  - 创建快照
    - `sudo virsh snapshot-create virt_host` #创建的快照名称为默认格式
    - `sudo virsh snapshot-create-as --domain kvm_host --name "snapshot_name"`
  - 查看快照
    - `sudo snapshot-list virt_host`
  - 恢复快照
    - `sudo snapshot-revert virt_host snapshot_name`
  - 删除快照
    - `sudo virsh snapshot-delete virt_host snapshot_name`

