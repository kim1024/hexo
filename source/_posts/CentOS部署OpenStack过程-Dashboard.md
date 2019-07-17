---
title: CentOS部署OpenStack过程-Dashboard
date: 2019-06-11 17:08:28
categories: 
 - OpenStack
tags:
  - OpenStack
  - dashboard
randnum: openstack-install-dashboard
---

## 安装配置组件

1. 安装组件
`yum install openstack-dashboard -y`
2. 配置
<!--more-->
```
vi /etc/openstack-dashboard/local_settings
# configure dashboard_host
OPENSTACK_HOST="ops-cont"
# allow all host visit dashboard
ALLOWED_HOSTS=['*', ]
# configure memcached
SESSION_ENGINE='django.contrib.sessions.backends.cache'
CACHES={
	'default':{
		'BACKEND':'django.core.cache.backends.memcached.MemcachedCache',
		'LOCATION':'ops-cont:11211'，
	}
}
# enable auth v3
OPENSTACK_KEYSTONE_URL="http://%s:5000/v3" % OPENSTACK_HOSTS
# enable domain support
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT=True
# configure api version
OPENSTACK_API_VERSIONS={
	"identity":3,
	"image":2,
	"volume":2,
}
# configure default domain
OPEMSTACK_KEYSTONE_DEFAULT_DOMAIN="default"
# configure default role
OPENSTACK_KEYSTONE_DEFAULT_ROLE="user"
# configure timezone
TIME_ZONE="Asia/Shanghai"
```
3. 重启web,memcached服务
`systemctl restart httpd memcached`

## 验证操作

打开浏览器，输入地址：`http://ops-cont/dashboard`
![openstack-dashboard](https://s2.ax1x.com/2019/06/11/VgGxM9.png)

## 注意

按照官方文档配置完成后，在执行登录操作的时候httpd日志会报如下错误提示：
> "Unable to create a new session key. "
> RuntimeError: Unable to create a new session key. It is likely that the cache is unavailable.

根据错误提示，需要修改`SESSION_ENGINE`,将其修改为`'django.contrib.sessions.backends.file'`即可正常登录。<sup>2</sup>
![login-successed](https://s2.ax1x.com/2019/06/11/Vgazse.png)

## 参考

1. [安装dashboard](https://docs.openstack.org/mitaka/zh_CN/install-guide-rdo/horizon-install.html)
2. [openstack中dashboard页面RuntimeError](https://www.cnblogs.com/yaohong/p/7351543.html)
