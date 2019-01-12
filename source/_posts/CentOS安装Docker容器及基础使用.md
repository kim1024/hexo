---
title: CentOS安装Docker容器及基础使用
date: 2018-10-30 14:28:15
categories: 
 - CentOS
 - Docker
tags:
  - CentOS
  - Docker
  - 容器
randnum: centos-docker-doc
---

# CentOS 安装Docker

## 使用repository安装

1. 设置repository

   1. 安装docker需要`yum-utils` `yum-config-manager` `device-persistent-data` `lvm2` 工具的帮助，所以首先要安装所需要的工具

       - `sudo yum install -y yum-utils device-mapper-persistent-data lvm2`
       - ![install tools.png][1]

   2. 启用docker stable安装源

      1. `sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo` 
      2. 如果需要启用edge和test安装源，可以分别启用如下安装源,,，默认为关闭
         - `sudo yum-config-manager --enable docker-ce-edge` or replace with `docker-ce-test`
      - ![add_repo.png][2]
<!--more-->
   3. 安装docker

      1. `sudo yum install docker-ce`
         1. 如果需要安装某个特殊版本的docker，可以使用以下命令列出系统支持的docker版本
            - `sudo yum list docker-ce --showduplicates | sort -r`
            - `sudo yum install docker-ce-<version string>` # 安装制定的版本
      - ![install-docker.png][3]

   4. 等待安装完成，完成后启用docker服务

      1. `sudo systemctl start docker`
      2. `sudo systemctl status docker -l` # 查看docker启动信息
      - ![dockerr_status.png][4]

   5. 添加国内的docker仓库镜像源

      1. `cd /etc/docker/` # 如果没有该文件，可以单独创建

      2. `sudo cp daemon.json daemon.json.old`

      3. `sudo vi daemon.json`

         1. 将以下信息加入到该文件张，注意格式是否正确，否则影响docker的启动

            ```json
            {
              "registry-mirrors": ["https://registry.docker-cn.com"]
            }
            ```


## 使用rpm包安装docker

1. 下载系统对应rpm格式的docker包
   1. 下载地址：<https://download.docker.com/linux/centos/7/x86_64/stable/Packages/>
2. 将下载的安装包上传到服务器中
   1. `scp ./docker-version-string.rpm user@centos:~/docker`
3. 登录到服务器，执行安装程序
   1. `sudo yum install ~/docker/docker-version-string.rpm`
   2. 安装程序完成后，会在系统中创建一个`docker`用户组，但是该用户组中无用户，需要将系统中的用户添加到组中
      - `sudo usermod -a -G docker user`
   3. 按照同样的步骤分别修改国内仓库镜像和重启docker服务

## 参考

1. docker官方安装指导
   1. <https://docs.docker.com/install/linux/docker-ce/centos/#uninstall-docker-ce> 

原文地址：<http://baby-time.cn/index.php/note/87.html>

  [1]: http://baby-time.cn/usr/uploads/2018/10/109795499.png
  [2]: http://baby-time.cn/usr/uploads/2018/10/2318791415.png
  [3]: http://baby-time.cn/usr/uploads/2018/10/1919531074.png
  [4]: http://baby-time.cn/usr/uploads/2018/10/2053333270.png
