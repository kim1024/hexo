---
title: HAProxy基础学习笔记
date: 2018-11-05 11:53:00
categories: 
 - HA
tags:
  - HAProxy
  - 学习笔记
randnum: haproxy-doc
---

# HAProxy代理软件基础学习笔记

## 基础知识

- HAProxy是使用C语言编写的，提供负载均衡，以及基于TCP和HTTP的应用程序代理。它支持Client-HAProxy，HAProxy-Server的全程SSL链接；
- HAProxy采用单线程事件驱动型非阻塞引擎，支持较大的并发数链接，具有较高的性能和稳定性；*多线程或多进程受内存、系统调度、锁的限制，很少能处理数千并发链接。事件驱动型因为有更好的资源和事件管理的用户空间实现所有任务，所以可以处理较大并发数链接。* <sup>1</sup> 
- HAProxy适用于负载大的Web站点，支持数以万计的并发连接，它的运行模式可以简单安全的整合到当前的架构中，使Web服务器不被暴露到网络中；
- HAProxy还提供基于Web的统计信息页面，用于展现健康状态和数据流量；
- HAProxy常见的架构形式如下：<sup>2</sup> 
   ![HAProxy Proxy](https://s1.ax1x.com/2018/11/04/i5hZKe.png) 

<!--more-->

## 核心功能

- 负载均衡
  - 提供2种负载均衡模式：TCP伪四层和HTTP七层
- 健康检查
  - 支持TCP和HTTP两种健康检查模式
- 会话保持
  - 对尉氏县会话共享的应用集群，可以通过Insert\Reweite\Prefix Cookie多种Hash方式实现会话保持
- SSL
  - 可以解析HTTPS协议，并能够将请求解密为HTTP后后端传输
- 监控与统计
  - 提供基于Web的统计信息页面



## 安装

- 下载HAProxy压缩包，版本号是1.8.14

  - 下载地址：<https://www.haproxy.org>

- 将下载的压缩包上传到服务器中,解压 <sup>3</sup> 

  ```bash
  tar -xzvf haproxy-1.8.14.tar.gz
  cd haproxy-1.8.14
  uname -r # 获取系统内核版本信息
  make TARGET=linux310 ARCH=x86_64 PREFIX=/usr/local/haproxy -j 20
  # TRAGET 指定操作系统内核版本 ；ARCH 指定操作系统位数； PREFIX指定安装路径;使用参数-j 可以指定用于编译的线程数目
  make install
  ```

- 完成安装

  [![make install haproxy](https://s1.ax1x.com/2018/11/05/iIQFxJ.md.png) ](https://imgchr.com/i/iIQFxJ) 

- 准备配置文件

  ```
  cd /usr/local/haproxy
  mkdir conf
  cd conf
  touch haproxy.cfg  # haproxy的配置文件
  user add -r -s /bin/nologin haproxy
  ```

- 准备启动脚本

  ```
  cd ~/haproxy-1.8.14/example
  cp haproxy.init /etc/init.d/haproxy
  chmod  +x haproxy
  vi haproxy
  # 分别修改HAProxy配置文件目录和sbin目录
  HAP_HOME=/usr/local/haproxy
  BIN=${HAP_HOME}/sbin
  CFG=${HAP_HOME}/conf/${BASENAME}.cfg
  # 如果出现“第26行，期待一元表达式”的提示信息，修改NETWORK字段
  [ ${NETWORKING}x = "no"x ] && exit 0
  ```




## 配置

- 配置文件分为2大段：全局配置(Global),代理配置(Proxies)

### 全局配置

- 全局配置建议不做修改，包含的字段有：
  1. 进程与安全配置相关的参数；
  2. 性能配置参数；
  3. Debug配置参数；
  4. 用户列表参数；
  5. peers参数；
  6. Mailers参数

### 代理配置

- 代理配置又分为3部分，分别是defaults,frontend,backend,listen。
  - defaults
    - 默认参数的配置，在该部分内配置的参数，会被自动引用到之后的frontend，backend，listen，某些参数属于公用的配置，既可以在defaults中配置，也可以在frontend，backend，listen中配置，两者都配置的以后者为准，defaults中的配置会被覆盖；
  - frontend
    - 负责配置接受用户请求的虚拟前段节点，类似于nginx配置文件中的server{}字段；
  - backend
    - 负责配置集群后端服务器集群的配置，用来定义一组真实服务器，用来处理用户发出的请求，类似于nginx配置中的upstream{}字段；
  - listen
    - 用来配置前段和haproxy后端

### 配置文件<sup>5</sup> <sup>6</sup> 

- 配置日志文件

  ```
  cd /etc/ && cp rsyslog.conf rsyslog.conf.old
  vi  rsyslog.conf
  # Provides UDP syslog reception
  $ModLoad imudp
  $UDPServerRun 514 ------>启动udp，启动端口后将作为服务器工作
  # Provides TCP syslog reception
  $ModLoad imtcp
  $InputTCPServerRun 514 ------>启动tcp监听端口
  local2.* /var/log/haproxy.log
  
  ```

- haproxy配置文件

```
global
   log 127.0.0.1 local0  # 全局日志文件配置条目，最多可定义2个
   log 127.0.0.1 local2 notice
   chroot /var/lib/haproxy # 切换根目录，将haproxy运行在/var/lib/haproxy，增加其安全性，注意该目录的权限和所属用户。
   # stats socket /run/haproxy/admin.sock mode 660 level admin
   # stats timeout 30s
   user haproxy # 指定运行用户和组
   group haproxy
   daemon # 设定haproxy以后台方式运行
   maxconn 40000 #设定前段的最大连接数，不能用户backend，默认为2000
   # HAProxy会为每个连接维持2个缓冲，每个缓冲的大小为8kb，再加上其他数据，每个连接大约占17kb RAM，这就意味着1GB的RAM可以维持40000-50000的并发连接
   # maxsslconn # 设定每个进程所能接受的ssl最大并发连接数

defaults
   log global  # 继承全局日志
   mode http  # 设置haproxy默认的运行模式，默认为http，支持tcp、http，tcp常用于ssl\ssh\smtp等服务
   option httplog
   option dontlognull # 不记录上级负载均衡发送的用于检测状态的心跳包
   option http-server-close # 客户端与服务器在完成一次请求后，hap会主动关闭该tcp连接，有助于提供性能
   option forwardfor except 127.0.0.0/8 # 由于hap工作在反向代理方向，后端集群中的服务器可能无法获取发送请求的真实ip，使用forwardfor可以在报文中分装新的字段记录请求段ip，使用except排除本地的ip地址
   option redispatch # 是否允许在session失败后重新分配
   retries 3 # 连接后端服务器失败重试次数，超出该数，hap会将对应的后端服务器设置为不可用状态
   timeout http-request 10s # 
   timeout connect 10s # 成功连接到一台服务器的最长等待时间，默认为毫秒，可以换用其他单位
   timeout queue 10s # 等待最大时长
   timeout client 10s # 连接客户端发送数据的最长等待时间，默认为毫秒
   timeout server 10s # 服务器端回应客户端数据放的最长等待时间
   timeout check 10s # 设置对后端服务器的检测超时时间
   maxconn 3000 # 每个server最大连接数

frontend main
   bind :80,:443 # 同时监听2个端口，之间不能有空格，监听端口要重启服务
   # bind 192.168.0.93:8080 
   mode http
   # sats uri /haproxy?stats
   # dfault_backend http_back
   default_bakcend webserver

backend webserver
   balance roundrobin # 后端集群服务器组内的调度算法，roundrobin轮循，依次访问每个后端服务器
   server webserver 192.168.0.91:80 check  # webserver为服务器在haproxy中的内部名称，主要出现在日志和警告中
   server webserver 192.168.0.92:80 check  # ip地址可以使用主机名替代
   server backserver 192.168.0.90:80 check backup 设定当前服务器为备用服务器，check表示对当前server做健康状态检查，默认是tcp检测
   # disable标记为不可用
   #redir <prefix> 将发往该服务器的请求重定向到指定的url
   #cookie <value>为当前server指定其cookie，用于实现基于cookie的会话黏性
   # server options: weight 支持配置权重
   # weight默认为1，最大为256,0表示不参与负载均衡，不被调度
   # 动态算法：支持权重的运行时调整，支持慢启动，每个后端中最多支持4095个server
   # static-rr 静态算法，不支持权重运行时调整及慢启动，后端主机数量无上限
   server webserver 192.168.0.93:80 check weight 3 # 加权轮询，权重为3，未设置的权重默认为1
   server webserver 192.168.0.94:80 check 
   
   listen hap_page
     mode http
     bind *:8081
     option httplog # 采用http日志格式
     stats refresh 30s # 统计页面自动刷新时间
     stats uri  /hap?stats # 统计页面url地址
     stats realm HAProxy Manage Page # 弹出用户名密码对话框的提示文本
     stats auth root:haproxy # 设置登录统计页面的用户名密码
     stats hide-version # 隐藏统计页面上的HAProxy版本信息
     stats admin if TRUE # 如果任何通过就做管理功能，可以管理后端服务器
 
```
- 配置文件部分参数
  - ACL
    - ACL用于实现基于请求报文的首部、响应保温的内容或其他的环境状态信息来做出转发决策。配置的步骤分为2步，首先定义1个ACL，而后在满足ACL的情况下执行特定的动作。
    - ACL语法格式：
      - `acl <aclname> <criterion> [flags] [operator] <value>`
        - aclname区分大小写
        - criterion测试标准
          - be_sess_rate用于测试指定的backend上会话常见的速率是否满足指定的条件，常用于在指定backend上的会话速率过高时将用户请求转发至另外的backend，或用于阻止攻击行为
            - `acl being_scanned be_sess_rate gt 50` # 定义一个acl
            - `redirect location /error_pages/ednied.html if being_scanned` # 指定满足acl条件，执行的操作
          - fe_sess_rate用户测试指定的frontend或当前frontend的会话创建速率是否满足指定的条件
          - hdr\<string\> 用于测试请求报文中的所有首部或指定首部满足指定的条件。指定首部时，名称不分区大小写，且字符内不能有任何多于的空白字符
          - method\<string\>用于测试http请求报文中使用的方法
          - path_beg \<string\>用于测试请求的url是否以指定的模式开头
            - `acl url_static path_beg -i /static /css /images /js` # 测试url中是否以这些字段开头
          - path_end \<string\> 用于测试请求的url是否以指定的模式结尾
            - `acl url_static path_end -i .jpg .png .css .js`
          - hdr_beg \<string\> 用于测试请求的报文的指定首部的开头部分是否符合指定的模式
          - hdr_end\<string\>
        - flage
          - -i 不区分中模式字符的大小写
          - -f 从指定的文件中加载模式
          - -- 标识符的强制结束标记
        - value
          - 整数或整数范围
          - 字符串，支持使用-i忽略大小写，使用\转义字符
          - 正则表达式
          - ip地址及网络地址
  - server参数
    - 语法格式`server <name> <address>[:port] [param*]`
      - name: 服务器内部名称
      - address: 服务器的ip地址，也可以使用主机名
      - port: 连接请求发往服务器时的目标端口，未指定时，使用客户端请求时的端口
      - param服务器设定的参数
        - backup: 设定为备用服务器
        - check: 启动对服务器的健康检查
        - inter \<delay\> :设定健康状态检查的时间间隔，单位为毫秒，默认为2000
        - rise \<count\> : 设定健康状态检查中，某离线的server从离线状态转换至正常状态需要成功检查的次数
        - fall \<count\>: 去人server从正常状态转为不可用状态需要检查的次数



### 错误提示

![期待一元表达式错误提示](https://s1.ax1x.com/2018/11/05/iIty5R.png)



### 统计页面

![HAProxy 认证信息](https://s1.ax1x.com/2018/11/05/iINNod.png)

![HAProxy Web页面](https://s1.ax1x.com/2018/11/05/iINtdH.png)

## 参考
1. <http://blog.51cto.com/11010461/2139872>
2. <https://www.haproxy.org> 
3. <http://blog.51cto.com/11010461/2139872> 
4. <https://cbonte.github.io/haproxy-dconv/1.8/configuration.html> 
5. <https://www.unixmen.com/installing-haproxy-for-load-balancing-on-centos-7/>
6. <https://www.cnblogs.com/pangguoping/p/7647091.html> 
7. <http://www.ttlsa.com/linux/haproxy-study-tutorial/>


