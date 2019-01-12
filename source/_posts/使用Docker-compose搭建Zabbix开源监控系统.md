---
title: 使用Docker-compose搭建Zabbix开源监控系统
date: 2018-10-30 14:33:07
categories: 
 - Docker
tags:
  - Docker-compose
  - Docker
  - 容器 
  - Zabbix
randnum: zabbix-docker
---

# 使用Docker-Compose搭建Zabbix系统

## 编辑docker-compose文件

   - 新建一个文件夹`zabbix`,并创建一个名为`zabbix.yml`的文件

     - `mkdir zabbix && cd zabbix && touch zabbix.yml`

   - 根据docker-compose的规范编辑yml文件

     - 详细设置 [zabbix.tar.gz][1]

<!--more-->
     - 注意事项

       1. 在yml文件中不能使用`Tab`进行分隔；

       2. 在符号`:`后接空格；

       3. 在对`zabbix-server` `zabbix-web`的环境变量进行设置时，变量的内容不需要使用符号`""` ，否则进行数据库连接时出错；

       4. 首次登录wen界面时，如果出现数据库配置错误的信息，可以进入`mysql-server`的docker容器内，查看`zabbix`数据库中`users`表中的数据是否为空，如果为空，需要在yml文件中将本地包含zabbix数据库初始化的文件夹映射到mysql容器中，然后进入容器内，使用`source`命令初始化zabbix数据库的表结构；
         - ![database error.png][2]

          - `docker exec -it mysql-server bash`
          - `mysql -uroot -p`
          - `use zabbix;`
          - `source /home/create.sql;` #开始会出现错误提示，部分表和字段已经存在，可忽略，之后会进行其他表和字段的创建，等待完成

       5. 注意设置正确的端口映射，`zabbix-server`使用`10051`端口，`zabbix-web`使用`80`和`443`端口，`mysql-server`使用`3306`端口，但是可以不映射到本机，仅限在容器间使用。
## 使用docker-compose创建容器
   - `docker-compose -f ./zabbix.yml up -d` # -d表示后台运行
   - 等待命令完成，当出现`done`字符时，表示容器已经启动
   - ![compose done.png][3]
## 登录web界面
   - `http://servername`
   - Zabbix默认的用户名和密码是:Admin/zabbix
   - ![zabbix-login.png][4]
   - ![zabbix-dashbar.png][5]


  [1]: http://baby-time.cn/usr/uploads/2018/10/1824008721.gz
  [2]: http://baby-time.cn/usr/uploads/2018/10/3317644551.png
  [3]: http://baby-time.cn/usr/uploads/2018/10/2208905385.png
  [4]: http://baby-time.cn/usr/uploads/2018/10/1321513859.png
  [5]: http://baby-time.cn/usr/uploads/2018/10/2991046210.png
