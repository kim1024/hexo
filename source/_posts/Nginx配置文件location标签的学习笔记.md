---
title: Nginx配置文件location标签的学习笔记
date: 2018-11-01 11:57:49
categories: 
 - Nginx
tags:
  - Nginx
  - 配置文件
  - location
  - 学习笔记
randnum: nginx-location
---

# Nginx 配置文件中location标签的学习

## 语法规则
```
location [/|=|~|~*|^~] url {}
location @name {}
```
## 修饰符

- `/` 通配符，如果没有找到任何匹配规则，则执行该项；
- `=` 表示精确匹配。只有请求的url路径与后面的字符完全匹配时，才会执行；
- `～` 表示该规则是使用正则表达式，**区分大小写** ；
- `~*` 表示该规则时使用正则表达式，**不区分大小写** ;
- `^~` 表示如果该符号后面的字符是最佳匹配，采用该规则，不再进行后续的查找,该项不是正则表达式；

<!--more-->
## URL匹配过程

- location有两种表达形式：**前缀字符\正则规则**  

- 匹配过程
  1. 首先检查使用**前缀** 字符定义的`location` ,选择最长匹配项并记录下来；
  2. 如果找到了精确匹配的`location` ，也就是使用了`=` 的`location`，则执行该项，结束查找；
  3. 如果没有精确匹配，则开始寻找使用**正则表达**定义的`location`,如果找到匹配项，则执行，结束查找；
  4. 如果没有找到匹配的正则`location`,则使用前面记录的最长匹配前缀字符`location` ;

- Tips
  - 使用正则表达的`location` 按照出现的先后顺序查找，优先执行先匹配到的正则`location` ;
  - 使用精确匹配`=` 可以提高查找速度；

## 实例说明

```
location = / {A} 
# 使用精确匹配，请求/，则执行A，不再往下查找
location / {B}
# 请求/index.html,首先查找匹配的前缀字符，找到最长匹配是B，继续查找正则表达的location，没有找到正则表达的，则执行最长匹配B
location /user/ {C}
# 请求/user/index.html，首先查找前缀字符，找到最长匹配是C，继续查找正则表达，没有找到正则表达的location，则执行最长匹配C
location ^~ /images/ {D}
# 请求/images/1.jpg ，首先查找前缀字符，找到最长匹配D，因为该location使用了字符^~，所以最佳匹配为D，不再继续查找
location ~* \.(gif|jpg|png)$ {E} # \是转义字符，$表示以某字符结尾
# 请求/user/2.gif,首先查找前缀字符，找到最长匹配C，继续查找正则表达，找到匹配E，则执行E
```
## location @的用法

- 前面我们看到了`location` 有2种表达的方式，`location @`用来内部重定向，不能用来处理正常的请求；
- 用法：
  ```
  location / {
      try_files $url $url/ @inside # 当尝试访问url url/时，找不到对应的文件，则重定向到@inside
  }
  location @inside {
      ........
  }
  ```
  
## location扩展
- 临时跳转
  - 临时需要将原有的url跳转到新的url，可以使用精确匹配，并将其放置在其他location之前
  - `location /admin {return 302 http://newurl/;}`
- 访问控制
  - 有一些目录为了安全，我们想限制访问，仅允许某些ip地址访问，如需使用此功能，nginx需要安装ngx_http_stus_status_module模块
  ```
  location /admin {
      stub_status; # 开启ngx_http_stub_status_module模块；
      allow 127.0.0.1;
      allow ip1;
      allow ip2;
      deny all;
      
  }
  ```
- 列出目录
  ```
  location ^~ /filesys {
      autoindex on; # 开启目录索引
      autoindex_exact_size off; # 默认为on，显示文件的确切大小，单位为byte；
      # 改为off后，显示文件的大概大小，单位为kb、MB、GB
      autoindex_localtime on; # 默认为off，显示的文件时间为GMT时间；
      # 改为on后，显示的文件时间为文件服务器的时间
  }
  ```

## 参考
1. <https://segmentfault.com/a/1190000013267839> 
2. <https://segmentfault.com/a/1190000013980557> 
