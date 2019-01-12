---
title: CentOS通过源码安装PHP
date: 2018-10-30 11:55:30
categories: 
 - PHP
tags:
  - CentOS
  - PHP
randnum: centos-php-sources
---

# CentOS通过源码安装PHP

- 安装必要的库文件和工具

  - `sudo yum install autoconf libtool re2c bison libxml2-devel bzip2-devel libcurl-devel libpng-devel libicu-devel gcc-c++ libmcrypt-devel libwebp-devel libjpeg-devel openssl-devel -y`

- 下载PHP并上传到服务器中，解压到制定文件夹中

  - php下载地址
    - <https://secure.php.net/downloads.php>
  - 上传到服务器中
    - `scp ./php.tar.gz user@centos:~/php`
  - 登录到服务器中，进行相关的操作
    - `ssh -i ./ssh_key user@centos`
    - `cd ~/php && tar-xzvf php.tar.gz`

- 创建`configure` 文件

  - `sudo ./buildconf --force` 

- 使用`configure`

<!--more-->

  ```bash
  sudo ./configure \
  --prefix=/usr/local/php \
  --enable-fpm \
  --disable-short-tags \
  --with-openssl \
  --with-pcre-regex \
  --with-pcre-jit \
  --with-zlib \
  --enable-bcmath \
  --with-bz2 \
  --enable-calendar \
  --with-curl \
  --enable-exif \
  --with-gd \
  --enable-intl \
  --enable-mbstring \
  --with-mysqli \
  --enable-pcntl \
  --with-pdo-mysql \
  --enable-soap \
  --enable-sockets \
  --with-xmlrpc \
  --enable-zip \
  --with-webp-dir \
  --with-jpeg-dir \
  --with-png-dir
  ```

- 编译php文件并安装

  - `sudo make clean && sudo make && sudo make install`

- 配置php-fpm

  ```bash
  cd /usr/local/php/etc/
  sudo cp ./php-fpm.conf.default ./php-fpm.conf
  sudo vi php-fpm.conf
  //[insert]
  include =etc/fpm.d/*.conf
  pid = /var/run/php-fpm.pid
  error_log = /var/log/php-fpm.log
  cd php-fpm.d
  sudo cp www.conf.default www.conf
  vi www.conf
  //[insert]
  [www]
  user = nginx
  group = nginx
  listen = 127.0.0.1:9000
  catch_workers_output = yes
  slowlog = /var/log/php-fpm.slow.log
  request_slowlog_timeout = 30s
  php_flag[display_errors] = off
  php_admin_value[error_log] = /var/log/php-fpm.error.log
  php_admin_flag[log_errors] = on
  php_admin_value[memory_limit] = 64M
  ;php_admin_value[open_basedir] = /var/www
  ```

- 配置php.ini文件

  ```bash
  sudo cp ~/php/php.ini-develop /usr/local/php/lib/php.ini
  cd /usr/local/php/lib
  sudo vi php.ini
  //[insert]
  short_open_tag = On
  ;open_basedir = /var/www
  disable_functions = exec,passthru,shell_exec,system,proc_open,popen
  expose_php = Off
  max_execution_time = 30
  memory_limit = 64M
  date.timezone = Europe/Warsaw
  error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
  display_errors = Off
  display_startup_errors = Off
  log_errors = On
  post_max_size = 5M
  upload_max_filesize = 4M
  
  opcache.enable=1
  opcache.memory_consumption=64
  opcache.interned_strings_buffer=16
  opcache.max_accelerated_files=7000
  opcache.validate_timestamps=0 ;set this to 1 on production server
  opcache.fast_shutdown=1
  ```

- 创建php-fpm启动脚本

  ```bash
  cd /etc/init.d
  sudo cp ~/php/sapi/fpm/init.php-fpm ./php-fpm && sudo chmod +x php-fpm
  sudo vi php-fpm
  //[insert]
  prefix=/usr/local/php
  exec_prefix=${prefix}
  php_fpm_BIN=${exec_prefix}/sbin/php-fpm
  php_fpm_CONF=${prefix}/etc/php-fpm.d/*.conf
  php_fpm_PID=/var/run/php-fpm.pid
  ```

- 创建php-fpm服务

  - `sudo chkconfig -add php-fpm`
  - `sudo chkconfig php-fpm on`

- 测试php-fpm并启动

  - `sudo /etc/init.d/php-fpm configtest`
  - `sudo systemctl start php-fpm`

- 配置nginx支持php

  ```bash
  cd /etc/nginx && sudo cp nginx.conf nginx.conf.old
  sudo vi nginx.conf
  //[insert]
  location ~ \.php$ {  
  root /var/www;  
  fastcgi_pass 127.0.0.1:9000;  
  fastcgi_index index.php;  
  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;  
  include fastcgi_params;  
  }
  ```

  - 重启nginx服务
    - `sudo service nginx restart`

- 参考

  - <https://www.webhostingneeds.com/install_php-fpm_from_source_on_centos>
  - <https://blacksaildivision.com/php-install-from-source>
  - <https://www.webhostingneeds.com/nginx_php-fpm_php_site_configuration> 
