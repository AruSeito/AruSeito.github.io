---
title: 协同编辑冲突处理算法之OT算法
categories:
  - 其他
tags:
  - 协同编辑冲突处理算法
keywords:
  - 协同编辑冲突处理算法
  - 协同算法
  - OT
index_img: 'http://www.dmoe.cc/random.php'
banner_img: 'http://www.dmoe.cc/random.php'
abbrlink: 23c3b7d4
date: 2021-12-27 20:19:59
---

## 背景

我司的滴答清单是可以分享清单与人共享协作的，但是今天我自己好奇是怎么处理冲突的，试验了一番，A和B同时编辑清单，同时向服务器提交会是什么现象？最终发现，居然没有处理？处理的机制就是简单的谁是最后到达的就以谁为准,甚至都不会上锁。我惊了，然后就调研了一下业界的编辑冲突解决方案。

## 早期方案

### 上锁

A用户编辑的时候就给这个文档上锁，B用户被禁止编辑或请求被拒绝。

弊端：

效率低下，只有一个可编辑，一个人在编辑其他人只能眼巴巴看着。

### 自动合并

原理类似于git diff这种，遇到冲突还是需要用户自己处理。具体没看过，就不做过多说明了。

## 主流方案

- OT（Operational Transformation）算法
- AST（Address space transformation）算法
- CRDT（Conflict-free Replicated Data Type）算法

### OT算法

Operational Transformation算法的简称，核心原理是基于操作转换。腾讯文档目前在用的方案。

[可视化OT算法过程](http://operational-transformation.github.io/index.html)

简单描述来说就是将各种操作抽成多种操作原子，最简单的应该需要三种原子：插入（Insert），保持（Retain），删除（Delete）。

举个例子:

文本都是 ‘aaab’，A 用户在第 3 个字符行后面插入了一个 ‘c’，B 用户在第 3 个字符行后面插入了一个 ‘d’。

A 本地已经是 ‘aaacb’ 了，过一会儿，后台告诉它 B 也编辑了，编辑的行为就是第 4 个字符行后面插入了一个 ‘d’，那 A 这边执行了这个行为，最终变成了 ‘aaacdb’。

B 本地已经是 ‘aaadb’ 了，过一会儿，后台告诉它 A 也编辑了，编辑的行为就是第 3 个字符行后面插入了一个 ‘c’，那 B 这边执行了这个行为，最终变成了 ‘aaacdb’

这样就一致了。

转换成OT的这种行为就是

```js

// A = [R(3),I('c')];
// B = [R(3),I('d')];

```

那是如何合并的呢？可以参考[ot.js](https://github.com/Operational-Transformation/ot.js)

逐个字符遍历，遇到A在执行插入的时候，B会先保持。A执行完插入之后字符串会变成基于A的一个版本，然后B在根据基于A操作的字符串进行插入。在执行过程中始终保持 indexA和indexB相等。

我们上面说的冲突其实并不是同一时间的冲突，而是基于某版本的冲突，比如用户A和用户B都是在版本100的时候进行修改的，那这两次都是从版本100开始推算的。也就是说 A用户这面不断修改，都到1000版本了，B用户这面也在修改，但是他只是从100开始修改了几个版本，一直没网，没同步上。那其实这种状态可以认为B用户处在 操作提交了但是在等后端确认，并且也编辑了数据。等联网了之后，直接通知他A修改了，开始进行 从100开始的操作合并。


我写的这些大部分内容来自于这里，[原文戳这](http://www.alloyteam.com/2019/07/13659/)

## 个人简单理解

其实就是在某个版本上写代码，只不过写的不是大段的话，而是记录每次在什么位置后进行了什么操作,然后把基于某版本的操作提交到后端。然后后端按照这个操作对数据库里的操作执行增删，然后把这个操作再通知给在线的客户端，客户端再按照这个操作进行个合并，如果是某个客户端自己的请求那么就可以忽略这个操作。直到两端版本对齐。
处于自己编辑并且操作提交了在等后端确认的时候不发起任何请求，只进行数据接收。只有服务端响应了自己的请求之后才会继续请求。
处于自己本地没编辑，就一直等着接收就可以。

服务端存储了 baseString 、 Operations、version。本地需要初始化的时候都是通过baseString初始化，后续变更往服务端都是提交operation,然后服务端的baseString基于operation进行变动，version++，然后再将operation通知给客户端们。客户端这面要存的比较多version,string，还有三种状态队列。客户端这面拿到了operation后基于string开始进行变化，version++。

### 三种状态

Synchronized：客户端与服务端状态相同（即string === baseString）

AwaitingConfirm：当前客户端向服务器发送了操作命令，还没有收到返回消息。

AwaitingWithBuffer：当前客户端向服务器发送了op操作，还没有收到确认消息，且客户端有进行了新的操作。（客户端掉线了并且有了编辑行为就会处于这个状态）

### 三个方法

每种状态下均有可执行三种操作applyClient、serverAck、applyServer，下面分别说明每种状态下各种操作的具体含义

- Synchronized状态

applyClient：向服务器发送op操作命令，并设置client状态为AwaitingConfirm
applyServer：收到服务器op操作指令，执行服务器op操作指令，版本号加1
serverAck：无 

- AwaitingConfirm状态
applyClient: 缓存客户端新的op操作命令，并设置client状态为AwaitingWithBuffer
applyServer: 客户端执行OT变换后的服务端op操作，对已经发送的op操作进行OT变换，状态保持不变，版本号加1
serverAck: 设置客户端状态为Synchronized，版本号加1 

- AwaitingWithBuffer状态 
applyClient: 缓存合并客户端新的op操作指令，状态不变 
applyServer: 客户端执行OT变换后的服务端op操作，对已经发送的op操作进行OT变换，对需要发送的op操作进行OT变换，版本号加1
serverAck: 发送缓存的客户端新指令，设置状态为AwaitingConfirm，版本号加1 


## 其他资料

 - [协同编辑冲突处理算法综述](https://mp.weixin.qq.com/s?__biz=MjM5MTY2NTIyMA==&mid=2649000528&idx=1&sn=98521c16c3f24809f426fe39ae48e203&chksm=bea2377b89d5be6df3656e8b8c76d022ab1fe6deece6b3f16e88ab07b5cba227542240f7d5d7#rd)

 - [协同编辑OT算法server端实现原理](http://hupengfoot.github.io/2019/01/08/OT-server.html)

 - [多人协同编辑技术的演进](https://juejin.cn/post/7030327005665034247)

 - [ot.js](https://github.com/Operational-Transformation/ot.js)

 - [可视化OT过程](http://operational-transformation.github.io/index.html)





