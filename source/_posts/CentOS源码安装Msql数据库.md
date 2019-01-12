---
title: CentOS源码安装Msql数据库
date: 2018-10-30 14:18:06
categories: 
 - CentOS
 - Mysql
tags:
  - CentOS
  - Mysql
  - 源码安装
randnum: centos-mysql-sources
---

# CentOS通过源码安装Mysql

- 下载mysql源码和boost文件，并上传到服务器中

  - 下载地址：<http://ftp.jaist.ac.jp/pub/mysql/Downloads/MySQL-8.0/> 
  - ncurses下载地址：<https://ftp.gnu.org/pub/gnu/ncurses/> 

- 创建myql所需要的用户和用户组

  - `sudo groupadd mysql`
  - `sudo useradd -r -g  mysql -s /bin/false mysql`

- 创建mysql数据库存放位置

  - `cd /var/ && sudo mkdir mysqldb`
  - `sudo chown -R mysql:mysql mysqdb`

- 解压源码安装包，并进入文件目录,制定boost路径，在该文件夹中存放的是boost压缩包，文件名为`boost_1_67_0.tar.gz`

<!--more-->
  ```bash
  sudo yum install numactl-devel ncurses-devel
  mkdir bld
  sudo cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
  -DSYSCONFDIR=/etc/mysql/ \
  -DMYSQL_DATADIR=/var/mysqldb \
  -DWITH_BOOST=boost/
  sudo make -j 20 #使用多线程编译
  sudo make install
  ```

- 将mysql添加到环境变量中

  - `sudo export PATH=${PATH}:/usr/local/mysql/bin`

- 安装mysql服务，并开机启动

  ```bash
  sudo chown -R mysql:mysql /usr/local/mysql
  sudo cp ~/mysql/support-files/mysql.server /etc/init.d/mysqld
  sudo chmod +x mysqld
  sudo chkconfig --add mysql
  sudo chkconfgi mysql on
  ```

- 创建mysql配置文件

  ```bash
  [mysqld]
  datadir=/var/mysqldb
  socket=/var/run/mysql.sock
  user=mysql
   
  symbolic-links=0
   
  [mysqld_safe]
  log-error=/var/log/mysql_error.log
  pid-file=/var/run/mysql.pid
  key_buffer_size = 8144M
  table_cache_size = 1024M
  read_buffer_size = 128M
  sort_buffer_size = 32M
  query_cache_size = 100M
  thread_cache_size = 16
  thread_concurrency = 32
  max_heap_table_size = 400M
  tmp_table_size = 400M
  max_connections = 500
  # The end
  #
  ```

- 安装mysql数据库文件

  ```
  cd /usr/local/mysql/bin
  sudo ./mysqld --initializa -user=mysql --datadir=/var/mysqldb
  sudo ./mysql_ssl_rsa_setup
  sudo ./mysqld_safe --user=mysql &
  ```


- 参考
  - cmake参数说明:<https://dev.mysql.com/doc/refman/5.7/en/source-configuration-options.html#cmake-option-reference> 
  - <http://shihlei.iteye.com/blog/2296886> 
  - <https://dev.mysql.com/doc/refman/5.6/en/installing-source-distribution.html> 
  - mysql官方安装指导：<https://dev.mysql.com/doc/refman/8.0/en/binary-installation.html>
