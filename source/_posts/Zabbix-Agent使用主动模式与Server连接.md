---
title: Zabbix-Agent使用主动模式与Server连接
date: 2018-10-30 14:35:24
categories: 
 - Zabbix
tags:
  - Zabbix
  - Zabbix-Agent
randnum: zabbix-agent-model
---

# Zabbix-Agent主动模式

## Agent主动与被动模式

  - 被动模式
    - zabbix-agent会监听10050端口，等待server段的监控信息收集请求
    - 当被监控端数量增加后，web操作会出现卡顿和502、图层断裂、数据丢失的现象
  - 主动模式
    - agent会主动收集信息并通过10050端口将信息传送到server段的10051端口

<!--more-->
## 打开主动模式(Agent段操作)

  - `cd /etc/zabbix && vi zabbix_agentd.conf`

    ```bash
    Server=x.x.x.x # 如果使用纯主动模式，则需要将该行注释掉
    StartAgents=0 # 数值范围为0-100,0表示关闭被动模式
    SeverActive=x.x.x.x #主动模式的Zabbix-Server ip地址
    Hostname=hostname #hostname名称需要与Zabbix-Web中添加的主机名称对应，否则会出错
    RefreshActiveChecks=120 # 被监控端到服务器获取监控项的周期，默认为120s即可
    BufferSize=200 # 被监控端存储监控信息的空间大小
    Timeout=10 # 超时时间
    ```

    - `systemctl restart zabbix-agent` #重启agent

## 设置主动监控模式的监控模板

  1. 完整复制原有的模板
   - ![clone template.png][1]

  2. 将复制的模板中的监听项目的模式修改为`Agent Active`，复制的模板会链接到其他模板，可以复制连接到的模板，将监控选项修改为Active模式，并重新链接
  - ![change name.png][2]
  - ![mass update.png][3]
  - ![change type.png][4]
  3. 添加监控主机
  - ![add host.png][5]
  4. 查看是否更新监控数据
  - ![monitor.png][6]


  [1]: http://baby-time.cn/usr/uploads/2018/10/1615188770.png
  [2]: http://baby-time.cn/usr/uploads/2018/10/3413491316.png
  [3]: http://baby-time.cn/usr/uploads/2018/10/3180119885.png
  [4]: http://baby-time.cn/usr/uploads/2018/10/742305417.png
  [5]: http://baby-time.cn/usr/uploads/2018/10/468176580.png
  [6]: http://baby-time.cn/usr/uploads/2018/10/2255496608.png
