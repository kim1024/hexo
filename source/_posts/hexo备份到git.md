---
title: hexo备份到git
date: 2019-01-12 11:43:04
categories: 
 - hexo
tags:
  - hexo
  - git
  - 备份
randnum: hexo-backup-git
---

1. 如果本地hex的工作目录使用的是 xxx.github.io的方式命名的，需要将文件夹重命名hexo(名称自定)；
2. 在git中新建一个repo，名称与本地文件夹相同；
3. 初始化本地文件夹
 `git init`
 4. 设置不需要推送到git的文件和文件夹：
 <!--more-->
 ```
 touch .gitignore
 # 在.gitignore文件夹中加入
 *.log
 /public
*.deploy/
 ```
 4. 删除主题文件夹中的`.git`文件夹；
 5. 在本地添加远程仓地址`git remote add origin git@github.com:kim0x/hexo.git`;
 5. 将本地源文件推送到git中：
 ```
 git add .
 git commit -m "backup"
 git push origin master
 ```
## 使用脚本定时备份和更新
```
#!/bin/bash
# env
our_home=/home/kim/Documents/kim1024.github.io
backup_home=/home/kim/Documents/hexo
now_date=`date "+%Y%m%d"`
# test log file exist or not
[ !-e /home/kim/tmp/git_update.log ] || rm -f /home/kim/tmp/git_update.log
#copy file from our_home to backup_home
cp -r ${our_home}/* ${backup_home}/
# push update to github
cd ${backup_home}
git add . > /home/kim/tmp/git_update.log 2>&1
git commit -m "${now_date}" >> /home/kim/tmp/git_update.log 2>&1
git push origin master >> /home/kim/tmp/git_update.log 2>&1
```
将脚本文件命为`update_git.sh`,添加执行权限`chmod u+x update_git.sh`,添加到用户的crontab定时执行中:
```
# 打开crontab
crontab -e
# 添加任务计划,每周五11点执行
0 11 * * 5 /home/kim/tmp/update_git.sh
# 保存文件
:wq!
# 查看用户crontab计划
crontab -l
# 删除当前的任务计划
crontab -e
删除文件中的所有计划
```