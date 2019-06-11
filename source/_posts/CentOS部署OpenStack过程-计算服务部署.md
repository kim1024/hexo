---
title: CentOS部署OpenStack过程-计算服务部署
date: 2019-06-11 10:06:30
categories: 
 - OpenStack
tags:
  - OpenStack
  - nova
  - compute
randnum: openstack-install-nova-compute
---
## 基本信息

OpenStack计算组件请求OpenStack Identiy服务进行认证;请求OpenStack Image服务提供磁盘镜像;为OpenStack dashboard提供用户管理域管理员接口。
OpenStack计算服务主要的组件：
  - nova-api服务
    - 接受和响应来自最终用户的计算API请求
  - nova-api-metadata服务
    - 接受来自虚拟机发送的元数据请求，一般在安装nova-network服务的多主机模式下使用
  - nova-compute服务
    - 一个持续工作的守护进程，通过Hypervior来创建和销毁虚拟机实例
  - nova-scheduler服务
    - 拿到一个来自队列请求虚拟机实例，然后决定哪台计算服务器主机来运行
  - nova-conductor模块
    - 媒介作用于nova-compute服务域数据库之间
  - nova-cert模块
    - 服务器守护进程向Nova Cert服务提供X509证书
  - nova-network worker守护进程
    - 与nova-compute类似，从队列中接受网络任务，并且操作网络。执行任务例如创建网桥接的接口或改变iptables规则
  - nova-consoleauth守护进程
    - 授权控制台代理所提供的用户令牌
  - nova-novncproxy守护进程
    - 提供一个代理，用于访问正在运行的实例，通过VNC协议，支持基于浏览器的novnc客户端
  - nova-spicehtml5proxy
    - 提供一个代理，用于访问正在运行的实例，通过SPICE协议，支持基于浏览器的html5客户端
  - nova-xvpvncproxy
    - 提供一个代理，用于访问正在运行的实例，通过VNC协议，支持OpenStack特定的java客户端
  - nova-cert守护进程
    - X509证书
  - nova client
    - 用于用户作为租户管理员或最终用户来提交命令
  - 队列
    - 一个在守护进程之间传递消息的中央集线器
  - SQL数据库
    - 存储构建时和运行时的状态，为云基础设施
    
<!--more-->
## 安装配置

### 控制节点执行操作

#### 安装条件

1. 创建数据库
```
# login mysql
mysql -u root -p
# create datbase
create database nova_api;
create database nova;
# grant privileges
grant all privileges on nova.* to 'nva_db'@'localhost' identified by 'passwd';
grant all privileges on nova.* to 'nva_db'@'192.168.122.%' identified by 'passwd';
grant all privileges on nova_api.* to 'nva_db'@'localhost' identified by 'passwd';
grant all privileges on nova_api.* to 'nva_db'@'192.168.122.%' identified by 'passwd';
```
2. 获取admin凭证
`. admin-openrc`
3. 创建服务证书
```
# 创建服务用户
openstack user create \
--domain default \
--password-prompt nova
# 添加角色
openstack role add --project serice --user nova admin
# 创建服务实体
openstack service create --name nova \
--description "OpenStack Compute" compute
```
7. 创建计算服务API端点
```
# create public endpoint
openstack endpoint create --region RegionOne \
compute public http://ops-comp:8774/v2.1/%\(tenant_id\)s
# create internal endpoint
# create admin endpoint
# create firewall rule
```
#### 安装placement<sup>3</sup><sup>4</sup>

1. 创建数据库
```
# login mysql
mysql -u root -p
# create database
create database placement;
# grant privilege
grant all privileges on placement.* to 'plc_db'@'localhost' identified by 'passwd';
grant all privileges on placement.* to 'plc_db'@'192.168.122.%' identified by 'passwd';
```
2. 创建用户
```
# create
openstack user create --domain default \
--password-prompt placement
# add role to user
openstack role add --project service --user placement admin
```
3. 创建服务实体
```
openstack service create \
--name placement \
--description "OpenStack Plancement" placement
```
3. 添加endpoint
```
# add public endpoint
openstack endpoint create \
--region RegionOne \
placement public http://ops-cont:8778
# add internal admin endpoint like public
```
4. 安装placement
`yum install openstack-nova-placement-api -y`


#### 安装nova

1. 安装
```
yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler -y
```
2. 配置`nova.conf`
```
i /etc/nova/nova.conf
# enable compute and metadata in [DEFAULT]
enabled_apis=osapi_compute,metadata
# configure database in [api_database] and [database]
[api_database]
connection=mysql+pymysql://nva_db:db_passwd@ops-cont/nova_api
[database]
connection=mysql+pymysql://nva_db:db_passwd@ops-cont/nova
# configure Rabbitmq in [DEFAULT] and [oslo_messageing_rabbit]
[DEFAULT]
rpc_backend=rabbit
[oslo_messageing_rabbit]
rabbit_host=ops-cont
rabbit_userid=openstack
rabbit_password=passwd
# configure auth in [DEFAULT] and [keystone_authtoken]
[DEFAULT]
auth_strategy=keystone
[keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=nova
password=passwd
# configure manager interface in [DEFAULT]
[DEFAULT]
my_ip=192.168.122.100
# enable neutrion and use nova firewall rule in [DEFAULT]
[DEFULT]
use_neutron=True
firewall_driver=nova.virt.firewall.NoopFirewallDriver
# configure vnc ip address in [vnc]
[vnc]
vncserver_listen=$my_ip
vncserver_proxyclient_address=$my_ip
# configure glance in [glance]
[glance]
api_servers=http://ops-cont:9292
# configure lock_path in [oslo_concurrency]
lock_path=/var/lib/nova/tmp
# configure placement in [placement]
[placement]
auth_uri=http://ops-cont:5000/v3
auth_url=http://ops-cont:35357/v3
os_region_name=RegionOne
project_domain_name=default
user_domain_name=default
project_name=service
user_name=placement
password=passwd
# configure rabbit transport url in [DEFAULT]
transport_url=rabbit://openstack_user:user_passwd@ops-cont
```
3. 同步数据库
```
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell" nova
# show cells
nova-manage cell_v2 list_cells
```
4. 启动服务
```
# start
systemctl start openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy
# enable
systemctl enable openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy
# add firewall rule
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port port="5672" protocol="tcp" accept' --permanent
```
5. 计算节点连接成功后执行
`nova-manage cell_v2 discover_hosts`

#### 验证操作

**在计算节点上的操作完成后**执行验证，查看服务组件是否全部启动`openstack compute service list`
![OpenStack-compute-service-list](https://s2.ax1x.com/2019/06/11/VcQBhd.png)

### 计算节点执行操作

1. 安装
`yum install openstack-nova-compute -y`
2. 配置`nova.conf`
```
# configure rabbitmq in [DEFAULT] and [oslo_messaging_rabbit]
# configure manager ip address
# configure neutron
[DEFAULT]
rpc_backend=rabbit
my_ip=192.168.0.100
use_neutron=True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[oslo_messaging_rabbit]
rabbit_host=ops-cont
rabbit_userid=openstack
rabbit_password=passwd
# configure auth in [DEFAULT] and [keystone_authtoken]
[keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domian_name=default
user_domain_name=default
project_name=server
username=nova
password=passwd
# configure vnc in [vnc]
enabled=True
vncserver_listen=0.0.0.0
vncserver_proxyclient_address=$my_ip
novncproxy_base_url=http://ops-cont:6080/vnc_auto.html
# configure iamges in [glance]
[glance]
api_servers=http://ops-cont:9292
# configure lock path in [oslo_concurrency]
lock_path=/var/lib/nova/tmp
# configure placement in [placement]
auth_uri=http://ops-cont:5000/v3
auth_url=http://ops-cont:35357/v3
os_region_name=RegionOne
project_domain_name=default
user_domain_name=default
project_name=service
user_name=placement
password=passwd
```
3. 使用kvm虚拟化
```
vi /etc/nova/nova.conf
# enable kvm in [libvirt]
virt_type=kvm
```
4. 启动服务
```
# start
systemctl start libvirtd openstack-nova-compute
# enable 
systemctl enable libvirtd openstack-nova-compute
```
## 注意

按照官方文档安装OpenStack-nova(ocata)时，在启动计算节点时会报如下错误：
> ERROR oslo_service.service PlacementNotConfigured: This compute is not configured to talk to the placement service. Configure the [placement] section of nova.conf and restart the service.

![ERROR-placement](https://s2.ax1x.com/2019/06/11/VclQDf.png)
根据提示，我们首先需要在控制节点中安装配置placement组件，同时需要将placement组件的配置信息写入到计算节点中的`nova.conf`文件中。

## 参考

1. [安装并配置控制节点](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/nova-controller-install.html)
2. [安装和配置计算节点](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/nova-compute-install.html)
3. [Install and configure Placement for Red Hat Enterprise Linux and CentOS](https://docs.openstack.org/placement/latest/install/install-rdo.html)
4. [Install and configure controller node](https://docs.openstack.org/ocata/install-guide-ubuntu/nova-controller-install.html)
