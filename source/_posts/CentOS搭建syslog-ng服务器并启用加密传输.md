---
title: CentOS搭建syslog-ng服务器并启用加密传输
date: 2019-05-14 13:55:22
categories:
 - syslog-ng
tags:
  - syslog-ng
  - tls
randnum: install_syslog_ng_with_tls
---

## 操作步骤
 
### Server端配置syslog-ng
 
1. 安装syslog-ng
`sudo yum install epel-release -y && sudo yum install syslog-ng -y`
2. 配置syslog-ng
在syslog-ng的配置文件中，有5种不同的项目，每个项目以1个特殊关键词开头：
  - options
    - 用来调节syslog-ng的守护进程。
  - source
    - 告知syslog-ng从什么地方收集日志。source内容可以包括Unix套接字、TCP或UDP套接字、文件或管道。
  - destination
    - 用来决定syslog-ng将向哪些地方发送日志，可以指定为文件、管道、Unix套接字、TCP或UDP套接字、TTY或程序等。
  - filter
    - 结合source、destination和filter使用，选择syslog程序和日志级别。
  - log
    - 将以上关键字和log结合使用，可以精确定义消息日志保存的地方。
<!--more-->
```
cd /etc/syslog-ng && sudo cp syslog-ng.conf syslog-ng.conf.old
sudo vi syslog-ng.conf
# add
# add a log source
source s_remote {
    tcp(ip("192.168.0.104") port(20514) max-connections(500));
};
# collect log from remote host
destination d_remote {
    # write log file to hostname path,log file named by y.m.d.log
    file("var/log/syslog-ng/${HOST}/${YEAR}.${MONTH}.${DAY}.log" perm(0644));
};
# add to log
log [
    source(s_remote); 
    destination(d_remote);
};
```
3. 修改日志路径的SELinux策略
`semanage fcontext -a -t syslog-ng "/var/log/syslog-ng(/.*)?" && restorecon /var/log/syslog-ng`
4. 添加防火墙
`firewall-cmd --zone=public --add-rich-rule='rule family=ipv4 source address=192.168.0.1/24 port port=20514 protocol=tcp accept' --permanent`
5. 启动服务
`sudo systemctl start syslog-n`
6. 如果启动失败
使用命令`/usr/sbin/syslog-ng -F -p /var/run/syslogd.pid` 查看具体的错误提示

### Agent端配置syslog-ng

1. 安装
`sudo yum install epel-release -y && sudo yum install syslog-ng -y`

2. 修改配置文件
```
cd /etc/syslog-ng/ && sudo cp syslog-ng.conf syslog-ng.conf.old
sudo vi syslog-ng.conf
# add
# add a log source
source s_net {
    # tell syslog-ng read log from /dev/log;/dev/log link to /var/run/log
    unix-dgram("/dev/log");
    # if use systemctl start syslog-ng start faild,use this
    # unit-stream("/dev/log");
    # create message by internal
    internal();
};
# send log to remote syslog server
destination d_net {
    tcp("192.168.0.104" port(20514) max-connections(10));
};
# add to log
log [
    source(s_net); 
    destination(d_net);
};
```
3. 启动服务
`sudo systemctl start syslog-ng`

### 配置加密服务

为保证日志传输的安全性，为syslog-ng日志的传递设置加密服务。
使用服务器生成的公钥，对client端传送的日志文件进行加密，所有client端使用相同的公钥进行加密。
1. 在server端生成加密证书和私钥
```
# cert dir
cd /etc/syslog-ng && sudo mkdir cert && cd cert
sudo openssl -x509 -nodes -days 365 -newkey rsa:2048 -outkey syslog_pri.key -out syslog_pub.crt
```
2. 配置server的syslog-ng.conf文件
```
# destination在tcp或udp条目中添加
tcp(ip("192.168.0.104") port(20514) tlc(key-file("/etc/syslog-ng/cert/syslog_pri.key") cert-file("/etc/syslog-ng/cert/syslog_pub.crt") peer-verify(optional-untrusted)));
```
3. 将公钥分别复制到client端的 */etc/syslog-ng/cert* 目录中,并生成哈希名的链接
`openssl -x509 -noout -hash -in syslog_pub.crt && ln -s syslog_pub.crt xxxx.0`
4. 配置client端的syslog-ng.conf文件
```
tcp("192.168.0.104" port(20514) tlc(ca-dir("/etc/syslog-ng/cert")));
```
5. 配置完成后，对server和client分别重启syslog-ng服务
`sudo systemctl restart syslog-ng`

### 注意

如果系统开启了SELinux，在使用tcp或udp进行日志传输时，选择端口时要注意SELinux中对syslog-ng端口的设定，如果使用自定的端口，还需要将端口加入到SELinux中。
![semanage_sshd_port](https://s2.ax1x.com/2019/05/14/EIgJSA.png)
`semanage port -a -t syslogd_port_t -p tcp 30514`
