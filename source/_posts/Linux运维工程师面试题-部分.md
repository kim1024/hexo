---
title: Linux运维工程师面试题-部分
date: 2019-04-26 10:59:59
categories:
 - Linux
 - 运维
tags:
  - 运维
  - 面试题
randnum: linux_om
---

1. 查看当前目录(包含子目录)下的文件数
`sudo ls -lR | grep "^-" -c`或`sudo ls -lR | grep "^-" | wc -l`
- 参数R表示递归子目录
- `"^-"`表示以符号`-`开头，`-c`计算符合条件的数目
- 如果计算目录数，把正则表达式修改`"^d"`
- grep工具是按行搜索
2. 查看当前系统每个IP的连接数
`netstat -n | grep "^tcp" | awk '{print $5}' | awk -F : '{print $1}' | sort | uniq -c | sort -rn `
`netstat -nt | awk '{print $5}' | awk -F : '{print $1}' | sort | uniq -c | sort -rn`
- netstat使用`-t`参数可以之间显示与tcp有关的数据,'-n显示地址和端口号',`-l`处于listen状态，`-u`表示与udp有关的数据，`-p`显示pid
- awk参数中的`-F :`表示以符号`：`分隔，默认以tab或空格键，按行搜索并把每行分为多个部分
- sort参数中`-r`表示反向排序,`-n`表示以纯数字进行排序，`-u`表示相同数据仅出现一行
- uniq参数中`-c表示计数`
<!--more-->
3. shell中生成32位随机密码
`cat /dev/urandom | head -n1 | md5sum | head -c32 > /tmp/pass`
- head参数中`-n`后跟数字表示显示几行，如果是负数表示列出总行数-x行前的,`-c`表示前多少字符
- 除md5sum运算外，还可以选择sha1sum,sha256sum
4. ps命令中的Aux与VSZ
- ps命令可以查看某个时间点的程序运行状况，比较常用的是`ps -l`和`ps aux`,前者表示只列出自己bash相关的程序，后者表示所有bash的程序
![ps aux](https://s2.ax1x.com/2019/04/24/EV8DsA.png)
- STAT状态
  - R->Running
  - S->Sleep，可以被唤醒
  - D->不可被唤醒，可能在等待I/O
  - T->Stop背景暂停或除错状态
  - Z->Zombie僵尸状态，已经终止但是无法被移除内存外
- TTY表示登录者的终端位置，远程登录则使用pts/n,与终端无关的显示为?,tty1-6为本机
- VSZ程序使用的虚拟内存(Kb)
- RSS程序使用的固定内存(Kb)
- %MEM程序占用的实体内存百分比
5. top与ps的区别
- top命令是动态观察程序的变化，ps是某个时间点的程序状态
![top](https://s2.ax1x.com/2019/04/24/EVUuPx.png)
- load average分别是1min，5min，15min的负载，如果该数除以逻辑cpu的数量大于5表示系统超负荷
- `-d` 跟秒数，top更新的秒数，默认为5s
- `-p` 指定pid
- `P` 按cpu资源排序
- `M` 以memeory资源排序
- `N` 以pid排序
- `T`使用cpu时间累计排序
- `1`数字1可以查看每个逻辑cpu的状况，再按一次返回
- `b`高亮显示当前进程
- `m`切换显示内存信息
- `q`离开top
- `PR`表示程序执行的优先顺序，越小越早被执行
- `NI`nice的缩写，越小越早被执行
- `VIRT`进程使用的虚拟内存总量，单位kb，VIRT=swap+res
- `RES`进程使用的物理内存
- `SHR`共享内存
6. shell内取1-39的随机整数
`expr ${RANDOM} % 39 + 1`
- expr是一个手工命令行计数器，用于求表达式变量的值，可以进行`+ - * / %`的运算， 进行乘法运算时需要将符号`*`转义`\*`,数字与元算符号之间有空格
- RANDOM是系统变量，会产生0～32767之间的数值
7. 显示文件*/etc/ssh/sshd_config*文件中以\#开头，并且后面跟一个或多个空白字符，而后又跟任意非空字符，并显示行号
`grep -n "^# \{1,\}[^ ]" /etc/ssh/sshd_config`
- grep中参数`-n`用于显示行号
- `^`万用字符表示以某个字符开头，`$`万用字符表示以某个字符结尾，`[^ ]`表示非空白字符
- `X\{1,\}`表示一个以上X字符，`\`用于转义符号`{}`,`X\{2,5\}`表示
8. 使用shell批量创建用户和默认密码，并保存用户名和密码到文件中
```
#!/bin/bash
# create group if not exist
grep test /etc/shadow
[ $? -eq 0 ] || groupadd test
# create user 
for i in 'seq -f"%02g" 1 10'
do
	# create user use command:useradd
	useradd -s /bin/bash -g test user${i} > /dev/null 2>&1
	user_passwd="`echo ${RANDOM}|md5sum|head -c8`"
	# change passwd use command:passwd --stdin
	echo "${user_passwd}"|passwd --stdin user${i} > /dev/null 2>&1
	# save user_name and user_passwd
	echo "user${i} :${user_passwd}" >> /home/kim/user_passwd.txt
done
```
- echo 在输出变量还有其他字符时，需要使用双引号`""`,如果输出的内容需要调用其他命令还需要使用字符````
- seq格式化`%02g`保留2位，不足位用0补充
- 使用判断符号`[]`要注意左右的空格
- 标准输出和标准错误输出`2>&1`
- 垃圾桶`/dev/null`
9. 查找/var/log目录下后缀格式为log，大小超过1M的文件数目
`find /var/log -name "*.log" -type -f -size +1024k | wc -l`
10. 查找/tmp目录下10天内未修改的文件，并删除
`find /tmp !-mtime -10 -exec rm -fr {} \;`
11. 查找当前目录下的空文件夹/文件并删除
`find ./ -type d -empty -exec rm -fr {} \;`
`find ./ -type f -size 0c -exec rm -fr {} \;`
12. 显示磁盘使用率超过50%的分区
`df -h |awk '+$5>50'`
- 使用一元加运算`+$5表示第五列乘以+1(正1)`，一元减表示乘以负1
13. 打包本目录下的所有文件为web.tar.gz，排除文件夹log和文件test
`tar -czvf web.tar.gz ./* --exclude=./log/ --exclude=./test`
14. umask022代表的意思
umask代表创建文件或目录的默认权限，计算方式为777分别减去umask的值	，umask022代表创建文件或目录的默认权限为755,即u为rwx，g为rx，o为rx
15. 查看某个进程/用户打开的文件
```
# 1个或多个进程打开的文件
## 根据进程名
lsof -c process
lsof | grep process
lsof -c process1 -c process2 
## 根据进程号
lsof -p pid,pid1,pid2
# 用户打开的文件
lsof -u user
# 除用户user外打开的文件
lsof -u ^user
# 查看正在使用文件
lsof /path/filename
# 查看网络信息
## tcp
lsof -i tcp
## udp
lsof -i udp
## 端口号
lsof -i:1080
## 使用端口号的tcp
lsof -i tcp:1080
## 用户的所有活跃的网络端口
lsof -a -u user -i 
```
16. 常用服务的端口号
  - http/https:80
  - ftp:21
  - ssh:22
  - sftp:22
  - smtp:25/465/993
  - pop3:110/995
  - imap:143/993
