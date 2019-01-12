---
title: Mysql数据库修改root用户密码
date: 2018-10-30 14:25:35
categories: 
 - Mysql
 - 学习笔记
tags:
  - Mysql
randnum: change-mysql-root-passwd
---

# 修改Mysql root用户密码

1. 在CentOS中使用yum安装的Mysql，root用户的密码默认为空，首先使用root用户登录mysql

   - `mysql -u root `

2. 进入mysql数据库后，使用`mysql`数据库

   - mysql\>`use mysql;`

3. 更新表中的user字段

   ```mysql
   mysql> update set password=password('newpasswd') where user='root';
   mysql> flus privileges;
   mysql> exit;
   ```

4. 重启mysql服务

   - `sudo systemctl restart mysql`


