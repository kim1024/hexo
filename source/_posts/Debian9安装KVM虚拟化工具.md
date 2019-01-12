---
title: Debian9安装KVM虚拟化工具
date: 2018-10-30 14:21:13
categories: 
 - KVM
tags:
  - Debian
  - KVM
  - 虚拟化
randnum: debian-kvm
---

# Debian9 安装KVM

## 系统信息

  - `sudo lsb_release -a`

    ```bash
    Distributor ID:	Debian
    Description:	Debian GNU/Linux 9.5 (stretch)
    Release:	9.5
    Codename:	stretch
    ```

  - 查看CPU是否支持虚拟化

    - `cat /proc/cpuinfo`
    - vmx //Inter
    - svm //AMD
<!--more-->
## 安装QEMU、KVM

  - `sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system  bridge-utils libguestfs-tools  virtinst libosinfo-bin`

- 将当前用户添加到`libvirt libvirt-qume`组中

  - `sudo usermod -a -G libvirt user`
  - `sudo usermod -a -G libvirt-qume`

- 创建桥接网络

  ```bash
  cd /etc/network/interfaces.d
  sudo touch br0 && sudo vi bro
  //[insert]
  auto br0
  iface br0 inet static
  address 192.168.0.101
  netmask 255.255.255.0
  gateway 192.168.0.1
  bridge_ports enp0s31f6
  bridge_stp off
  bridge_waitport 0
  bridge_fd 0
  ```

- 重启网络

  - `sudo systemctl restart network-manager`
  - `sudo systemctl restart networking`

- 查看kvm网络

  - `sudo virsh net-list --all`
  ![virt net-list](https://s1.ax1x.com/2018/11/13/iOaysH.png)

- 查看本机桥接网络
  - `sudo brctl show`
  ![show bridge net](https://s1.ax1x.com/2018/11/13/iOaeqs.png)
  - 在kvm中找不到br0网卡，但是在kvm虚拟机中可以连通到网络
  ![cento1 ping](https://s1.ax1x.com/2018/11/13/iOdFT1.png)

- 查看网络配置

  - `ip addr`
  - 如果查看不到创建的桥接网络，需要`reboot`

- 添加kvm桥接网卡<sup>2</sup>

  - 新建一个xml文件`sudo touch /var/kvm/bridge,xml`
  - 将网卡定义写进xml文件中`sudo vi /var/kvm/bridge.xml`
    ```
	<network>
	  <name>br1</name>
	  <forward mode="bridge" />
	  <bridge name="br1" />
	</network>
    ```
  - 在kvm中定义网卡`sudo virsh net-define --file /var/kvm/bridge.xml`
  - 设置自启动并启用该网卡`sudo virsh net-autostart br1 && sudo virsh net-start br1`

- 创建虚拟机

  ```
  cd ~ && mkdir kvmiso #用于存放iso镜像
  mkdir kvmimg #用户存放安装后的img镜像
  sudo virt-install \
  --virt-type kvm \
  --name Debian-kvm \
  --memory 1024 \ #单位为M
  --vcpus 1 \
  --os-variant debian9 \
  --hvm \ #请求全虚拟化
  --cdrom /home/user/kvmiso/debian9.iso \
  --network bridge=br0,model=virtio \  \#直接桥接到宿主机的br0网卡上
  --graphics vnc \
  --disk path=/home/user/kvmimg/debian-kvm.qcow2,size=30,bus=virtio,format=qcow2 \ #常用格式有raw\qcow2\vmdk
  ```
   - 特别注意事项：**在创建镜像磁盘时，如果虚拟机是Linux，磁盘bus可以使用virtio，如果是Windows则会出现找不到磁盘的问题，可以将bus修改为ide**

## 创建完成，开启虚拟机
  - `sudo virt-viewer centos1`
  - 如果需要使用vnc，需要在宿主中安装`vnc viewer`,通过`virsh dumpxml centos1 | grep vnc` 命令查看vnc的端口号，然后使用vnc viewer连接到图形虚拟机

## 参考
  1. <https://wiki.debian.org/KVM> 
  2. <https://www.cyberciti.biz/faq/install-kvm-server-debian-linux-9-headless-server/>

