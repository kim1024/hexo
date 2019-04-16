---
title: 使用Docker-compose构建Nginx-PHP-Mysql环境
date: 2018-10-30 14:30:30
categories: 
 - Docker
tags:
  - Docker
  - Docker-compose
  - 容器
randnum: lnmp-docker
---

# 使用Docker-Compose搭建nginx+php+mysql基础应用

## PHP

  - 为了能连接mysql数据库，php还需要安装相关的插件

    1. 首先需要建立docker-php目录

       - `mkdir docker4php`

    2. 创建Dockerfile

       - `vi Dockerfile`

    3. 添加以下内容<sup>1</sup>  

       ```python
       FROM php:7.1-fpm-alpine  
       Run apt-get update \
       && apt install iputils-ping \
       && docker-php-ext-install mysqli && docker-php-ext-enable mysqli
       ```
<!--more-->
## Mysql

    - 从Docker Hub拉取最新版的mysql镜像 <sup>2</sup>
      - `sudo pull mysql`

## Docker-Compose

    - 下载对应系统版本的docker-compose，上传到服务器，并添加执行权限；除此之外，还可以使用脚本安装<sup>3</sup>

  - 使用docker-compose创建项目<sup>4</sup> 

    1. 建立项目结构

       ```bash
       mkdir npm4compose
       cd npm4compose
       mkdir conf.d php html && touch docker-compose.yml
       cd conf.d && touch nginx.conf
       cd html && touch index.php && echo "<?php phpinfo(); ?>" >index.php
       cp ~/docker4php/Dockerfile ./php/
       
       ```

        - 目录结构如下

          ```
          npm4compose/
          |—— conf.d   #nginx配置文件目录
          	|—— nginx.conf #自定义nginx配置文件
          |—— docker-compose.yml # compose文件
          |—— html  #网站根目录
          	|—— index.php
          |—— php #php目录
          	|—— Dockerfile
          ```

    2. 编辑`docker-compose.yml`文件<sup>5</sup> <sup>6</sup> 

       ```dockerfile
       version: '3'
       services:
       	nginx:
       		image: nginx:lastest
       		ports:   		    #端口映射
       			- "80:80"
       		depends_on:		#依赖关系，需要先运行php
       			- "php"
       		volumes:
       			- "${PWD}/conf.d:/etc/nginx/conf.d"   #将宿主机上nginx配置文件映射到容器中
       			- “${PWD}/html:/usr/share/nginx/html” #映射网站根目录
       		networks:
       			- d_net
       		container_name: "compose-nginx"  #容器名称
       	php:
       		build: ./php  #指定build Dockerfile生成镜像
       		image: php:7.1-fpm-alpine
       		ports:
       			- "9000:9000"
       		volumes:
       			- "$PWD/html:/var/www/html"
       		networks:
       			- d_net: 
       		container_name: "compose-php"
       	mysql:
       		image: mysql:8.0
       		ports:
       			- "3306:3306"
       		environment:
       			- MYSQL_ROOT_PASSWORD={your_passwd}
       		networks:
       			- d_net
       		container_name: "compose-mysql"
       networks: 			#配置docker 网络
       	app_net:
       		driver: bridge
       
       ```

    3. 配置本地nginx.conf文件<sup>7</sup>

       ```nginx
       server{
           listen	80;
           server_name	localhost;
           location /{
               	root 	/var/www/html;
               	index	index.php index.html index.htm;
           }
           error_page	 500 502 503 504 /50x.html;
           location = /50x.html {
               	root	/var/www/html;
           }
           location ~ \.php$ {
               include 	fastcgi_params;
               fastcgi_pass	php:9000;
               fastcgi_index	index.php;
               fastcgi_param	SCRIPT_FILENAME /var/www/html/$fastcgi_script_name;
           }
           
       }
       ```

    4. 运行docker-compose，`docker-compose up -d`

## 参考
  - 1. [docker-php Tags](https://hub.docker.com/_/php/) 
    2. [docker-mysql](https://hub.docker.com/_/mysql/) 
    3. [docker-compose](https://github.com/docker/compose/releases)
    4. [docker-compose for nginx php mysql](https://www.jianshu.com/p/0561d3cfccda) 
    5. [compose yml file ](https://docs.docker.com/compose/compose-file/#compose-and-docker-compatibility-matrix) 
    6. [compose yml file for CN](https://yeasy.gitbooks.io/docker_practice/compose/compose_file.html) 
    7. [nginx config document](https://nginx.org/en/docs/beginners_guide.html) 
    8. [docker q&a](https://blog.lab99.org/post/docker-2016-07-14-faq.html) 

 
