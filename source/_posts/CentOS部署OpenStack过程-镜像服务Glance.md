---
title: CentOS部署OpenStack过程-镜像服务Glance
date: 2019-06-08 13:42:33
categories: 
 - OpenStack
tags:
  - OpenStack
  - glance
randnum: openstack-install-glance
---
## 基础

镜像服务glance允许用户发现、注册和获取虚拟镜像。它提供一个RESETAPI允许查询虚拟机镜像的metadata并获取一个现存的镜像。

<!--more-->
## 安装和配置

### 安装条件

1. 创建数据库
```
# login mysql
mysql -u root -p
# create database named glance
create database glance;
# grant privileges
grant all privileges on glance.* to 'glc_db'@'localhost' identified by 'passwd';
grant all privileges on glance.* to 'glc_db'@'192.168.122.%' identified by 'passwd';
```
2. 获得admin凭证获取只有管理员才能执行的命令的权限
`. admin-openrc`
3. 创建服务证书
  1. 创建glance用户
  ```
  openstack user create --domain default \
  --password-prompt glance
  ```
  2. 为用户添加admin角色
  ```
  openstack role add --project service --user glance admin
  ```
  3. 创建glance实体
  ```
  openstack service create \
  --name glance \
  --description "OpenStack Image" image
  ```
  ![OpenStack-create-service](https://s2.ax1x.com/2019/06/08/VBs5DA.png)
4. 创建镜像服务的API端点
```
# create public image api
openstack endpoint create \
--region RegionOne \
image public http://ops-cont:9292
# create internal image api
openstack endpoint create \
--region RegionOne \
image internale http://ops-cont:9292
# create admin image api
openstack endpoint create \
--region RegionOne \
image admin http://ops-cont:9292
```

### 安装配置组件

1. 安装
`yum install openstack-glance -y`
2. 配置`glance-api.conf`
```
cd /etc/glance
vi glance-api.conf
# config database in [database]
[datebase]
# add
connection = mysql_pymysql://glc_db:db_passwd@ops-cont/glance
# config auth in [keystone_authtoken] and [paste_deploy]
[keystone_authtoken]
# add
auth_url=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=glance
password=user_passwd
[paste_deploy]
# add
flavor=keystone
# config image postion in [glance_store]
[glance_store]
stores=file,http
default_store=file
filesystem_store_datadir=/var/lib/glance/images/
```
3. 配置`glance-registry.conf`
```
# configure database in [database]
[database]
# add
connection=mysql+pymysql://glc_db:db_passwd@opc-cont/glance
# configure auth in [keystone_token] and [paste-deploy]
[keystone_authtoken]
# add
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=glance
password=user_passwd
[paste_deploy]
flavor=keystone
```
4. 写入镜像服务数据库
`/bin/sh -c "glance-manage db_sync" glance`
5. 启动服务
```
systemctl start openstack-glance-api openstack-glance-registry
systemctl enable openstack-glance-api openstack-glance-registry
```
## 验证服务

1. 获得admin凭证
`. admin-openrc`
2. 下载cirros镜像
`wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img cirros040.img`
将下载的镜像移动到`/var/lib/glance/images`
3. 使用qcow2格式，bare容器格式上传镜像到镜像服务并设置公共可见
```
openstack image create "cirros" \
--file cirros040.img \
--disk-format qcow2 \
--container-format bare \
--public
```
![OpenStack-create-image](https://s2.ax1x.com/2019/06/10/VyROr6.png)
4. 查看镜像属性
`openstack image list`

## 参考

1.[OpenStack安装和配置镜像服务](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/glance-install.html)
