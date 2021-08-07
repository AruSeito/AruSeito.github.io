---
title: 《自顶向下学 React 源码》学习笔记
categories:
  - 源码学习
tags:
  - React
  - 源码
keywords:
  - React
  - 源码
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg26.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg26.jpg
abbrlink: 3f8812bd
date: 2021-08-07 17:47:35
updated: 2021-08-07 17:47:35
---

## 设计理念

[React 哲学](https://zh-hans.reactjs.org/docs/thinking-in-react.html):React 是用 JavaScript 构建快速响应的大型 Web 应用程序的首选方式

目前 web 端快速响应的两大瓶颈：计算能力和网络延迟。对应的也就分别是 CPU 和 IO。

1000ms/60Hz = 16.6ms 浏览器刷新一次。

在这 16.6ms 之间，会依次 JS 脚本执行->样式布局->样式绘制

如果 JS 的脚本执行时间超过 16.6ms，就会掉帧。

以前的方案主要有：防抖和节流。但是治标不治本。

防抖：指定时间内不继续操作后执行。

节流：指定时间内只执行一次。

React 的做法是实现一种异步可中断的更新机制。

浏览器预留时间给 React，React 用这部分时间来干自己的事，如果这段时间内没干完，那么 React 就将控制权交回给浏览器，等下一次的预留时间。所以浏览器就有充足的时间进行样式布局+样式绘制。

## 架构的演化

### 老 React 的架构（15 及以前）

老 React 中可以分为两部分：决定渲染组件（协调器）-》将组件渲染到视图中（渲染器）。

协调器（Reconciler）中会进行 Diff 算法，算出哪些需要更新，然后将要更新的内容交给渲染器（Render）中。

问题：

协调器与渲染器是依次执行工作。如果同时更新多个节点，第一个 DOM 会先发生变化，但是因为更新过程是同步的，所以会同时渲染出来。如果在渲染过程中发生中断，协调器和渲染工作还在继续，但是第一个组件会先渲染完。就会产生 bug。

### 新 React 的架构（16 及以后）

新 React 中分为三部分：调度更新（调度器）->决定更新什么（协调器）->将组件更新到视图中（渲染器）。

调度器会对更新项分配优先级，将高优先级的先交给协调器，然后协调器进行 Diff 算法，再将更新的内容交给渲染器。如果在进行 Diff 的过程中来了新的更高优先级的更新项，则将正在 Diff 的更新项中断，先进行高优先级的 Diff。循环以上操作。因为这些操作都在内存中操作，用户并不会感知。（跟离线操作 DOM 一个意思）

## React 的新架构 ---- Fiber

Fiber 是协程的一种实现方式，另一种协程的实现方式为 Generator。不采用 Generator 的原因：Generator 和 async 一样都具有传染性。更新可以中断并继续，更新具有优先级，高优先级可以打断低优先级。

### Fiber 的含义

#### 从架构的角度来说

- 老 React 的架构：Reconciler 采用递归的方式执行，数据保存在递归的调用栈中，所以被称为 Stack Reconciler。

- 新 React 的架构：Reconciler 基于 Fiber 的节点实现，所以成为 Fiber Reconciler

#### 从静态数据结构来说

每个 Fiber 节点对应一个 React element，保存了该组件的类型（函数组件/类组件/原生组件...）、对应的 DOM 节点等信息。

一个 React 应用中只能有一个 FiberRootNode，一个 FiberRootNode 最多有两个 RootFiber。

![静态数据结构](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210807/作为静态数据结构.png)

为什么父节点连接子节点用 child，子节点使用 Return 连接父节点？因为 React 15 中 Stack Reconciler 采用递归的方式，先从根递到子节点，在从子节点归到根，所以归阶段函数处理完会用 Return。在 Fiber Reconciler 采用遍历的方式，实现可中断的递归，所以复用了这种方式。

#### 作为动态工作单元

每个 Fiber 节点保存了本次更新中该组件改变的状态、要执行的工作（需要被删除/被插入页面中/被更新...）。

### Fiber 的工作原理

#### 双缓存

正常动画播放：先删除前一帧，然后计算当前帧，显示当前帧。如果当前帧计算量特别大就会有特别长的白屏时间。

在内存中绘制当前帧，绘制完后替换前一帧。（这不还是离线操作 DOM 的操作）

#### Fiber 树双缓存

首次运行时，会创建一个 FiberRootNode 和 RootFiber，因为是首屏渲染，所以 RootFiber 下并没有任何内容。

然后进入 Render 阶段，首先创建 Fiber 树的根节点 RootFiber，使用 alternate 连接之前的 RootFiber，方便属性公用。然后根据组件返回的 JSX 在内存中创建一颗 Fiber 树（其实就是虚拟 DOM，存有各个节点的父子关系），。这个 Fiber 树叫 WorkInProgress Fiber 树。之前的那个树叫 Current Fiber 树。

WorkInProgress Fiber 树在内存中构建完后，FiberRootNode 会将 Current 的指向从 Current Fiber 树移到 WorkInProgress Fiber 树。

在更新时，跟之前一样，只不过在构建 Fiber 树的时候会进行 Current Fiber 要跟返回的 JSX 结构进行比对即 Diff 算法，然后生产 WorkInProgress Fiber 树。
