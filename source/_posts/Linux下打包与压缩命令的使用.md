---
title: Linux下打包与压缩命令的使用
date: 2018-10-30 12:00:52
categories: 
 - Linux
 - 学习笔记
tags:
  - Linux
  - 打包压缩
  - 备忘
randnum: tar-format
---

# Linux 下打包压缩命令备忘

## 常用打包压缩解压命令
- \*.tar.gz  //使用gzip压缩，用tar打包
  - 打包压缩命令：`tar -czvf new.tar.gz files `
  - 解压命令： `tar -xzvf new.tar.gz`
- \*.tar.bz2 //使用bzip2压缩，用tar打包
  - 打包压缩命令： `tar -cjvf new.tar.bz2 files`
  - 解压命令： `tar -xjvf new.tar.bz2`
- *.tar.xz //使用xz压缩，用tar打包
  - 打包压缩命令： `tar -cJvf new.tar.xz files` //参数中注意是大写的`J`
  - 解压命令： `tar -xJvf new.tar.xz [-C dirname]` //可以添加参数`-C dirname`指定解压缩的目录
## 单独解压压缩包中的某个文件
  1. 首先查看压缩包中的文件，并筛选出该文件，使用命令：`tar -tjvf new.tar.gz | grep 'filename'`
  2. 使用解压命令，单独解压该文件，使用命令：`tar -xjvf new.tar.gz dir/filename`
## 注意事项
  - 参数`c`创建压缩包，参数`x`解压压缩包，参数`t`查看压缩包内部文件名；
  - 使用gzip压缩打包时使用参数`z`,使用bzip时使用参数`j`,使用xz时使用参数`J`;
  - 参数`p`可以用来保留备份数据的原本权限与属性，使用时与参数`c`同时使用；
  - 在打包压缩命令前添加`time`可以显示程序运行的时间；
- 压缩率xz>bz2>gz，压缩率越高，需要的时间越多
