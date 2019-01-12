---
title: Mysql高可用架构之keepalived and MHA
date: 2018-11-20 10:36:41
categories: 
 - Mysql
 - 高可用
tags:
  - Mysql
  - keepalived
  - MHA
  - 集群
randnum: mysql-keepalived-mha
---

## MHA介绍
- MHA目前在mysql高可用方面是一个相对成熟的解决方案，它由日本DeNA公司youshimaton开发，是一套优秀的作为MySQL高可用性环境下故障切换和主从提升的高可用软件。在MySQL故障切换过程中，MHA能做到在0~30秒之内自动完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA能在最大程度上保证数据的一致性，以达到真正意义上的高可用。
- MHA由2部分组成：MHA Manager、MHA Node
  - MHA Manager是单独部署在一台独立的机器上用来管理多个master-slave集群，也可以部署在一个slave结点上。MHA Manager定期探测集群中的master结点，当master出现故障，它可以自动将最新数据的slave提升为新的master，然后将其他slave重新指向新的master;
  
<!--more-->
  - MHA Manager工具
    1. masterha_check_ssh 检查MHA的ssh配置状况
    2. masterha_chck_repl 检查mysql复制状况
    3. masterha_manger    启动MHA
    4. masterha_chck_status    检查当前MHA运行状态
    5. masterha_master_monitor 检查master是否宕机
    6. masterha_master_switch  控制故障转移(自动or手动)
    7. masterha_conf_hosot     添加或删除配置的server信息
  - MHA Node运行在每台Mysql服务器上;
- MHA支持一主多从，要求至少3台数据服务器，1台master，1台备用master，1台从;
  - MHA Node工具
    1. save_binary_logs      保存和复制master的二进制日志
    2. apply_diff_relay_log  识别差异的中继日志时间并将其差异的事件应用到其他slave
    3. filter_mysqlbinlog    除去不必要的rollback事件*MHA不再使用该工具*
    4. purge_relay_logs      清除中继日志(不会阻塞SQL线程)
- MHA工作步骤
  1. 从宕机的master保存二进制日志事件;
  2. 识别含有最新更新的slave;
  3. 应用差异的中继日至到其他slave;
  4. 应用从master保存的二进制日志事件;
  5. 提升一个slave为新的master;
  6. 使其他的slave连接到新的master进行复制;
  
- **为了检查服务器硬件损坏宕机造成数据丢失，在配置MHA时建议配置Mysql半同步主从复制**

## 部署MHA

### 环境

- Master 
  - centos1 192.168.0.81 server-id:81 write
  - MHA-Node
- Master Back
  - centos2 192.168.0.82 server-id:82 read-only
  - MHA-Node
- Slave
  - centos3 192.168.0.83 server-id:83 read-only
  - MHA-Node
- Monitor host 
  - centos4 192.168.0.84  server-id:null monitor
  - MHA-Manager
  
### 安装

- perl-DBD-MySQL
  - `yum install perl-DBD-MySQL -y`
- MHA-Node,所有的结点都需要安装MHA-node

  1. 下载MHA-Node，执行安装命令`rpm -ivh mha4mysql-node-0.54-1.el5.noarch.rpm`
- MHA-Manager
  1. 安装依赖程序
     - `yum install perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager -y`
  2. 安装MHA-Manager
     - `rpm -ivh mha4mysql-manager-0.55-1.el5.noarch.rpm`
  3. 安装附加脚本文件
     - `cp mha-source/samples/scripts/* /usr/local/bin/`
     
- 配置服务器ssh登陆

  1. 不能禁用密码登陆，否则会出错
  2. 执行`ssh-add`时报错：`Could not open a connection to your authentication agent`,先执行`ssh-agent bash`命令，再执行`ssh-add`命令
  3. `ssh-keygen -t rsa`生成密钥对，复制`id_rsa.pub`为`authorized_keys`,将生成的公钥复制到其他服务器`ssh-copy-id [centos2/3/4]`,其他服务器中执行相同的操作
  
- 配置Mysql数据库主从复制

  - 配置过程参考文章：[Mysql配置异步同步主从复制](https://kim1024.github.io/2018/11/02/Mysql%E6%95%B0%E6%8D%AE%E5%BA%93%E9%85%8D%E7%BD%AE%E5%BC%82%E6%AD%A5%E5%90%8C%E6%AD%A5%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6/)
  - 在centos2\3上设置数据库为只读，在数据库中设置，未将该设置添加到mysql配置文件中，在mysql中执行命令`set global read_only = 1;`
  - 在centos2\3上设置relay log的清除方式`set global relay_log_purge = 0;`
    - MHA在切换过程中，从苦的恢复过程依赖于relay log的相关信息，设置relay log 为off状态，采用手动清除的方式，创建脚本文件，并将脚本文件添加到crontab中定期执行，脚本文件`purge_relay_log.sh`
    ```
    #!/bin/bash
    user=root
    password=mysql_root_passwd
    port=3306
    log_dir='/var/log/masterha/log'
    work_dir=`home/user/mysql/`
    purge='/usr/local/bin/purge_relay_logs'
    if [ ! -d ${log_dir} ]
    then
       mkdir ${log_dir} -p
    fi
    ${purge} --user=${user} --password=${passwd} --disable_relay_log_purge --port=${port} --workdir=${work_dir} >> ${log_dir}/purge_relay_logs.log 2>&1
    
    ```
    
     
### 配置

- 创建配置文件目录`mkdir -p /etc/masterha`
- 创建配置文件`cd /etc/masterha && touch app1.cnf`

```
[server default]
# 设置mha-manager工作目录
manager_workdir=/var/log/masterha/app1
# 设置mha-manager日志目录
manager_log=/var/log/masterha/app1/app1.log
# 设置master保存二进制日志事件的位置,便于mha找到
master_binlog_dir=/var/lib/mysql
# 设置自动failover的切换脚本，需要提前安装
master_ip_failover_script=/usr/local/bin/master_ip_failover
# 设置手动切换的脚本
master_ip_online_change_script=/usr/local/bin/master_ip_online_change
# 设置Mysql用户密码
user=root
password=mysql_root_passwd
# 监控主库，发送ping包的间隔，默认3s，尝试3次没有回应自动railover
ping_interval=1
# 设置远程mysql发生切换时二进制日志事件保存位置
remote_workdir=/tmp
# 设置数据库主从复制的用户密码
repl_user=slave_db
repl_password=slave_password
# 设置发生切换后发送的报警脚本
report_script=/usr/local/bin/send_report
secondary_check_script=/usr/local/bin/master_secondary_check -s centos2 -s centos3
# 设置故障发生后关闭故障主机的脚本，作用是防止发生脑裂
# shutdown-script=""
# 设置ssh登陆的用户名,使用普通用户在检查复制时会报错
ssh_user=root

[server1]
# Master服务器
hostname=centos1
# port=3306

[server2]
# 备用Master服务器
hostname=centos2
# port=3306
# 设置为候选Master，如果设置了该参数，Master发生故障后，将该服务器提升为Master，无论该服务器是否是最新的Slave
candidate_master=1
# 默认情况下，如果一个slave落后master 100M的relay logs,MHA将不会选择该slave作为新master;通过设置该参数值为0，MHA在出发切换mster主机时，会忽略复制延时，该参数对设置了candidate_master=1的主机非常有用
check_repl_delay=0

[server3]
hostname=centos3
# port=3306

```
- 在mha中引入keepalived，修改vip漂移脚本文件`master_ip_failover`,在该脚本中添加Master宕机后MHA对keepalived的处理`vi /usr/local/bin/master_ip_failover`添加以下内容 <sup>4</sup>
  ```
  my $vip = '192.168.0.110'; # vip地址
  my $ssh_start_vip ="systemctl start keepalived";
  my $ssh_stop_vip ="systemctl stop keepalived";
  ```
  
- 修改脚本文件`master_ip_online`,添加以下内容
  ```
  my $vip = '192.168.0.110/32'; # vip地址
  my $key = '1';
  my $ssh_start_vip = "systemctl start keepalived";
  my $ssh_stop_vip = "systemctl stop keepalived";
  my $orig_master_ssh_port = 22;
  my $new_master_ssh_port = 22;
  ```
  
- 修改脚本文件`send_report`,添加以下内容
  ```
  my $smtp='smtp.xxx.com';
  my $mail_from='send@xx.com';
  my $mail_user='send_user@xx.com';
  my $mail_pass='Password';
  my$mail_to=['mail1@xx.com','mail2@xx.com'];
  ```
- 检查MHA-Manager到所有结点的ssh连接状态,使用命令`masterha_check_ssh --conf=/etc/masterha/app1.cnf`
  - 执行命令后会有一个报错`Can't locate MHA/SSHCheck.pm in @INC (@INC contains: /usr/local/lib64/perl5 /usr/local/share/perl5 /usr/lib64/perl5/vendor_perl /usr/share/perl5/vendor_perl /usr/lib64/perl5 /usr/share/perl5 .) at /usr/bin/masterha_check_ssh line 25.`,解决方法是在所有的服务器中做一个软连接`ln -s /usr/lib/perl5/vendor_perl/MHA /usr/lib64/perl5/vendor_perl/`
  
### 检查

- 检查masterha的ssh无密码验证`masterha_check_ssh --conf=/etc/masterha/app1.cnf`
  ![masterha_check_ssh](https://s1.ax1x.com/2018/11/19/FS4Faj.png)
- 检查masterha的复制环境`masterha_check_repl`，在`app1.cnf`配置文件中，如果`ssh_user`使用的是普通用户，在服务器中，普通用户无权访问mysql的二进制日志bin_log,relay_log,mha工作目录，会提示以下错误
  `[error][/usr/lib64/perl5/vendor_perl/MHA/MasterMonitor.pm, ln386] Error happend on checking configurations. SSH Configuration Check Failed!
 at /usr/lib64/perl5/vendor_perl/MHA/MasterMonitor.pm line 341.`
- 检查Mysql主从复制`masterha_check_repl --conf=/etc/masterha/app1.cnf`,出现`ok`字样，表明检查通过
  ![check_repl](https://s1.ax1x.com/2018/11/20/Fp29gO.png)
- 在管理服务器中后台启动MHA监控`nohup masterha_manager --conf=/etc/masterha/app1.cnf --remove_dead_master_conf --ignore_last_failover < /dev/null > /var/log/masterha/app1/app1.log 2>&1 &`
 - `--remove_dead_master_conf` 该参数代表当发生主从切换后，老的主库的ip将会从配置文件中移除
 - `--manager_log` 日志存放位置
 - `--ignore_last_failover` 在缺省情况下，如果mha检测到连续发生宕机，且2次宕机的事件不足8小时，则不会进行failover。该参数代表忽略上次mha触发切换产生的文件
- 查看mha的运行状态`masterha_check_status`,可以看到mha运行中，Master服务器为centos
  ![check_status](https://s1.ax1x.com/2018/11/20/Fp2KxS.png)
- 关闭mha监控`masterha_stop --conf=/etc/masterha/app1.cnf`

## 测试

- 使用`sysbench`对Mysql数据库进行插入测试，执行以下命令
  ```
  sysbench \
	--mysql-user=root --mysql-password=mysql_root_passwd --db-driver=mysql \
	--mysql-socket=/var/lib/mysql/mysql.sock --mysql-db=test1120 --range-size=100 \
	--table-size=2000 --tables=20 --threads=2 --time=60 \
	--rand-type=uniform /usr/share/doc/sysbench/oltp_insert.lua prepare
  ```
- 停掉Backup服务器中的slave sql线程，模拟主从延时
- 停掉Master服务器中的Mysqld，模拟Master宕机,Master切换到centos2，vip漂移到centos2,slave指向centos2,centos2中的slave指向被清空，mha manager进程会停掉，在配置文件中，关于server1的信息被删除
  ![test_failover](https://s1.ax1x.com/2018/11/20/FpbCxs.png)
  
## 参考

1. <https://www.cnblogs.com/gomysql/p/3675429.html>
2. <https://github.com/yoshinorim/mha4mysql-manager/wiki/Installation>
3. <https://rpmfind.net/linux/RPM/index.html>
4. <http://www.voidcn.com/article/p-fsekcbpa-mt.html>



