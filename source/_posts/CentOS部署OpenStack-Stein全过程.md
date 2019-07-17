---
title: CentOS部署OpenStack-Stein全过程
date: 2019-06-17 11:49:40
categories: 
 - OpenStack
tags:
  - OpenStack
  - Stein
randnum: openstack-install-Stein
---
## 基本信息

![dashboard](https://s2.ax1x.com/2019/06/17/VHiZHx.png)
<!--more-->
## 安装

1. 安装openstack-stein软件源
`yum install centos-release-openstack-stein -y`
2. 安装NTP服务
`yum install chrony -y`
3. 安装openstack客户端
`yum install python-openstackclient openstack-selinux -y`

### 安装数据库<sup>1</sup>

1. 安装mariadb-server pyhont2-pymysql
```
yum install mariadb mariadb-server python2-pymysql -y

```
2. 配置数据库
```
vi /etc/my.cnf.d/mariadb-server.cnf
# modify
[mysqld]
bind-address=192.168.122.11
default-storage-engine=innodb
innodb_file_per_table=on
max_connections=4096
collation-server=utf8_general_ci
character-set-server=utf8
```
3. 启动服务并执行安全检查
```
systemctl start mariadb 
systemctl enable mariadb
mysql_secure_installation
```
4. 添加开放端口
`firewall-cmd --zone=internal --add-port=3306/tcp --permanent`

### 安装消息服务rabbit<sup>2</sup>

1. 安装
`yum install rabbitmq-server -y`
2. 启动服务
```
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
```
3. 创建消息服务用户
`rabbitmqctl add_user rbtmq user_passwd`
4. 授权用户读写权限
`rabbitmqctl set_permissions rbtmq ".*" ".*" ".*"`
5. 添加开放端口
`firewall-cmd --zone=internal --add-port=5672/tcp --permanent`

### 安装认证缓存memcached<sup>3</sup>

1. 安装
`yum install memcached python-memcached -y`
2. 配置
```
vi /etc/sysconfig/memecached 
## modify
OPTION="-l 127.0.0.1,::1,ops-ctr"
```
3. 启动服务
```
systemctl start memecached
systemctl enable memecached
# add firewall rule
firewall-cmd --zone=internal --add-port=11211 --permanent
```

### 安装etcd服务<sup>4</sup>

1. 安装
`yum install etcd -y`
2. 配置
```
vi /etc/etcd/etcd.conf
# modify
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.122.11:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.122.11:2379"
ETCD_NAME="controller"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.11:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.122.11:2379"
ETCD_INITIAL_CLUSTER="controller=http://192.168.122.11:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
```
3. 启动服务
```
systemctl start etcd
systemctl enabl etcd
```
4. 添加开放端口
```
firewall-cmd --zone=internal --add-port=2379/tcp --permanent
firewall-cmd --zone=internal --add-port=2380/tcp --permanent
```

### 安装placement服务<sup>10</sup>

1. 数据库
```
create database placement;
grant all on placement.* to 'plcm_db'@'localhost' identified by 'passwd';
grant all on placement.* to 'plcm_db'@'%' identified by 'passwd';
```
2. 创建用户
```
openstack user create --domain default \
--password-prompt placement
openstackk role add --project service --user placement admin
```
3. 创建服务实体
```
openstack service --name placement \
--description "OpenStack Placement" placement
```
4. 创建endpoint
```
openstack endpoint create --region RegionOne \
placement public http://ops-ctr:8778
# create internal admin endpoint like public
```
5. 安装组件
`yum install openstack-placement-api -y`
6. 配置
```
vi /etc/placement/placement.conf
[placement_database]
connection=mysql+pymysql://plcm_db:passwd@ops-ctr/placement
[api]
auth_strategy=keystone
[keystone_authtoken]
auth_url=http://ops-ctr:5000/v3
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=placement
password=passwd
vi /etc/httpd/conf.d/00-placement-api.conf
# add
<Directory /usr/bin>
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>
    <IfVersion < 2.4>
        Order allow,deny
        Allow from all
    </IfVersion>
</Directory>
```
7. 同步数据库
`/bin/sh -c "placement-manage db sync" placement`
9. 重启httpd服务
`systemctl restart httpd`

### 安装openstack服务

#### 安装认证服务keystone<sup>5</sup>

1. 数据库服务
```
# create database
create database keystone;
# set permission
grant all on keystone.* to 'kst_db'@'localhost' identified by '';
grant all on keystone.* to 'kst_db'@'%' identified by '';
```
2. 安装keystone组件
`yum install openstack-keystone httpd mod_wsgi -y`
3. 配置
```
vi /etc/keystone/keystone.conf
[database]
connection=mysql+pymysql://kst_db:passwd@ops-cont/keystone
[token]
provider=fernet
[signing]
enable=true
certfile=/etc/pki/tls/private/pub.pem
keyfile=/etc/pki/tls/private/key.pem
ca_certs=/etc/pki/tls/certs/cert.pem
cert_required=true
```
4. 同步数据库
`/bin/sh -c "keystone-manage db_sync" keystone`
5. 初始化fernet
```
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group=keystone
```
6. 创建bootstrap服务
```
keystone-manage bootstrap --bootstrap-password passwd \
--bootstrap-admin-url http://ops-ctr:5000/v3 \
--bootstrap-internal-url http://ops-ctr:5000/v3 \
--bootstrap-public-url http://ops-ctr:5000/v3 \
--bootstrap-region-id RegionOne
```
6. 配置httpd服务
```
vi /etc/httpd/conf/httpd.conf
# add
ServerName ops-ctr
# configure /etc/httpd/conf.d/wsgi-keystone.conf
Listen 5000
<VirtualHost *:5000>
    # SSLEngine on
    # SSLCertificateKeyFile /etc/pki/tls/private/key.pem
    # SSLCertificateFile /etc/pki/tls/private/cert.pem
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
# create link
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
```
7. 启用ssl加密链接，参考[Apache enable ssl on centos](https://wiki.centos.org/HowTos/Https)

8. 设置环境变量
```
export OS_USERNAME=admin
export OS_PASSWORD=passwd
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=https://ops-ctr:5000/v3
export OS_IDENTITY_API_VERSION=3
```
9. 创建服务用户、角色、项目和域
```
# create domain if need
openstack domain create --description "mystack" mystack
# create project
openstack project create --domain default \
--description "Service Project" service
openstack project create --domain default \
--description "Demo Project" demo
# create user
openstack user create --domain default \
--password-prompt demo
# create role
openstack role create demo
# set role for user
openstack role add --project service --user demo demo
```
10. 验证操作
```
# unset 
unset OS_AUTH_URL OS_PASSWORD
# request new auth token
openstack --os-auth-url https://ops-ctr:5000/v3 \
--os-project-domain-name default \
--os-user-domain-name default \
--os-project-name admin \
--os-username admin token issue
openstack --os-auth-url https://ops-ctr:5000/v3 \
--os-project-domain-name default \
--os-user-domain-name default \
--os-project-name demo \
--os-username demo token issue
```
11. 分别创建用户admin和demo的环境脚本
```
admin-openrc
---
export OS_USERNAME=admin
export OS_PASSWORD=passwd
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=http://ops-ctr:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

demo-openrc
---
export OS_USERNAME=demo
export OS_PASSWORD=passwd
export OS_PROJECT_NAME=demo
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=http://ops-ctr:5000/v3
export OS_IDENTITY_API_VERSION=3
```

### 安装镜像服务glance<sup>6</sup>

1. 数据库
```
create database glance;
# set permission to glc_db on glance like keystone
```
2. 创建用户
```
openstack user create --domain default \
--password-prompt glance
openstack role add --project service --user glance admin
```
3. 创建服务实体
```
openstack service create \
--name glance \
--description "OpenStack Image" image
```
4. 创建服务endpoint
```
openstack endpoint create --region RegionOne \
image public http://ops-ctr:9292
# create admin internal endpoint like public
# add port 9292 by firewall-cmd
```
5. 安装glance组件
`yum install openstack-glance -y`
7. 配置
```
vi /etc/glance/glance-api.conf
[database]
connection=mysql+pymysql://glc_db:passwd@ops-ctr/glance
[keystone_authtoken]
www_authenticate_uri=http://ops-ctr:5000
auth_url=http://ops-ctr:5000
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=glance
password=passwd
[paste_deploy]
flavor=keystone
[glance_store]
stores=file,http
default_store=file
filesystem_store_datadir=/var/lib/glance/images/
vi /etc/glance/glance-registry.conf
[database]
connection=mysql+pymysql://glc_db:passwd@ops-ctr/glance
www_authenticate_uri=http://ops-ctr:5000
auth_url=http://ops-ctr:5000
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=glance
password=passwd
[paste_deploy]
flavor=keystone
```
8. 同步数据库
`glance-manage db_sync glance`
9. 启动服务
```
systemctl start openstack-glance-api openstack-glance-registry
systemctl enable openstack-glance-api openstack-glance-registry
```
如果glance-api服务启动失败，尝试修改`/var/lib/glance/images`和`/var/log/glance/api.log`的所属用户和组为`glance:glance`
10. 验证操作
```
. admin-openrc
# create image use cirros.img
openstack image create "cirros" \
--file /home/user/cirros-0.4.0-x86_64-disk.img \
--disk-format qcow2 \
--container-format bare \
--public
# show image
openstack image list
```

### 安装计算服务nova<sup>8</sup>

#### 控制节点中安装nova服务

1. 数据库
```
# create database
create database nova;
create database nova_api;
create database nova_cell0;
# set permission like others
grant all on nova.* to 'nva_db'@'localhost' identified by 'passwd';
```
2. 创建用户
```
openstack user create --domain default \
--password-prompt nova
openstack role add --project service --user nova admin
```
3. 创建服务实体
```
openstack service create --name nova \
--description "OpenStack Compute" compute
```
4. 创建endpoint
```
openstack endpoint create --region RegionOne \
compute public http://ops-ctr:8774/v2.1
# create internal admin endpoint like public
# add port to firewall
```
5. 安装nova组件
`yum install openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-console -y`
6. 配置组件
```
vi /etc/nova/nova.conf
[DEFAULT]
enabled_apis=osapi_compute,metadata
transport_url=rabbit://rbtmq:paswd@ops-ctr
my_ip=192.168.122.11
use_neutron=true
firewall_driver=nova.virt.firewall.NoopFirewallDriver
[database]
connection=mysql+pymysql://nva_db:passwd@ops-ctr/nova
[api_database]
connection=mysql+pymysql://nva_db:passwd@ops-ctr/nova_api
[api]
auth_strategy=keystone
[keystone_authtoken]
auth_url=http://ops-ctr:5000/v3
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=nova
password=passwd
[vnc]
enabled=true
server_listen=$my_ip
server_proxyclient_address=$my_ip
[glance]
api_servers=http://ops-ctr:9292
[oslo_concurrency]
lock_path=/var/lib/nova/tmp
[placement]
region_name=RegionOne
auth_url=http://ops-ctr:5000/v3
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=placement
password=passwd
[scheduler]
discover_hosts_in_cells_interval=300
```
7. 同步数据库
```
/bin/sh -c "nova-manage api_db sync" nova
/bin/sh -c "nova-manage cell_v2 map_cell0" nova
/bin/sh -c "nova-manage cell_v2 create_cell --name cell1 --verbose" nova
/bin/sh -c "nova-manage db sync" nova
# show cells
nova-manage cell_v2 list_cells nova
```
8. 启动服务
```
systemctl start openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy
systemctl enable openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy
```
9. 将计算节点添加到cell数据库

```
# show compute service
openstack compute service list 
# discover compute node
/bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
```
10. 确认操作
```
# show endpoint
openstack catalog list
# show image
openstack image list
nova-status upgrade check
```

#### 计算节点中安装nova服务<sup>9</sup>

1. 安装组件
`yum install openstack-nova-compute -y`
2. 配置
```
vi /etc/nova/nova.conf
[DEFAULT]
enabled_apis=osapi_compute,metadata
transport_url=rabbit://rbtmq:passwd@ops-ctr
my_ip=192.168.122.12
use_neutron=true
firewall_driver=nova.virt.firewall.NoopFirewallDriver
[api]
auth_strategy=keystone
[keystone_authtoken]
auth_url=http://ops-ctr:5000/v3
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=nova
password=passwd
[vnc]
enabled=true
server_listen=0.0.0.0
server_proxyclient_address=$my_ip
novncproxy_base_url=http://ops-ctr:6080/vnc_auto.html
[glance]
api_servers=http://ops-ctr:9292
[oslo_concurrency]
lock_path=/var/lib/nova/tmp
[placement]
region_name=RegionOne
auth_url=http://ops-ctr:5000/v3
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=placement
password=passwd
[libvirt]
virt_type=qemu
```
3. 启用虚拟化
```
egrep -c '(vmx|svm)' /proc/cpuinfo
结果：0-qemu
```
4. 启动服务
```
systemctl start lilbvirtd openstack-nova-compute
systemctl enable lilbvirtd openstack-nova-compute
```

### 安装网络服务neutron

#### 控制节点

1. 数据库
```
create database neutron;
grant all on neutron.* to 'ntr_db'@'localhost' identified by 'passwd';
grant all on neutron.* to 'ntr_db'@'%' identified by 'passwd';
```
2. 创建用户
```
openstack user create --domain default \
--password-prompt neutron
openstack role add --project service --user neutron admin
```
3. 创建服务实体和endpoint
4. 创建网络
  - 私有网络
    1. 安装组件
    `yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y`
    2. 配置
    ```
    vi /etc/neutron/neutron.conf
    [DEFAULT]
    core_plugin=ml2
    service_plugins=router
    allow_overlapping_ips=true
    transport_url=rabbit://rbtmq:passwd@ops-ctr
    auth_strategy=keystone
    notify_nova_on_port_status_changes=true
    notify_nova_on_port_data_changes=true
    [database]
    connection=mysql+pymysql://ntr_db:passwd@ops-ctr/neutron
    [keystone_authtoken]
    www_authenticate_uri=http://ops-ctr:5000
    auth_url=http://ops-ctr:5000
    memcached_servers=ops-ctr:11211
    auth_type=password
    project_domain_name=default
    user_domain_name=default
    project_name=service
    username=neutron
    password=passwd
    [nova]
    auth_url=http://ops-ctr:5000
    auth_type=password
    project_domain_name=default
    user_domain_name=default
    project_name=service
    username=nova
    password=passwd
    [oslo_concurrency]
    lock_path=/var/lib/neutron/tmp
    vi /etc/neutron/plugins/ml2/ml2_conf.ini
    [ml2]
    type_drivers=flat,vlan,vxlan
    tenant_network_types=vxlan
    mechanism_drivers=linuxbridge,l2population
    extension_drivers=port_security
    [ml2_type_flat]
    flat_networks=provider
    [ml2_type_vxlan]
    vni_ranges=1:1000
    [securitygroup]
    enable_ipset=true
    vi /etc/neutron/plugins/ml2/linuxbridge_agent.ini
    [linux_bridge]
    physical_interface_mappings=provider:eth1
    [vxlan]
    enable_vxlan=true
    local_ip=192.168.122.11
    l2_population=true
    [securitygroup]
    enable_security_group=true
    firewall_driver=neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    vi /etc/neutron/l3_agent.ini
    [DEFAULT]
    interface_driver=linuxbridge
    vi /etc/neutron/dhcp_agent.ini
    [DEFAULT]
    interface_driver=linuxbridge
    dhcp_driver=neutron.agent.linux.dhcp.Dnsmasq
    enable_isolated_metadata=true
    ```
5. 配置元数据
```
vi /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_host=ops-ctr
metadata_proxy_shared_secret=passwd
```
6. 配置nova服务
```
vi /etc/nova/nova.conf
[neutron]
url=http://ops-ctr:9696
auth_url=http://ops-ctr:5000
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=neutron
password=passwd
service_metadata_proxy=true
metadata_proxy_shared_secret=passwd
```
7. 同步数据库
```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
/bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```
8. 启动服务
```
systemctl restart openstack-nova-api
systemctl start neutron-server neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
systemctl enable neutron-server neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
```
9. 验证操作
`openstack network agent list`
计算节点有1个服务，控制节点有4个服务

#### 计算节点

1. 安装组件
`yum install openstack-neutron-linuxbridge ebtables ipset -y`
2. 配置
```
vi /etc/neutron/neutron.conf
[DEFAULT]
transport_url=rabbit://rbtmq:passwd@ops-ctr
auth_strategy=keystone
[keystone_authtoken]
www_authenticate_uri=http://ops-ctr:5000
auth_url=http://ops-ctr:5000
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=neutron
password=passwd
[oslo_concurrency]
lock_path=/var/lib/neutron/tmp
vi /etc/nova/nova.conf
[neutron]
url=http://ops-ctr:9696
auth_url=http://ops-ctr:5000
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=neutron
password=passwd
vi /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]
physical_interface_mappings=provider:eth1
[vxlan]
enable_vxlan=true
local_ip=192.168.122.12
l2_population=true
[securitygroup]
enable_security_group=true
firewall_driver=neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

```
3. 启动服务
```
systemctl restart openstack-nova-compute
systemctl start neutron-linuxbridge-agent
systemctl enable neutron-linuxbridge-agent
```

### 安装UI服务horizon<sup>12</sup>

1. 安装组件
`yum install openstack-dashboard -y`
2. 配置
```
vi /etc/openstack-dashboard/local_settings
OPENSTACK_HOST="ops-ctr'
ALLOW_HOSTS=['*', ]
SESSION_ENGINE='django.contrib.sessions.backends.cache'
CACHE={
    'default':{
        'BACKEND':'django.core.cache.backends.memcached.MemcachedCache',
        'LOCALTION':'ops-ctr:11211',
    }
}
OPENSTACK_KEYSTONE_URL="http://%s:5000/v3 % OPENSTACK_HOST"
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT=True
# True要使用大写，用小写会报错
OPENSTACK_VERSIONS={
    "identity":3,
    "image":2,
    "volume":3,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN="default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE="demo"
TIME_ZONE="Asia/Shanghai"
vi /etc/httpd/conf.d/openstack-dashboard.conf
# add
WSGIApplicationGroup %{GLOBAL}
```
3. 重启服务
```
systemctl restart httpd memcached
```

### 添加一个存储节点

#### 控制节点<sup>13</sup>

1. 数据库
```
create database cinder;
grant all on cinder.* to 'cid_db'@'localhost' identified by 'passwd';
```
2. 创建用户、角色、endpoint和2个服务：
  - cinderv2,cinderv3,类型分别是volumev2,volumev3
  - v2 endpoint地址http://ops-ctr:8776/v2/%\(project_id\)s
  - v3 endpoint地址http://ops-ctr:8776/v3/%\(project_id\)s
3. 安装组件
`yum install openstack-cinder -y`
4. 配置
```
vi /etc/cinder/cinder.conf
[DEFAULT]
transport_url=rabbit://rbtmq:passwd@ops-ctr
auth_strategy=keystone
my_ip=192.168.122.11
[database]
connection=mysql+pymysql://cid_db:passwd@ops-ctr/cinder
[keystone_authtoken]
www_authenticate_uri=http://ops-ctr:5000
auth_url=http://ops-ctr:5000
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=cinder
password=passwd
[oslo_concurrency]
lock_path=/var/lib/cinder/tmp
```
5. 同步数据库
`/bin/sh -c "cinder-manage db sync" cinder`
7. 配置计算服务使用块存储
```
vi /etc/nova/nova.conf
# add
[cinder]
os_region_name=RegionOne
```
8. 启动服务
```
systemctl restart openstack-nova-api
systemctl start openstack-cinder-api openstack-cinder-scheduler
systemctl enable openstack-cinder-api openstack-cinder-scheduler
```
9. 检查操作
`openstack volume service list`

#### 存储节点

1. 安装组件
`yum install lvm2 device-mapper-persistent-data -y`
2. 创建逻辑分区
`pvcreate /dev/vdb`
3. 创建逻辑卷组
`vgcreate cinder /dev/vdb`
4. 添加过滤器
```
vi /etc/lvm/lvm.conf
filter=["a/dev/vda/","a/dev/vdb/","r/.*/"]
```
5. 安装cinder组件
`yum install openstack-cinder targetcli python-keystone -y`
6. 配置
```
vi /etc/cinder/cinder.conf
[DEFAULT]
transport_url=rabbit://rbtmq:passwd@ops-ctr
auth_strategy=keytone
my_ip=192.168.122.13
enabled_backends=lvm
glance_api_servers=http://ops-ctr:9292
[database]
connection=mysql+pymysql://cid_db:passwd@ops-ctr/cinder
[keystone_authtoken]
www_authenticate_uri=http://ops-ctr:5000
auth_url=http://ops-ctr:5000
memcached_servers=ops-ctr:11211
auth_type=password
project_domain_name=default
user_domain_name=default
project_name=service
username=cinder
password=passwd
[lvm]
volume_driver=cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group=cinder
target_protocol=iscsi
target_helper=lioadm
[oslo_concurrency]
lock_path=/var/lib/cinder/tmp
```
7. 启动服务
```
systemctl start openstack-cinder-volume target
systemctl enable openstack-cinder-volume target
```

### 创建实例

#### 创建公有网络<sup>15</sup>

1. 创建网络

```
. admin-openrc
# 使用provider创建1个flat类型的网络，名称为provider
openstack network create \
--share --external \
--provider-physical-network provider \
--provider-network-type flat provider
```
2. 创建子网
```
使用创建的provider网络，创建1个192.168.0.200-240范围的子网
openstack subnet create \
--network provider \
--allocation-pool start=192.168.0.200,end=192.168.0.240 \
--dns-nameserver 192.168.0.1 \
--gateway 192.168.0.1 \
--subnet-range 192.168.0.0/24 provider
```
#### 创建私有网络<sup>16</sup>

1. 创建网络
```
. demo-openrc

openstack network create selfservice
```
2. 创建子网
```
openstack subnet create \
--network selfservice \
--dns-nameserver 192.168.0.1 \
--gateway 192.168.100.1 \
--subnet-range 192.168.100.0/24 selfservice
```
3. 创建路由
`openstack router create self-router`
4. 将selfservice网络添加到路由中
`openstack router add subnet self-router selservice`
5. 在路由中设置公网网关
`openstack router set self-router --external-gateway provider`
6. 检查操作
```
. admin-openrc
ip netns
openstack port list --router self-router
```

#### 创建实例

1. 创建最小规格的主机,内存64M，硬盘1G，名称m1.nano
`openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano`
2. 添加密钥对
`openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey`
3. 添加安全规则到default安全组中
```
# allow ping
openstack security group rule create --proto icmp default
# allow ssh 
openstack security group rule create --proto tcp --dst-port 22 default
```

#### 创建主机

1. 私网主机<sup>17</sup>
```
. demo-openrc
openstack server create --flavor m1.nano \
--image cirros \
--nic net-id=c34add94-6f4d-4312-92f9-ac4ad426bce7 \
--security-group default \
--key-name mykey self-host
```
2. 查看创建的主机
`openstack server list`
3. 虚拟终端访问主机
`openstack console url show self-host`
![show-host](https://s2.ax1x.com/2019/06/17/V7O4iR.png)
![vnc-console](https://s2.ax1x.com/2019/06/17/VHPNp4.png)
5. 远程访问主机
```
# create float ip
openstack floating ip create provider
# associate floating ip with self-host
openstack server add floating ip self-host 192.168.0.234
# show server list
openstack server list
```
![create-floating-ip](https://s2.ax1x.com/2019/06/17/V7X6fI.png)
![associate-floating-ip](https://s2.ax1x.com/2019/06/17/V7XvBF.png)

## 参考

1. [install database on centos](https://docs.openstack.org/install-guide/environment-sql-database-rdo.html#install-and-configure-components)
2. [install rabbitmq-server on centos](https://docs.openstack.org/install-guide/environment-messaging-rdo.html#install-and-configure-components)
3. [install memcached on centos](https://docs.openstack.org/install-guide/environment-memcached-rdo.html#install-and-configure-components)
4. [install etcd on centos](https://docs.openstack.org/install-guide/environment-etcd-rdo.html#install-and-configure-components)
5. [install keystone on centos](https://docs.openstack.org/keystone/stein/install/keystone-install-rdo.html)
6. [install glance on centos](https://docs.openstack.org/glance/stein/install/install-rdo.html#install-and-configure-components)
7. [enable ssl on keystone](https://docs.openstack.org/mitaka/admin-guide/keystone_configure_with_SSL.html)
8. [install nova on centos](https://docs.openstack.org/nova/stein/install/controller-install-rdo.html#prerequisites)
9. [compute server install nova](https://docs.openstack.org/nova/stein/install/compute-install-rdo.html#install-and-configure-components)
10. [install placement on centos](https://docs.openstack.org/placement/stein/install/install-rdo.html)
11. [incell neutron on centos](https://docs.openstack.org/neutron/stein/install/install-rdo.html)
12. [install horizon on centos](https://docs.openstack.org/horizon/stein/install/install-rdo.html)
13. [install cinder on centos for controller](https://docs.openstack.org/cinder/stein/install/cinder-controller-install-rdo.html#prerequisites)
14. [install cinder on centos for storage](https://docs.openstack.org/cinder/stein/install/cinder-storage-install-rdo.html)
15. [create provider network](https://docs.openstack.org/install-guide/launch-instance-networks-provider.html)
16. [create self-service network](https://docs.openstack.org/install-guide/launch-instance-networks-selfservice.html)
17. [create self-host in selfservice](https://docs.openstack.org/install-guide/launch-instance-selfservice.html)
