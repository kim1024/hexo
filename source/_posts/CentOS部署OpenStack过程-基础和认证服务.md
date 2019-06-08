---
title: CentOS部署OpenStack过程-基础和认证服务
date: 2019-06-08 09:59:38
categories: 
 - OpenStack
tags:
  - OpenStack
  - keystone
randnum: openstack-install-keystone
---
## 基本信息

![Openstack结构图](https://s2.ax1x.com/2019/06/06/VaSqiT.png)
![OpenStack网络结构](https://s2.ax1x.com/2019/06/08/VBMfd1.png)
![OpenStack控制节点服务](https://s2.ax1x.com/2019/06/08/VBMhIx.png)
<!--more-->

## 步骤

### 启用网络事件协议NTP

1. 控制节点
```
# install
sudo yum install chrony -y
# config
sudo vi /etc/chrony.conf
# modify
server Server_Name or IP iburst
allow 192.168.122.0/24
# start service
sudo systemctl start chronyd
sudo systemctl enable chronyd
```
2. 计算节点
```
# install
sudo yum install chrony -y
# config
sudo vi /etc/chrony.conf
# modify 注释掉除server外的字段
server cont_server iburst
# start service
sudo systemctl start chronyd
sudo systemctl enable chronyd
```
## 安装OpenStack库

1. 安装OpenStack库
`sudo yum install centos-release-openstack-ocata -y`
2. 安装OpenStack客户端
`sudo yum install python-openstackclient -y`
3. 安装SELinux策略文件
`sudo yum install openstack-selinux -y`

## 数据库

### MySQL数据库

OpenStack服务使用SQL数据库来存储信息，数据库运行在控制节点上。
1. 安装软件
`sudo yum install yum install mariadb mariadb-server python2-PyMySQL -y`
2. 配置
```
cd /etc/my.cnf.d
sudo vi mariadb.cnf
# mysqld part
[mysqld]
# change ip to controller node ip address
bind-address=192.168.122.200 
# set store-engine and character
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```
3. 启动服务
```
# start
sudo systemctl start mariadb
sudo systemctl enable mariadb
# set firewall rule
su root
firewall-cmd --zone=public --add-rich-rule='rule famliy=ipv4 source address=192.168.122.100 port port=3306 protocol=tcp accept' --permanent
firewall-cmd --reload
```
4. 检查MySQL数据库安全
`mysql_secure_installation`

### NoSQL数据库

Telemetry服务使用NoSQL数据库来存储信息，该服务运行在控制节点上。
1. 安装
`sudo yum install mongodb-server mongodb -y`
2. 配置
```
cd /etc
sudo vi mongod.conf
# modfiy
bind_ip=192.168.122.200
# limit log size 128M
smallfiles=true
```
3. 启动服务
```
# start
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 消息队列RabbitMQ

OpenStack使用 *message_queue* 协调操作和个服务的状态信息。消息队列服务运行在控制节点上。OpenStack支持多种消息队列服务，包括：RabbitMQ、Qpid和ZeroMQ。
1. 安装
`sudo yum install rabbitmq-server -y`
2. 启动服务
```
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
```
3. 添加用户
```
# create rabbitmq user with passwd
rabbitmqctl add_user openstack Passwd
# grant privilege
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

### Memcached

认证服务认证缓存使用Memcached缓存令牌，缓存服务Memcached运行在控制节点上。
1. 安装
`sudo yum install memcached python-memcached -y`
2. 启动服务
```
sudo systemctl start memcached
sudo systemctl enable memcached
```

## 认证服务

当openStack服务收到来自用户的请求时，该服务询问Identity服务，验证该用户是否有权限进行此次请求。身份服务包含的组件有：服务器、驱动、模块。
在安装认证服务前，需要线创建数据库和管理员令牌。

### 安装条件

1. 创建数据库
```
# login Mysql
mysql -u root -p
# create keystone database
create database keystone;
# grant privilege on keystone
grant all privileges on keystone.* to 'ks_db'@'localhost' identified by 'Passwd';
grant all privileges on keystone.* to 'ks_db'@'192.168.122.%' identified by 'passwd';
flush privileges;
```
2. 生成一个随机值在初始配置中作为系统管理员令牌
`openssl rand -hex 10`
记下刚生成的随机码：`e7d81bfae3c2884d8ea1`

### 安装认证服务

1. 安装
`sudo yum install openstack-keystone httpd mod_wsgi -y`
使用`mod_wsgi`来服务认证服务请求，端口号为 *5000 35357* 
2. 配置
```
cd /etc/keystone
sudo vi keystone.conf
# modify [default]  replace with copybord
admin_token = e7d81bfae3c2884d8ea1
# modify [database] replace db_passwd with mysql database passwd
# replace db_server with db-server-name or ip
# mysql+pymysql://db_user:db_passwd@db-server/db_name
connection = mysql+pymysql://ks_db:db_passwd@db-server/keystone
# modify [token]
provider = fernet
```
3. 初始化身份认证数据库
`su -s /bin/sh -c "keystone-manage db_sync" keystone`
4. 初始化Fernet Keys
`keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone`

### 配置Apache服务器

1. 编辑`httpd.conf`文件*/etc/httpd/conf/httpd.conf*
`ServerName ops-cont`
2. 创建`wsgi-keystone.conf`文件
```
cd /etc/httpd/conf.d && sudo touch wsgi-keystone.conf
# add
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
```
3. 启动服务
```
# start
sudo systemctl start httpd
sudo systemctl enable httpd
# add firewall rule
su root
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=5000/tcp --permanent
firewall-cmd --zone=public --add-port=35357/tcp --permanent
firewall-cmd --reload
```

### 创建服务实体和API端点

身份认证服务提供服务的目录和他们的位置，每个添加到OpenStack环境中的服务在目录中需要一个*service*实体和一些*API_endpoints*。

#### 安装条件

默认情况下，身份认证服务数据库不包含支持传统认证和目录服务的信息，需要使用临时身份验证令牌来初始化服务实体和API端点。
1. 配置认证令牌为环境变量
`export OS_TOKEN=e7d81bfae3c2884d8ea1`
2. 配置端点URL
`export OS_URL=http://ops-cont:35357/v3`
3. 配置认证API版本
`export OS_IDENTITY_API_VERSION=3`

#### 创建服务实体和API端点

在OpenStack环境中，认证服务管理服务目录，使用这个目录来决定环境中可用的服务。
OpenStack使用三个API端点代表每种服务：`admin`,`internal`，`public`。默认情况下，管理API端点允许修改用户和租户而内部和公众APIs不允许这些操作。
公众API是为了让用户管理自己的云在互联网上是可见的;内部API网络回被限制在包含OpenStack服务的主机上。
1. 创建服务实体和身份认证服务
```
openstack service create \
--name keystone --description "OpenStack Identity" identity
```
![openstack-create-service](https://s2.ax1x.com/2019/06/08/VBmR4U.png)
2. 所有端点和默认`RegionOne`区域都使用管理网络
`identity`与创建的服务实体认证中的`identity`对应
```
# create public API
openstack endpoint create --region RegiOne \
identity public http://ops-cont:5000/v3
# create internal API
openstack endpoint create --region RegionOne \
identity internal http://ops-cont:5000/v3
# create admin API
openstack endpoint create --region RegionOne \
identity admin http://ops-cont:5000/v3
```
![create-region](https://s2.ax1x.com/2019/06/08/VBm5v9.png)

#### 创建域、项目、用户和角色

创建的角色都映射到每个OpenStack服务配置文件目录下的`policy.json`文件中。

1. 创见域`default`
```
openstack domain create --description "Default Domain" default
```
2. 创建项目、用户和角色
```
# 创建admin项目,项目要包含在域中
openstack project create --domain default \
--description "Admin Project" admin
# 创建用户,输入用户密码
openstack user create --domain default \
--password-prompt admin
# 创建角色
openstack role create admin
# 将角色添加到用户上,执行后无输出
openstack role add --project admin --user admin admin
```
![openstack-create-domain-project-user-role](https://s2.ax1x.com/2019/06/08/VBmvgH.png)
3. 创建每个服务独有用户的service项目
```
openstack project create --domain default \
--description "Service Project" service
```
![openstack-project-create-service](https://s2.ax1x.com/2019/06/08/VBnZvj.png)
4. 创建非管理无特权的项目和用户
```
# 创建demo项目
openstack project create --domain default \
--description "Demo Project" demo
# 创建用户
openstack user create --domain default \
--password-prompt demo
# 创建角色
openstack role create user
# 将角色添加到用户上
openstack role add --project demo --user demo user
```

#### 验证操作

在安装其他服务之前需要在控制节点上确认身份认证服务。
1. 关闭临时认证令牌服务
```
cd /etc/keystone
vi keystone-paste.ini
# remove admin_token_auth from below
[pipeline:public_api]
[pipiline:admin_api]
[pipeline:api_v3]
```
2. 重置环境变量
`unset OS_URL OS_TOKEN`
3. 请求用户admin认证令牌，输入用户认证密码
```
openstack --os-auth-url http://ops-cont:35357/v3 \
--os-project-domain-name default \
--os-user-domain-name default \
--os-project-name admin \
--os-username admin token issue
```
4. 请求用户demo认证令牌，注意与用户admin区分端口号
```
openstack --os-auth-url http://ops-cont:5000/v3 \
--os-project-domain-name default \
--os-user-domain-name default \
--os-project-name demo \
--os-username demo token issue
```
![openstack-user-auth-token](https://s2.ax1x.com/2019/06/08/VBK6HI.png)

#### 创建环境脚本

1. 创建admin脚本`admin-openrc`
```
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=user_passwd
export OS_AUTH_URL=http://ops-cont:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```
2. 创建demo脚本`demo-openrc`
```
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=user_passwd
export OS_AUTH_URL=http://ops-cont:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```
3. 使用脚本
```
. admin-openrc
openstack token issue
```
## 参考

1.[OpenStack-DOC](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/)
