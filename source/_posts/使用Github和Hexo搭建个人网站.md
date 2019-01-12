---
title: 使用Github和Hexo搭建个人网站
date: 2018-10-30 10:29:19
categories: 
 - other
tags: 
  - Hexo
  - Github
  - 个人网站
randnum: github-hexo-website
---
# 使用Github和Hexo搭建个人网站

- 概述
  - Hexo使用Markdown解析文章，能够在几秒内利用主题生成静态网页；
  - Github是世界上最大的代码存放网站和开源社区，目前已经被微软收购；
  - 利用Hexo生成静态网页，将生成的静态网页发布到Github上，已完成个人网站所具有的功能。
- 系统信息
  - 系统：Debian9.5
  - NVM：V11.0.0
  - NPM：6.4.1
  - Nodejs：11.0.0


<!--more-->


## 登录Github

1. 登录Github，新建一个repository，格式应为：`xxxx.github.io` 其中xxx代表你的用户名

   [![New Repository](https://s1.ax1x.com/2018/10/29/ig0j56.png)  ](https://imgchr.com/i/ig0j56) 

   ## 安装Nodejs和Git 

2. 首先需要在本机上安装`Node.js`和`Git`

 1. 安装nvm

  - `aria2c https://raw.github.com/creationix/nvm/v0.33.11/install.sh && chmod +x install.sh && ./install.sh`

 2. 安装Nodejs
   - `nvm install stable`
 3. 安装hexo
   - `npm install hexo-cli -g` 
3. 安装Git
   - `apt install git-core`


4. 创建一个文件夹，文件夹名称与第1步中新建的repository相同

   - `mkdir kim1024.github.io && cd kim1024.github.io`

5. 切换到刚创建的文件夹中，创建`.git`文件

   - `git config --global user.name "kim1024"` # replace kim1024 with your git username
   - `git config --global user.email "email_address"`

6. 如果需要使用SSH秘钥，则需要创建秘钥对

   - `ssh-keygen -t rsa -C "email_address -f ./"`
   - 在目录下找到刚创建的秘钥对，其中一个文件后缀格式为`.pub`,这就会刚刚创建的加密公钥；
     - `cat gir_rsa.pub` # 会看到一串字符，以ssh-rsa开头，以邮箱地址结尾，复制全部的字符串；
     - [![i2czUH.md.png](https://s1.ax1x.com/2018/10/30/i2czUH.md.png) ](https://imgchr.com/i/i2czUH) 
   - 打开`github.com`,登录自己的账号，点击右上角的头像，找到`Setting` ，然后打开右侧的`SSH and GPG Keys`，点击`New SSH Key`，然后命名，将复制的字符串粘贴到下方的空白处，提交即可；
     - [![i2gC8I.md.png](https://s1.ax1x.com/2018/10/30/i2gC8I.md.png)](https://imgchr.com/i/i2gC8I) 
     - [![i2gixP.md.png](https://s1.ax1x.com/2018/10/30/i2gixP.md.png)](https://imgchr.com/i/i2gixP) 
   - 添加成功后，在本机上进行ssh测试连接`ssh -i ./gir_rsa git@github.com`,当出现如下提示时，表示ssh连接成功；
   - 还可以通过`ssh-add` 命令将生成的密钥添加到ssh-agent中，在添加之前，需要修改key的权限
     - [![i2gZVg.md.png](https://s1.ax1x.com/2018/10/30/i2gZVg.md.png)](https://imgchr.com/i/i2gZVg) 

   ## 安装Hexo 

7. 安装hexo,进入创建的`kim1024.github.io`文件夹中，依次执行以下命令：

   - `hexo init ./` # hexo初始化

     - [![i2gkKf.md.png](https://s1.ax1x.com/2018/10/30/i2gkKf.md.png)](https://imgchr.com/i/i2gkKf) 

   - 初始化完成后，在文件夹中会创建多个文件夹和文件，找到文件`_config.yml`进行编辑

     - `vi _config.yml` # 根据自己的需要修改其中的项目

       ```
       deploy: 
         type: git
         repo: git@github.com:kim1024/kim1024.github.io.git # replace this url with your own ssh url
         branch: master # 必须使用master，使用其他分支会出现问题
       ```

     - 编辑完成后保存

   - `hexo g`

     - [![i2g5sf.md.png](https://s1.ax1x.com/2018/10/30/i2g5sf.md.png)](https://imgchr.com/i/i2g5sf)

   - `hexo d` # 发布，使用ssh认证，避免了每次发布都需要输入用户名和密码的麻烦

     - [![i2gIL8.md.png](https://s1.ax1x.com/2018/10/30/i2gIL8.md.png)](https://imgchr.com/i/i2gIL8)

