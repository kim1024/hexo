---
title: Zabbix监控图形中文不显示或乱码的解决方法
date: 2019-05-11 10:04:54
categories:
 - Zabbix
tags:
  - Zabbix
  - 中文
randnum: zabbix_Chinese_font
---

## 基本信息

Zabbix版本号为4.0.7LTS，在使用系统管理员创建用户，为用户分配中文语言环境后，新用户登录系统后，出现在监控图形中中文显示为方框或不显示的情况。

## 解决方法

下载中文字体，将原字体用下载的字体替换。我们使用雅黑字体替换原文件。
下载雅黑字体`wget https://www.wfonts.com/download/data/2014/06/01/microsoft-yahei/microsoft-yahei.zip`，解压`unzip microsoft-yahei.zip -d ./yahei`

<!--more-->

### 替换原字体

1. 找到原字体
`find / -name "graphfont*"`
2. 替换字体
字体文件位于*/usr/share/zabbix/fonts/graphfont.ttf* ,查看该字体详情会发现该字体链接到*/etc/alternatives/zabbix-web-font* 
3. 替换链接文件
`ln -s ./yahei.ttf /etc/alternatives/zabbix-web-font`
4. 或者直接替换graphfont.ttf文件
`mv /usr/share/zabbix/fonts/graphfont.ttf /usr/share/zabbix/fonts/graphfont.ttf.old && cp ./yahei.ttf /usr/share/zabbix/fonts/graphfont.ttf`

**如果该方法不生效，可以参考另一种方法**

### 安装新字体

1. 将雅黑字体复制
`cp ./yahei/yahei.ttf /usr/share/zabbix/fonts/`
2. 使用雅黑字体
```
# 修改文件defines.inc.php
cp defines.inc.php defines.inc.php.old
# sed 查找关键词,将graphfont替换为yahei
sed -i 's/graphfont/yahei/g' ./defines.inc.php

```
![replace_font](https://s2.ax1x.com/2019/05/11/EWg0uF.png)
3. 打开监控图形，中文字体显示正常
![Chinese_font](https://s2.ax1x.com/2019/05/11/EWgsE9.png)
