---
title: CentOS部署OpenStack过程-块存储服务
date: 2019-06-12 13:30:35
categories: 
 - OpenStack
tags:
  - OpenStack
  - cinder
randnum: openstack-install-cinder
---
## 安装并配置控制节点

### 安装条件

1. 数据库
```
# login
mysql -u root -p
# create database
create database cinder;
# grant privilege
grant all privileges on cinder.* to 'cid_db'@'localhost' identified by 'passwd';
grant all privileges on cinder.* to 'cid_db'@'192.168.122.%' identified by 'passwd';
```
<!--more-->
2. 获取admin凭证
`. admin-openrc`
3. 创建用户
```
# create user
openstack user create \
--domain default \
--password-prompt cinder
# create role
openstack role --project service --user cinder admin
```
4. 创建服务实体
块存储服务要求2个服务实体
```
# create cinder
openstack service create --name cinder \
--description "OpenStack Block Storge" volume
# create cinderv2
openstack service create --name cinderv2 \
--description "OpenStack Block Storge" volumev2
```
5. 创建endpoint
```
# create volume endpoint for public internal admin
openstack endpoint create region RegionOne \
volume public http://ops-cont:8776/v1/%\(tenant_id\)s
# create volumev2 endpoint like volume
openstack endpoint create region RegionOne \
volumev2 public http://ops-cont:8776/v2/%\(tenant_id\)s
```

### 安装配置组件

1. 安装组件
`yum install openstack-cinder -y`
2. 配置`cinder.conf`
```
vi /etc/cinder/cinder.conf
# configure database in [database]
connection=mysql+pymysql://cid_db:db_passwd@ops-cont/cinder
# configure [DEFAULT]
[DEFAULT]
rpc_backend=rabbit
auth_strategy=keystone
my_ip=192.168.122.200
# configure rabbit in [oslo_messaging_rabbit]
[oslo_messaging_rabbit]
rabbit_host=ops-cont
rabbit_id=openstack
rabbit_password=passwd
# configure auth in [keystone_authtoken]
[keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=cinder
password=passwd
# configure lock path in [oslo_concurrency]
[oslo_concurrency]
lock_path=/var/lib/cinder/tmp
```
3. 同步数据库
`su -c /bin/sh -c "cinder-manage db sync" cinder`
4. 配置计算节点使用块存储
**在计算节点中执行的操作**
```
vi /etc/nova/nova.conf
# add region name in [cinder]
[cinder]
os_region_name=RegionOne
```
5. 启动服务
```
# restart nova-api
systemctl restart openstack-nova-api
# start cinder service
systemctl start openstack-cinder-api openstack-cinder-scheduler
systemctl enable openstack-cinder-api openstack-cinder-scheduler
```

### 验证操作

添加存储节点后，在控制节点中执行验证操作：`cinder service-list`
![cinder-service-list](https://s2.ax1x.com/2019/06/12/VRmbX6.png)

## 添加并配置存储节点

lvm工具会扫描`/dev`目录，照抄包含卷的块存储设备，如果项目在系统卷上使用lvm，扫描工具检测到这些卷时会尝试缓存它们，这样会在底层操作系统和项目卷上产生问题。在配置lvm时，需要创建一个过滤器，只接受`/dev/sdb`设备，拒绝其他所有设备。
过滤器组中的元素都以`a`开头，即`accept`,或以`r`开头，即`reject`,并且包括一个设备名称的正则表达式规则，以`r/.*/`结束，如果操作系统使用了lvm，也必须要把操作系统相关设备添加到过滤器中。

1. 将新添加的硬盘添加到lvm中
```
# create pv
pvcreate /dev/vdb
# create lvm group
vgcreate -s 4M cinder /dev/vdb
# create filter
vi /etc/lvm/lvm.conf
# create a filter
filter=["a/vda/","a/vdb/","r/.*/"]
```
2. 安装并配置组件
```
# install
yum install centos-release-openstack-ocata -y
yum install openstack-cinder targetcli python-keystone -y
yum install mariadb python2-pymysql -y
# configure cinder.conf
vi /etc/cinder/cinder.conf
[DEFAULT]
rpc_backend=rabbit
auth_strategy=keystone
my_ip=192.168.122.90
enabled_backends=lvm
glance_api_servers=http://ops-cont:9292
[database]
connection=mysql+pymysql://cid_db:db_passwd@ops-cont/cinder
[oslo_messaging_rabbit]
rabbit_host=ops-cont
rabbit_id=openstack
rabbit_password=passwd
[keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=cinder
password=passwd
[lvm]
volume_driver=cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group=cinder
iscsi_protocol=iscsi
iscsi_helper=lioadm
[oslo_concurrency]
lock_path=/var/lib/cinder/tmp
```
3. 启动服务
```
systemctl start openstack-cinder-volume target
systemctl enable openstack-cinder-volume target
```


## 参考

1. [计算节点配置块存储服务](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/cinder-controller-install.html)
2. [添加一个块存储节点](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/cinder-storage-install.html)
