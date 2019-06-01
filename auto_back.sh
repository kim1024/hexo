#!/bin/bash
# function: auto backup hexo 
# date: 2019-05-30
# command:
# env
hexo_home=/home/kim/Documents/kim1024.github.io
hexo_src=/home/kim/Documents/hexo
now_date=echo `date +%Y/%m/%d` > /dev/null 2>&1
# backup
cp -r ${hexo_home}/* ${hexo_src} > /dev/null 2>&1
cd ${hexo_src}
git add ./ > /dev/null 
git commit -m "${now_date}"
git push origin master 

