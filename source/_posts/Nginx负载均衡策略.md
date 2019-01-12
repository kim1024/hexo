---
title: Nginx负载均衡策略
date: 2018-11-01 10:47:35
categories: 
 - Nginx
 - 负载均衡
tags:
  - Nginx
  - 负载均衡
  - 学习笔记 
randnum: nginx-ha
---

# Nginx负载均衡策略

## 概要

- Nginx工作在OSI的第七层，可以这对http应用做一些分流策略；
- Nginx反向代理服务的核心主要是转发Http请求，扮演了浏览器后端和后端服务器中转的角色；
- Nginx官方测试支持5万并发连接，在实际生产环境中可以到2-3万并发数连接，1万个非活跃http keep-alive连接占用约2.5M内存。3万并发连接下，10个Nginx进程，消耗内存约150M；
- 负载均衡的目的是为了解决单个节点压力过大，导致Web服务响应慢的问题；

<!--more-->
## 内置负载策略

### 策略

- 轮循(round-robin)默认策略

  - 根据请求次数，将每个请求均匀分配到每台服务器,如果后端服务器宕机，自动剔除。

- 权重(Weight)

  - 把请求更多的分配到高配置的后端服务器上，默认每个服务器的权重都是1。

- ip_hash

  - 同一客户端的Web请求被分发到同一个后端服务器进行处理，使用该策略可以有效的避免用户Session失效的问题。该策略可以连续产生1045个互异的value，经过20次hash仍然找不到可用的机器时，算法会退化成轮循。

- 最少连接(last_conn)

  - Web请求会被转发到连接数最少的服务器上。

  ### 参数说明

  - weight
    - 启用权重策略，总数按照10进行计算，如果分配为3，则表示所有连接中的30%分配给该服务器,默认值为1；
  - max_fail/fail_time
    - 某台服务器允许请求失败的次数，超过最大数后，在fail_timeout时间内，新的请求不会分配给这台机器，如果设置为0，反向代理服务器则会将这台服务器设置为永久无效状态。fail_time默认为10秒；
  - backup
    - 将某台服务器设定为备用机，当列表中的其他服务器都不可用时，启用备用机
  - down
    - 将某台服务器设定为不可用状态
  - max_conns
    - 限制分配给某台服务器的最大连接数，超过这个数量，反向代理服务器将不会分配新的连接，默认为0，表示不限制；

  ### 代码

  ```
  http {
      upstream  server_group_name {
          # ip_hash; # 启用ip_hash策略
          # last_conn; #启用最少连接策略
          server ip or domain:port weight=2 max_fails=3 fail_timeout=15 max_conns=1000; # 使用weight设置权重为20%
          server ip or domain:port backup; # 设置为备用机，当其他服务器全部宕机时，启用备用服务器
          server ip or domain:port down; # 设置服务器为不可用状态
      }
      server {
          listen 80;
          location / {
              proxy_pass http://server_group_name;
          }
      }
  }
  ```
## 扩展策略
### 策略
- 扩展策略默认不被编译进nginx内核，如果启用该策略，需要自行编译安装

- fair

  - 根据后台服务器的响应时间判断负载情况，从中选出负载最轻的后端服务。但是在实际请款中，网络环境往往不那么简单，所以慎用。
  - 在编译安装后，如果需要启用该策略，需要在upstream标签中添加`fair;`,启用该策略后，加权轮循将失效。

- url_hash

  - 按照请求url的hash结果来分配请求，试每个url定向到同一个后端服务器，在1.7.2之后的nginx版本中，该模块应集成到内核中，不需要单独安装。
  - 启用该策略，需要在upstream标签中添加`hash $request_url;`


## 问题

- 使用Nginx的反向代理，让同一个用户的请求一定转发到同一台服务器上，这种均衡策略会消耗更多的服务器资源，也增加了代理服务器的负担；
- 使用其他策略作为负载均衡时，会出现用户Session丢失的情况，为避免出现这种情况，可以将用户的Session存放到缓存服务器中，比较常用的方案时redis/memchache；
- 反向代理服务器也可以开启缓存服务，但是开启该项服务会增加代理服务器的负担，影响整体的负载均衡效率；
- 使用Nginx反向代理布置负载均衡，操作相对金丹，但是会有“单点故障”的问题，如果后台某台服务器宕机，会带来很多的麻烦，后期如果后台服务器继续增加，反向代理服务器会成为负载均衡方案的瓶颈。

## 参考

1. <https://juejin.im/post/5821c24e570c350060bef4c3> 
2. <https://www.jianshu.com/p/ac8956f79206> 
3. https://segmentfault.com/a/1190000014483200
4. <https://www.kancloud.cn/digest/understandingnginx/202607> 
