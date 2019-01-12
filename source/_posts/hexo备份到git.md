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
