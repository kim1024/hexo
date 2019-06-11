---
title: CentOS部署OpenStack过程-网络服务
date: 2019-06-11 16:03:46
categories: 
 - OpenStack
tags:
  - OpenStack
  - neutron
randnum: openstack-install-neutron
---

## 控制节点

### 安装条件

1. 数据库
```
# login
mysql -u root
# create database
create database neutron;
# grant privilege
grant all privileges on neutron.* to 'nt_db'@'localhost' identified by 'passwd';
grant all privileges on neutron.* to 'nt_db'@'192.168.122.%' identified by 'passwd';
```
2. 创建用户
```
# create user
openstack user create \
--domain default \
--password-prompt neutron
# create role
openstack role add --project service --user neutron admin
```
<!--more-->
3. 创建服务实体
```
openstack service create \
--name neutron \
--description "OpenStack Networking" network
```
4. 创建endpoint
```
# create public endpoint
openstack endpoint create \
--region RegionOne \
network public http://ops-cont:9696
# create internal admin endpoint like public
```

### 创建私有网络

1. 安装组件
`yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y`
2. 配置组件
```
vi /etc/neutron/neutron.conf
# configure database in [database]
connection=mysql+pymysql://nt_db:db_passwd@ops-cont/neutron
# configure ml2 plugin、rabbit、keystone_authtoken in [DEFAULT]
core_plugin=ml2
service_plugins=router
allow_overlapping_ips=True
rpc_backend=rabbit
auth_strategy=keystone
notify_nova_on_port_status_changes=True
notify_nova_on_port_data_changes=True
# configure  [oslo_messaging_rabbit]
[oslo_messaging_rabbit]
rabbit_host=ops-cont
rabbit_userid=openstack
rabbit_password=passwd
# configure keystone_auth in [keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=neutron
password=passwd
# configure nova in [nova]
auth_url=http://ops-cont:35357
auth_type=password
region_name=RegionOne
project_domain_name=default
user_domain_name=default
project_name=service
username=nova
password=passwd
# configure lock path in [oslo_concurrency]
lock_path=/var/lib/neutron/tmp
```
3. 配置ml2插件
```
vi /etc/neutron/plugins/ml2/ml2.conf.ini
# enable flat,vlan,vxlan in [ml2]
# enable linuxbridge l2
# disable other type_drivers
[ml2]
type_drivers=flat,vlan,vxlan
tenant_network_types=vxlan
mechanism_drivers=linuxbridge,l2population
extension_drivers=port_security
#configure flat network in [ml2_type_flat]
[ml2_type_flat]
flat_networks=provider
# configure vxlan in [ml2_type_vxlan]
[ml2_type_vxlan]
vni_ranges=1:1000
# enable ipset in [securitygroup]
[securitygroup]
enabled_ipset=true
```
4. 配置linuxbridge代理
```
vi /etc/neutron/plugins/ml2/linuxbridge_agent.ini
# link nic with eth in [linux_bridge]
[linux_bridge]
physical_interface_mappings=provider:eth1
# configure vxlan in [vxlan]
[vxlan]
enable_vxlan=true
local_ip=192.168.122.200
l2_population=true
# configure security in [securitygroup]
[securitygroup]
enable_security_group=true
firewall_driver=neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
```
5. 配置l3代理
```
vi /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver=neutron.agent.linux.interface.BridgeInterfaceDriver
external_network_bridge=
```
6. 配置DHCP
```
vi /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver=neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver=neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata =true
```

### 配置元数据代理

```
vi /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_ip=ops-cont
metadata_proxy_shared_secret=passwd
```

### 为计算节点配置网络

1. 配置`nova.conf`
```
vi /etc/nova/nova.conf
[neutron]
url=http://ops-cont:9696
auth_url=http://ops-cont:35357
auth_type=password
project_domain_name=default
user_domain_name=default
region_name=RegionOne
project_name=service
username=neutron
password=passwd
service_metadata_proxy=true
metadata_proxy_shared_secret=passwd
```
2. 创建1个链接
`ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini`
3. 同步数据库
`su -c /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/nemutron/plugins/ml2/ml2_conf.ini upgrade head" neutron`
4. 重启api服务
`systemctl restart openstack-nova-api`
5. 启动网络服务

```
systemctl start neutron-server neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
systemctl enable neutron-server neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
```

### 验证操作

在计算节点中的操作完成后，在控制节点中执行验证操作`neutron ext-list` `neutron agent-list`,输出结果应该包含控制节点上4个代理和每个计算节点上1个代理
![neutron-agent-list](https://s2.ax1x.com/2019/06/11/VgpQZ6.png)


## 计算节点

1. 安装组件
`yum install openstack-neutron-linuxbridge ebtables ipset -y`
2. 配置组件
```
vi /etc/neutron/neutron.conf
# disable all connection in [database]
# configure rabbit in [DEFAULT] [oslo_messaging_rabbit]
# configure auth
[DEFAULT]
rpc_backend=rabbit
auth_strategy=keystone
[oslo_messaging_rabbit]
rabbit_host=ops-cont
rabbit_userid=openstack
rabbit_password=passwd
[keystone_authtoken]
auth_uri=http://ops-cont:5000
auth_url=http://ops-cont:35357
memcached_servers=ops-cont:11211
auth_type=password
project_domain_name=default
user_domain_name=default
region_name=RegionOne
project_name=service
username=neutron
password=passwd
[oslo_concurrency]
lock_path=/var/lib/neutron/tmp
```
3. 为计算节点配置网络服务
```
vi /etc/nova/nova.conf
[neutron]
url=http://ops-cont:9696
auth_url=http://ops-cont:35357
auth_type=password
projrct_domain_name=default
user_domain_name=default
region_name=RegionOne
project_name=service
username=neutron
password=passwd
```
4. 重启计算服务
`systemctl restart openstack-nova-compute`
5. 启动linuxbridge服务
```
systemctl start neutron-linuxbridge-agent
systemctl enable neutron-linuxbridge-agent
```

## 注意

按照官方文档配置后，在计算节点中启动`neutron-linuxbridge-agent`服务时，会有如下报错：
> neutron.plugins.ml2.drivers.linuxbridge.agent.linuxbridge_neutron_agent [-] Tunneling cannot be enabled without the local_ip bound to an interface on the host. Please configure local_ip None on the host interface to be used for tunneling and restart the agent.

根据提示，需要在`/etc/neutron/plugins/ml2/linuxbridge-agent.ini`中的`[vxlan]`部分中添加本地ip地址`local_ip=192.168.122.100`

## 参考

1. [为控制节点配置网络](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/neutron-controller-install-option2.html)
2. [为计算节点配置网络](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/neutron-compute-install.html)
