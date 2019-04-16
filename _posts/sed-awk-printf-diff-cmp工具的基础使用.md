---
title: sed-awk-printf-diff-cmp工具的基础使用
date: 2018-12-07 14:12:01
categories:
  - Shell
tags:
  - Shell
  - sed
  - awk
randnum: sed-awk-printf-diff-cmp
---

## sed工具

- sed是一个管线命令，可以分析标准输入，而且可以将数据取代、删除、新增、撷取特定行;
- sed工具的命令格式：`sed [-nefre] '[n1,n2][command]' `
  - `-n` : 使用安静模式silent,在sed的一般应用中，所有来自标准输入的数据都会列到屏幕中，如果使用了安静模式，只有经过sed处理的那一行数据才会被输出到屏幕中;
  - `-e` : 直接在命令行界面上进行sed的动作编辑;
  - `-f` : 直接将sed的动作写在一个文件内，使用该参数指定文件路径名称;
  - `-r` : sed动作支持的是延伸型正则表达式，不使用参数，默认使用基础正则表达式语法;
  - `-i` ： 直接修改读取的文件内容，而不是由屏幕输出
  - `n1,n2` : 选择进行动作的行数，连同后接的命令需要用单引号括住
  - command中可以使用的命令有：
    - `a` 新增到下一行，后接字符串,新增多行的，需要在每行最后添加换行符号`\`在最后一行后新增内容`sed -i '$a new add content' filename`
    - `c` 取代n1,n2之间的行，后接字符串,ex: nl ~/test | sed '2,5c This is a replace contend'`使用This is a replace contend取代2-5行的全部内容
    - `d` 删除,删除空白行`sed '/^$/d'`
    - `i` 插入到上一行，后接字符串
    - `p` 打印输出,可以用于取出特定行的内容,ex: `nl /etc/shadow | sed -n '2,5p'`
    - `s` 取代，直接进行取代的工作，格式`s/要取代的字符/新字符/g`
    - 使用sed工具取出eth0的ip地址`ip addr | grep 'eth0$'` | sed '.*inet.//g' | sed 's/\24.*$//g'
    
![sed-ip-addr](https://s1.ax1x.com/2018/12/07/F1TwZR.png)

<!--more-->
## printf格式化打印

- 命令格式`printf 'format' content`
  - 打印格式
    - `\a` 警告声音输出
    - `\b` 倒退键backspace
    - `\f` 清除屏幕form feed
    - `\n` 输出新行
    - `\r` Enter键
    - `\t` 水平Tab键
    - `\v` 垂直Tab键 
    - `\xnn` 将2位数字nn转换为字符
    - `%ns` n个字符
    - `%ni` n个整数	
    - `%N.nf` 浮点数全长N为，其中n个小数位，1位小数点，整数位N-n-1
    
## awk工具

- awk工具将一行中的数据分成多段进行处理，默认的分段分割符是**空白格或Tab**，以行为1次处理单位，以字段为最小的处理单位，命令格式`awk 'option1{command} option2{command}' filename`
- awk的变量
  - `$n` n代表数字，表示一行中的第n个字段，如果为0表示整行
  - `NF` 内置变量，每行拥有的字段总数
  - `NR` 内置变量，当前处理行
  - `FS` 内置变量，目前的分割字符，默认是空白格
  
- 获取last的前5行数据的第一个字段名称，并输出当前行和当前行的字段总和`last -n 5 | sed '6,7d' | awk '{prinft $1 "\t linnum:" NR "\t fnum:" NF "\t"}'`

![last-sed-awk](https://s1.ax1x.com/2018/12/07/F1biZ9.png)

- awk逻辑运算
```
1. >  # 大于
2. <  # 小于
3. >= # 大于等于
4. <= # 小于等于
5. == # 等于
6. != # 不等于
```

## 文件比对工具

- diff
  - diff工具常用来比对2个文件之间的差异，并且是以行为单位的，一般是用在ASCII纯文本文件的对比，除了比对文件外，diff还可以用来比对目录之间的差异。命令格式`diff [-bBi] from-file to-file`
    - `-b` 忽略一行中，仅有多个空白的差异
    - `-B` 忽略空白行的差异
    - `-i` 忽略大小写差异
  
![diff-file](https://s1.ax1x.com/2018/12/07/F1jP4s.png)

- cmp
  - cmp以字节为单位比对，命令格式：`cmp [-l] file1 file2`
    - `-l` 将所有的不同点的字节都列出，默认只输出第一个发现的不同点
    
![cmp-diff](https://s1.ax1x.com/2018/12/07/F1j7rT.png)
