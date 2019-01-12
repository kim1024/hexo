---
title: Linux Shell学习笔记<部分>
date: 2018-10-30 12:04:26
categories: 
 - Linux
tags:
  - Linux
  - Shell
  - 学习笔记
randnum: linux-shell-doc
---

# Linux Shell学习笔记
# 基本信息
- 系统：Debian 9.5
- 发行信息：Debian GNU/Linux 9.5/Stretch

# Shell基础
*update:2018年09月22日*

----------


- 只要能够操作应用程序的借口都能成为壳程序Shell。
- 文件`/etc/shells`中存放着用户可以使用的shell，`/bin/bash`是Linux默认的的shell
 - ex:Debian9.5中可以使用的shell
  - ![shells.png][1]
- 文件`/etc/passwd`中存放着登录时取得的shell,每行的最后一个数据，就是该用户登陆后取得的默认shell
 - ex:用户kim登录取得的shell为`/bin/bash`
  - ![passwd.png][2]

## 命令历史记录
- 用户通过bash操作的记录都被记录到用户主目录下的`.bash_history`中，该文件中记录的是前一次登录以前所执行过的命令。本次登录所执行的命令都被暂存到内存中，当登出系统后，该用户的操作记录才会被记录到该文件中。
- 使用命令`history`可查看当前登录用户执行过的命令

<!--more-->
## 命令别名设置
- `alias ll='ls -la'`  //使用命令`ll`替代命令`ls -la`
- 如果下次登录该别名时效，还可以通过在文件`～/.bashrc`78行左右添加一条记录`alias ll='ls-la'`
  - ![alias.png][3]

## 查询指令类型
- 使用命令`type` 可以查询shell指令是`file or alias or builtin`
  - 可用的参数有`- p -a -t`  //参数p仅在指令为外部指令时，显示完整文件名
   - ![type.png][4]
  
## 指令的快速编辑
- `ctrl+u` 从光标处向前删除指令
- `ctrl+k` 从光标处向后删除指令
- `ctrl+a` 从光标处移动到整个指令的最前面
- `ctrl+e` 从光标处移动到整个指令的末尾

*update:2018-09-25*
## Shell中的变量
- 输出变量内容使用`echo`,ex:`echo $PATH` or `echo ${PATH}`
 - ![echo.png][5]
- 变量规则
  1. 变量与变量内容以`=`连接，`=`两侧**不能直接接空白字符**
  2. 变量名称只能是英文字母和数字，但是**不能以数字开头**
  3. 变量内容若有空白字符，可以使用双引号`"`或单引号`'`将变量内容结合起来，二者的区别是：**双引号内的特殊字符仍然保持原本的特性，单引号内的特殊字符仅为一般字符**
   - ![单引号双引号.png][6]
  4. 可以使用转义字符`\`将特殊字符转换为一般字符
  5. 若指令中需要使用额外指令提供的内容，可以使用`$(comm)` or "\`\comm \`\"(数字1左侧的反引号)
  6. 若变量需要在其他子程序中执行，则需要以`export`使变量变成环境变量
  7. 通常大写字符为系统默认变量，自行设置变量可以用小写字符
  8. 取消变量使用`unset 变量名`
   - ![unset.png][7]
- 环境变量的功能
  1. 使用`env`查看环境变量与常见环境变量说明
   ![env.png][8]- 
  2. 使用`set`查看所有变量(包含环境变量与自定变量)

*update:2018-09-26*

## 变量键盘读取

- `read [-pt] 变量`
  - `p` 后面可以连接提示符
  - `t` 后面可以连接等待时间
   - ![read.png][9]

## 变量类型定义

- `declar/typeset [-aixr] 变量`
  - `-a` 将变量定义为阵列类型[array]
  - `-i` 将变量类型定义为整数数字[integer]
  - `-x` 用法与`export`一样，将变量定义为环境变量
  - `-r` 将变量定义为只读不可更改内容[readonly]
   - ![typeset.png][10]

## 终端可用资源

- `ulimit [-SHacdfltu]`
 - ![ulimit.png][11]

## 变量内容的删除、取代与替换

- 变量内容的删除需要用到特殊字符`#` `new=${old#*_} ` //删除变量old内容中的_及前面所有的内容，删除从最左侧开始
 - ![delete.png][12]


  [1]: http://kim.baby-time.cn/usr/uploads/2018/09/406930324.png
  [2]: http://kim.baby-time.cn/usr/uploads/2018/09/480736423.png
  [3]: http://kim.baby-time.cn/usr/uploads/2018/09/4099011829.png
  [4]: http://kim.baby-time.cn/usr/uploads/2018/09/3460664185.png
  [5]: http://kim.baby-time.cn/usr/uploads/2018/09/523727721.png
  [6]: http://kim.baby-time.cn/usr/uploads/2018/09/1007418659.png
  [7]: http://kim.baby-time.cn/usr/uploads/2018/09/1898152606.png
  [8]: http://kim.baby-time.cn/usr/uploads/2018/09/746461166.png
  [9]: http://kim.baby-time.cn/usr/uploads/2018/09/2771125510.png
  [10]: http://kim.baby-time.cn/usr/uploads/2018/09/168055666.png
  [11]: http://kim.baby-time.cn/usr/uploads/2018/09/3822642523.png
  [12]: http://kim.baby-time.cn/usr/uploads/2018/09/4209473722.png
