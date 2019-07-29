---
title: Hive部署单节点过程
date: 2019-07-27 15:00:50
categories: 
 - hive
 - hadoop
tags:
  - hive
  - hadoop
randnum: hadoop_hive_mysql
---
# Hive部署单节点过程

![webui](https://s2.ax1x.com/2019/07/27/eK4Q6P.png)

## 基础环境

### 安装JDK8

- 安装jdk8
`sudo rpm -ivh jdk-8u221-linux-x64.rpm`
- 配置环境变量
```
su
vi /etc/profile
# add
JAVA_HOME=/usr/java/jdk1.8.0_221-amd64
. /etc/profile
java -version
```
<!--more-->

## 安装Hadoop

- 下载hadoop
`wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz`
- 解压
`tar -xzvf hadoop-3.1.2.tar.gz`
- 移动文件
`sudo mv hadoop-3.1.2 /opt `
- 创建用户和组
`sudo groupadd hadoop && sudo useradd -g hadoop hadoop && sudo passwd hadoop`
- 修改权限
```
cd /opt
su
chown -R hadoop:hadoop hadoop-3.1.2
```
- 配置用户环境变量
```
su hadoop
cd ~
vi .bash_profile
# add
## JAVA env variables
export JAVA_HOME=/usr/java/jdk1.8.0_221-amd64
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar

## HADOOP env variables
export HADOOP_HOME=/opt/hadoop-3.1.2
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
```
- 测试hadoop是否安装成功
`hadoop dfs -ls`

## 安装Hive

- 下载hive
`wget http://mirror.bit.edu.cn/apache/hive/hive-2.3.5/apache-hive-2.3.5-bin.tar.gz`
- 解压
`sudo tar -xzvf apache-hive-2.3.5-bin.tar.gz /opt`
- 修改用户和组
`cd /opt && sudo mv apache-hive-2.3.5-bin/ hive-2.3.5 && sudo chown -R hadoop:hadoopp hive-2.3.5`
- 添加环境变量
```
su hadoop
cd ~
vi .bash_profile
# add
## Hive
export HIVE_HOME=/opt/hive-2.3.5
export PATH=$HIVE_HOME/bin:$PATH
```
- 测试hive是否安装成功
`hive`

## 配置单节点模式

- 安装mysql-connector-java
`sudo yum install mysql-connector-java -y`
- 复制文件
`sudo cp /usr/share/java/mysql-connector-java.jar /opt/hive-2.3.5/lib && cd /opt/hive-2.3.5/lib && sudo chown hadoop:hadoop mysql-connector-java.jar`
- 编辑hive-site.xml,如果没有，需要创建文件
```
su hadoop
cd /opt/hive-2.3.5/conf && touch hive-site.xml
# add
<configuration>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/home/hadoop/hive/warehouse</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://mysql-master/hive_db</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>dba</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>passwd</value>
  </property>
  <property>
    <name>hive.querylog.location</name>
    <value>/home/hadoop/hive/log</value>
  </property>
<!--enable webui-->
  <property>
    <name>hive.server2.webui.host</name>
    <value>hive</value>
  </property>
  <property>
    <name>hive.server2.webui.port</name>
    <value>10002</value>
  </property>
  <property>
    <name>hive.scratch.dir.permission</name>
    <value>755</value>
  </property>
</configuration>
</configuration>
```
- 配置mysql数据库
```
create database hive_db character set utf8;
grant all on hive_db.* to 'dba'@'hive' identified by 'passwd';
flush privileges;
```
- 初始化hive数据库
`schematool --dbType mysql --initSchema`
- 在hive中可以使用hadoop命令
`dfs -ls / ;`
- 在hive中可以执行简单的bash shell命令
`! pwd ;`
- hive的历史命令存放在`~/.hivehistory`
- 启动hiveserver2服务
`hive --service hiveserver2 & > /dev/null`
- 打开webui
`http://hive:10002/hiveserver2.jsp`

## 参考

1. [Hadoop: Setting up a Single Node Cluster.](https://hadoop.apache.org/docs/r3.2.0/hadoop-project-dist/hadoop-common/SingleCluster.html)
