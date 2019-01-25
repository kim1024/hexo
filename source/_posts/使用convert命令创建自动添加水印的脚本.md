---
title: 使用convert命令创建自动添加水印的脚本
date: 2019-01-25 09:04:09
categories:
  - convert
tag:
  - convert
  - 水印
  - shell
randnum: convert-watermark
---

## convert

`convert`是ImageMagic中的，如果要使用`convert`的相关功能，首先系统中安装ImageMagic。脚本实现的是基础功能，将一张图片作为水印，添加到当前文件夹中的所有图片中，图片支持的格式有`jpg|png|jpeg|gif`,添加水印后的照片被保存到当前目录下的`w_pic`。

<!--more-->

```
#!/bin/bash
# date:2019-01-17
# function: Add watermark to all picture in this dir by command convert.
# version: 1.0
# start script


# env
home_dir=${PWD}
cd ${home_dir}
# copyright 
copy_png=/home/kim/Documents/img/copy.png

# test list_file and w_pic exit or not
if [ -e "list_file" ]; then
	rm -fr list_file
elif [ -d "w_pic" ]; then
	rm -fr w_pic
fi

# search imge file,print filename to list_file
touch list_file
find ./ -name "*.png" 1> ./list_file
find ./ -name "*.png" 1>> ./list_file
find ./ -name "*.gif" 1>> ./list_file
mkdir w_pic

# start convert
# f_num=1
cat ${home_dir}/list_file | while read f_name
do
	convert ${f_name} label: ${copy_png} -gravity center -append ${home_dir}/w_pic/${f_name}
	# rm -fr ${f_name}
	echo "${f_name} complate!"
	# f_num=$((${f_num}+1))
done
# echo ${f_num}

## print 
if [ $?==0 ]; then
	echo "New Pic location is ${home_dir}/w_pic"
	exit 0
else
	echo "ERROR!"
fi
# clean
	rm -f ${home_dir}/list_file
	exit 1

```
