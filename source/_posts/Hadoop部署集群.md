---
title: Hadoop部署集群
date: 2019-07-28 15:33:34
categories: 
 - Hadoop
tags:
  - hadoop
  - cluster
randnum: hadoop_cluster_setup
---
## 架构

- h-master
  - role:NameNode/JobTracker
  - ip:192.168.0.210
  - app:hadoop/jdk
  - jobs:主节点，总管分布式数据和分解任务的执行;主节点负责调度构成一个作业的所有任务
- h-slave
  - role:DataNode/Tasktracker
  - ip:192.168.0.211
  - app:hadoop/jdk
  - jobs:从节点，负责分布式数据存储以及任务的执行;从节点负责由主节点指派的任务
- mapreduce框架
  - 主节点JobTracker
  - 每个从节点TaskTracker
  
<!--more-->

## 安装步骤

### 配置h-master无密码ssh登录h-slave

```
ssh-keygen -t rsa -b 2048
ssh-copy-id hadoop@h-slave
ssh hadoop@h-slave
```

### 安装Java环境

- 安装JDK(All Servers)
```
<!--install_java.sh-->
#!/bin/bash
# env
java_env=java.env
# install jdk8
rpm -ivh jdk-8u221-linux-x64.rpm
# configure java env
cp /etc/profile /etc/profile.old
cat ${java_env} >> /etc/profile.old
# source profile
source /etc/profile
# show java version
java -version
<!--java.env-->
export JAVA_HOME=/usr/java/jdk1.8.0_221-amd64
export PATH=${PATH}:${JAVA_HOME}
```

### 安装Hadoop(All Servers)

#### h-master服务器

- 安装和配置

```
<!--install_hadoop.sh-->
#!/bin/bash
# env
hadoop_dir=/opt/hadoop-3.1.2
pwd_dir=$(echo `pwd`)
host_name=$(echo 'hostname')
# install hadoop
tar -xzvf hadoop-3.1.2.tar.gz -C /opt
# create group and user
groupadd hadoop
useradd -g hadoop hadoop
passwd hadoop
# change owner of hadoop_dir
chown -R hadoop:hadoop ${hadoop_dir}
# source profile
cp /etc/profile /etc/profile.add
cat hadoop.env >> /etc/profile
source /etc/profile
# set firewall rule
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.210" port port="9000" protocol="tcp" accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.210" port port="9870" protocol="tcp" accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port="8088" protocol="tcp" accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port="10020" protocol="tcp" accept' --permanent
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port port="19888" protocol="tcp" accept' --permanent
firewall-cmd --reload
# configure hadoop
mkdir /opt/hadoop-3.1.2/hdfs/namenode
## configure xml file
mv ${hadoop_dir}/etc/hadoop/core-site.xml ${hadoop_dir}/etc/hadoop/core-site.xml.old
mv ${hadoop_dir}/etc/hadoop/hdfs-site.xml ${hadoop_dir}/etc/hadoop/hdfs-site.xml.old
mv ${hadoop_dir}/etc/hadoop/mapred-site.xml ${hadoop_dir}/etc/hadoop/mapred-site.xml.old
mv ${hadoop_dir}/etc/hadoop/yarn-site.xml ${hadoop_dir}/etc/hadoop/yarn-site.xml.old
cp core-site-master.xml ${hadoop_dir}/etc/hadoop/core-site.xml
cp hdfs-site-master.xml ${hadoop_dir}/etc/hadoop/hdfs-site.xml
cp mapred-site-master.xml ${hadoop_dir}/etc/hadoop/mapred-site.xml
cp yarn-site-master.xml ${hadoop_dir}/etc/hadoop/yarn-site.xml
## configure workers 
cd ${hadoop_dir}/etc/hadoop && cp workers workser.old
sed -i '1d' workers
echo "h-slave" > workers
chown -R hadoop:hadoop ${hadoop_dir}
# configure hadoop_env.sh
echo "export JAVA_HOME=/usr/java/jdk1.8.0_221-amd64" >> ${hadoop_dir}/etc/hadoop/hadoop_env.sh
<!--hadoop.env-->
export HADOOP_HOME=/opt/hadoop-3.1.2
export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
<!--core-site-master.xml-->
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://h-mster:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>file:/home/hadoop/tmp</value>
  </property>
</configuration>
<!--hdfs-site-master.xml-->
<configuration>
  <property>
    <name>dfs.name.dir</name>
    <value>/opt/hadoop-3.1.2/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>/opt/hadoop-3.1.2/hdfs/data</value>
  </property>
</configuration>
<!--mapred-site-master.xml-->
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapred.job.tracker</name>
    <value>http://h-master:9001</value>
  </property>
</configuration>
<!--yarn-site-master.xml-->
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapred.job.tracker</name>
    <value>http://h-master:9001</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>h-master:10020</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>h-master:19888</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.intermediate-done-dir</name>
    <value>/home/hadoop/history/tmp</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.done-dir</name>
    <value>/home/hadoop/history/done</value>
  </property>
</configuration>
```
- 启动
```
# format hdfs on first start
su hadoop
hdfs namenode -format
# start
cd /opt/hadoop-3.1.2/sbin && ./start-all.sh
# start jobhistory
mapred --daemon start jobhistory
# show runing info
jps
```
- 注意
如果ssh端口不是默认的22，需要在文件`hadoop_env.sh`中修改，具体的位置是`HADOOP_SSH_OPTS="-p 9022"`
![HADOOP_SSH_OPTS](https://s2.ax1x.com/2019/07/28/elYANF.png)

#### h-slave服务器

- 在主服务器中复制hadoop安装目录到slave
- 删除workers文件中的内容
- 配置环境变量
- 在hadoop_env.sh文件中添加java环境变量

#### Web UI

- Yarn WebUI http://h-master:8088
![yarn_ui](https://s2.ax1x.com/2019/07/28/elK8ht.png)
- NameNode WebUI http://h-master:9870
![NameNode](https://s2.ax1x.com/2019/07/28/ellS6f.png)
- JobHistory WebUI http://h-master:19888
![JobHistory](https://s2.ax1x.com/2019/07/28/el878A.png)

## 参考

1. [Hadoop多节点集群的构建](https://blog.csdn.net/lysc_forever/article/details/52033508)
2. [hadoop分布式集群搭建](http://www.ityouknow.com/hadoop/2017/07/24/hadoop-cluster-setup.html)
3. [How to Install and Set Up a 3-Node Hadoop Cluster](https://www.linode.com/docs/databases/hadoop/how-to-install-and-set-up-hadoop-cluster/)
4. [Hadoop Cluster Setup](https://hadoop.apache.org/docs/r3.1.2/hadoop-project-dist/hadoop-common/ClusterSetup.html#Web_Interfaces)
