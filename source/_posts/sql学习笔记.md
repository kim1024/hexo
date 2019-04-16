---
title: sql学习笔记
date: 2019-04-16 17:21:02
categories: 
 - sql
 - 学习笔记
tags:
  - sql
randnum: sql-learning
---
# 结构化查询语言SQL学习笔记- 基础知识

## 基础知识

- 主键：主键是唯一的，一个数据表中只能包含一个主键，可以使用主键来查询数据;
- 外键：外键用来关联2个表;
- 符合键：符合键(组合键)将多个列作为一个索引键;
- 索引：使用索引可快速访问数据表中的特定信息。索引是数据表中一列或多列的值进行排序的一种结构;
- SQL常用动词
  - 数据查询：select
  - 数据定义：create，drop，alter
  - 数据操纵：insert，update，delete
  - 数据控制：grant，revoke
<!--more-->
 - SQL对关系数据库模式的支持：外模式，模式，内模式。3个模式的基本对象有表，视图和索引;
  - 外模式：外模式对应视图和部分基本表;
  - 模式：模式对应基本表;
  - 内模式：内模式对应存储文件;
 - SQL的数据定义语句
  - 模式:定义模式实际上是定义了一个命名空间，可以在这个空间中进一步定义该模式包含的数据库对象;
   - 创建：create schema
   `create schema <schema_name> authorization <user_name>`
   - 删除：drop schema
   `drop schema <schema_name> <cascade|restrict>`
    - cascade级联模式：在删除模式的同时把该模式中所有的数据库对象全部删除;
    - restrick限制模式：如果在定义的模式中包含数据库对象，则拒绝删除该模式，近当该模式下没有数据库对象时才执行删除;
  - 表：基本表是本身独立存在的表，一个关系就对应一个基本表。一个或多个基本表对应一个存储文件，一个表可以带若干索引，索引也存放在存储文件内中;
   - 创建：create table
   - 删除： drop table
   - 修改：alter table
  - 视图：视图是从一个或几个基本表导出的表。它本身不独立存储在数据库中，数据库中只存放视图的定义而不存放视图对应的数据。这些数据仍存放在导出视图的基本表中，**视图是一个虚表**
   - 创建：create view
   - 删除：drop view
  - 索引
   - 创建：create index
   - 删除：drop index
   
## 基本表的定义、删除与修改

- 定义基本表
`create table <table_name> (<列名> <数据格式> <约束条件>,<列名> <数据格式> <约束条件>)`
![create table.png](https://s2.ax1x.com/2019/04/16/AvqR6P.png)
![foreign references.png](https://s2.ax1x.com/2019/04/16/AvXR61.png)
* foreign key可以用于预防破坏表之间连接的动作，也可以防止非法数据插入外键列 *
## 创建数据库
`create database if not exists test_db default charset utf8 collate utf8_general_ci;`
 - collate 意思是在排序时个怒utf-8编码格式来排序
 - default charset 设置默认的字符集

