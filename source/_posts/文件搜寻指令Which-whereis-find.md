---
title: 文件搜寻指令Which/whereis/find
date: 2019-01-12 11:07:29
categories: 
 - Linux
tags:
  - whereis
  - which
  - find
randnum: whereis-which-find
---

![文件搜寻指令导图](https://s1.ax1x.com/2018/12/30/Fh3OfA.png)

<!--more-->

## 常用
- 在根目录下查找后缀格式为log的文件，并删除删除3天前的
`find / -name "*.log" -mtime +3 -exec rm -fr {} \;`
- 在根目录下查找后缀格式为log的文件，并且3天内没有修改过
`find / -name "*.log" !-mtime -3`
- 在当前目录下查找大于1M,后缀格式为log的文件，并将文件移动到/tmp/1M文件夹中
`find ./ -name "*.log" -size +1024k -exec mv {} /tmp/1M \;`
- 查找当前目录下的空文件夹并删除
`find ./ -type d -empty -exec rm -fr {} \;`
- 查找当前目录下的空文件(普通文件)并删除
`find ./ -type f -size 0c -exec rm -fr {} \;`
