---
title: MHA在线主从切换
date: 2018-11-20 17:16:22
categories: 
 - MHA
tags:
  - MHA
  - 故障转移
  - 主从切换
randnum: mha-m2s
---


## 切换过程

  1. 检测复制设置和确定当前的主服务器;
  2. 确定新的主服务器;
  3. 阻塞写入到当前的主服务器;
  4. 等待所有从服务器同步完成;
  5. 授予写入到新的主服务器
  6. 重新设置从服务器
  
  
<!--more-->
## 操作过程
  - 把主服务器从centos2切换到centos
  1. 停止MHA监控
    `masterha_stop --conf=/etc/masterha/app1.cnf`
  2. 将centos服务器加入到app1.cnf配置文件中
     ```
     [server3]
     hostname=centos
     ```
  3. 在centos中配置主从复制，将数据与centos2中的数据保持一致
  4. 删除文件`rm -f /var/log/masterha/app1/mha.failover.complete saved_master_binlog_from_*.binlog`
  5. 在线切换
    ```
    masterha_master_switch --conf=/etc/masterha/app1.cnf \
    --master_state=alive \
    --new_master_host=centos \
    --orig_master_is_new_slave --running_updates_limit=10000
    ```
    - 首次切换时，会有一个错误提示,需要将`master_ip_online_change`152行中的`FIXME_xxx_drop_app_user($orig_master_handler);`注释掉
      `Got Error: Undefined subroutine &main::FIXME_xxx_drop_app_user called at /usr/local/bin/master_ip_online_change line 152.
      ![error-fixme](https://s1.ax1x.com/2018/11/20/F9PEcV.png)
`
    ![switch-master](https://s1.ax1x.com/2018/11/20/F9C2f1.png)
  6. 检查服务器的Mysql状态
    - centos的slave hosts
      ![centos-slave-hosts](https://s1.ax1x.com/2018/11/20/F9i35j.png)
    - centos2的slave status
      ![centos2-slave-status](https://s1.ax1x.com/2018/11/20/F9itx0.png)