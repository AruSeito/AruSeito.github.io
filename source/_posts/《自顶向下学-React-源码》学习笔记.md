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
---

## 理念篇

### 如何学？

将 React 完整的运行过程可以分为三个部分：产生更新、决定更新什么组件、将更新的组件渲染到页面。即：调度、协调、渲染。

### 设计理念

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

### 架构的演化

#### 老 React 的架构（15 及以前）

老 React 中可以分为两部分：决定渲染组件（协调器）-》将组件渲染到视图中（渲染器）。

协调器（Reconciler）中会进行 Diff 算法，算出哪些需要更新，然后将要更新的内容交给渲染器（Render）中。

问题：

协调器与渲染器是依次执行工作。如果同时更新多个节点，第一个 DOM 会先发生变化，但是因为更新过程是同步的，所以会同时渲染出来。如果在这种老的架构上实现异步可中断许安然的话，在渲染过程中发生中断，协调器和渲染工作还在继续，但是第一个组件会先渲染完，其他组件没变化，所以推出了 16 这种架构。

#### 新 React 的架构（16 及以后）

新 React 中分为三部分：调度更新（调度器）->决定更新什么（协调器）->将组件更新到视图中（渲染器）。

调度器会对更新项分配优先级，将高优先级的先交给协调器，接着创建虚拟 DOM，然后协调器进行 Diff 算法，给变化的 DOM 打上标记，再将更新的内容交给渲染器，由渲染器来执行视图操作，。如果在进行 Diff 的过程中来了新的更高优先级的更新项，则将正在 Diff 的更新项中断，先进行高优先级的 Diff。循环以上操作。因为这些操作都在内存中操作，用户并不会感知。（跟离线操作 DOM 一个意思）

### React 的新架构 ---- Fiber

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

##### 挂载时

1. 运行`ReactDom.render`会创建一个 `FiberRoot` 和 `rootFiber`。`FiberRoot` 是整个应用的根结点，有且仅有一个。然后 `FiberRoot` 的 `current` 指针会指向页面上已经渲染好了的 Fiber 树上（`FiberRoot.current = rootFiber`）。`fiberRoot` 的 `current` 会指向当前页面上已渲染内容对应 Fiber 树，即 `current Fiber 树`。因为是首屏渲染，所以 rootFiber 下并没有任何东西。

2. 进入`Render`阶段，根据组件的 JSX 创建 Fiber 树（`workInProgress Fiber`）。在创建的过程中会尝试复用`current fiber`上已有节点的属性。

3. 进入`Commit`阶段 ，将 current 指针指向 `workInProgress 树`，成为 `current Fiber 树`。

##### 更新时

1. 进入`Render`阶段，根据组件的 JSX 一棵新的 `workInProgress Fiber`。在创建的过程中会尝试复用`current fiber`上已有节点的属性。

2. `workInProgress Fiber 树`在`Render阶段`完成构建后进入`Commit阶段`渲染到页面上。渲染完毕后，`workInProgress Fiber 树`变为`current Fiber 树`。

## Render 阶段

Render 阶段指 调和器工作的阶段，主要是打标记（effectTag）是 Update 还是 Replace 等操作，并非指 Render 运行的阶段。Render 方法运行的阶段成为 Commit 阶段。

![三个阶段](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210808/三个阶段.png)

### 挂载时

用`CRA`创建一个最基础的 React 应用，用 devTool 录制一个从 0 到 1 的火炬图。

在 Render 阶段经历了如下：（可以在 beginWork 和 completeWork 打个断点看一下，看笔记想不起来记得再手动调试一次,记得对着 CRA 创建的 DEMO 代码看）

废话连篇:首先进入 BeginWork 的三个参数分别为 `current, workInProgress, renderLanes`。因为是首次运行，所以 current 的 Tag 为`3`，代表`HostRoot`，然后恢复脚本执行。又到了 BeginWork 的断点处，这时`current`为空,`workInProgress`的 ElementType 为`f APP()`。再放开`workInProgress`又变成`div`。再放开是`header`,然后再放开是`img`，这时候因为 img 没有任何子节点，所以再放开后到了 completeWork，执行完后，会再寻找 img 的兄弟节点，然后找到了 P 标签，进入`beginWork`，再找 P 的子节点，先`Edit `begin 再 completed，接着是`Code`，因为 Code 内的子节点是纯文本，所以直接采用优化方案，不会找子节点，直接进入`completeWork`,然后再是最后的文本`and save to reload.`，执行完后进入父节点的`completeWork`。

总结：根 beginWork->子节点 beginWork-如果有子节点->一直直行到最后一个子节点时，执行父节点的 completeWork; -如果子节点没有子节点->执行自己的 completeWork->然后找到兄弟元素。(深度优先遍历，遇到有唯一文本节点的，不会创建他的 Fiber 节点)

专业总结:首先从`rootFiber`开始向下深度优先遍历,为遍历到的每个 Fiber 节点调用`beginWork`方法。当遍历到没有子组件的组件时就会进入“归”阶段。在归阶段调用`completeWork`,当某个 Fiber 节点执行完`completeWork`，如果其存在兄弟 Fiber 节点（即 fiber.sibling !== null），会进入其兄弟 Fiber 的“递”阶段。如果不存在兄弟 Fiber，会进入父级 Fiber 的“归”阶段。“递”和“归”阶段会交错执行直到“归”到 rootFiber。至此，render 阶段的工作就结束了。

[卡颂老师的 DEMO](https://react.iamkasong.com/process/reconciler.html#%E4%BE%8B%E5%AD%90)

为什么 EffectTag 是用二进制？ 因为如果要插入一个元素到页面中，然后还要替换他的属性，那就要标记成 Update 和 Placement。用二进制可以很快的进行标记。

```javascript
const NoFlags = /*                      */ 0b00000000000000000000000;

const Placement = /*                    */ 0b00000000000000000000010;

const Update = /*                       */ 0b00000000000000000000100;

const PlacementAndUpdate = /*           */ Placement | Update;

// 首先有个元素,初始状态为没变化
let effectTag = NoFlags;

// 先插入，按位或
effectTag |= Placement; //2 === 0b00000000000000000000010
// 然后更新
effectTag |= Update; // 6 === 0b00000000000000000000110

(effectTag & PlacementAndUpdate) !== NoFlags; //True
```

#### 流程

beginWork：当一个节点进入 beginWork 时，目的是为了创建当前 Fiber 节点的第一个子 Fiber 节点，判断当前 Fiber 节点的类型，进入不同的 Update 逻辑。在进入 Update 逻辑后，会先判断 WorkInProgress Fiber 中是否有对应的 Current Fiber，来决定是否标记 EffectTag（在 17.0.3 中更名为 ReactFiberFlags），接着判断当前 Fiber 节点的 child 的类型，来执行不同的创建操作，创建不同的子 Fiber 节点。

completeWork：根据 WorkInProgress 的 tag，进入不同操作。首先为 Fiber 节点创建对应的 DOM 节点， 然后挂到 Fiber 节点的 StateNode （已经构建好的 DOM 树）上。然后将 DOM 节点插入到之前创建好的 DOM 树中，然后初始化 DOM 对象的属性。

![beginWork](https://react.iamkasong.com/img/beginWork.png)
![completeWork](https://react.iamkasong.com/img/completeWork.png)

### 更新时

### 流程

beginWork：先判断是否可以复用，如果可以复用直接 Clone 在 current 中对应的 Fiber 节点。如果不能复用，判断当前 Fiber 节点的类型，进入不同的 Update 逻辑，在这里面会使用 JSX 对象与 current Fiber 节点进行对比，将对比的结果创建一个 fiber 节点并返回。

completeWork：先 diff props，返回一个需要更新的属性名称构成的数组（[key1，value1,key2,value2...]）然后赋值给 workInpProgress.updateQueue，最后再将 effectTag 的 fiber 挂载在父级 fiber 的 effectList 末尾，并返回 workInProgress Fiber 树。

作为 DOM 操作的依据，commit 阶段需要找到所有有 effectTag 的 Fiber 节点并依次执行 effectTag 对应操作？

每个执行完 completeWork 且存在 effectTag 的 Fiber 节点会被保存在一条被称为 effectList 的单向链表中。effectList 中第一个 Fiber 节点保存在 fiber.firstEffect，最后一个元素保存在 fiber.lastEffect。类似 appendAllChildren，在“归”阶段，所有有 effectTag 的 Fiber 节点都会被追加在 effectList 中，最终形成一条以 rootFiber.firstEffect 为起点的单向链表。这样，在 commit 阶段只需要遍历 effectList 就能执行所有 effect 了。

- 注意：近期 React 团队有在重构 Effect List（v18），老的会生成 Effect List，然后在 commit 阶段，直接遍历 EffectList 就能找到所有副作用的节点并执行对应的操作。在重构会会将子节点的副作用冒泡到父节点的 SubtreeFlags 属性。详细可见卡老师的另外一篇文章[React Effects List 大重构，是为了他？](https://mp.weixin.qq.com/s/-UNN45YttXJPA2TlrnSy3Q)

## Commit 阶段

![2021/12/05/20211205130037](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2021/12/05/20211205130037.png)
主要工作分为三部分：

- before mutation 阶段（执行 DOM 操作前）

- mutation 阶段（执行 DOM 操作）

- layout 阶段（执行 DOM 操作后）

### beforeMutation 阶段

1. 遍历 effectList 并调用`commitBeforeMutationEffects`函数处理

2. commitBeforeMutationEffects 处理有三步

   1. 处理 DOM 节点渲染/删除后 focus 和 blur 逻辑

   2. 如果是类组件会调用`getSnapshotBeforeUpdate`生命周期：通过`finishedWork.stateNode`取得对应 Fiber 节点的原型。如果是函数组件会直接 return 出去。

   3. 调度`useEffect`：如果是函数组件，并且他的`useEffect`被标记为`Passive` 会在这调度。以 NormalSchedulerPriority 为优先级，异步执行`flushPassiveEffects`（也就是`useEffect`的回调函数），由于`commit`阶段是同步执行的，所以`useEffect`的回调函数是在 commit 阶段执行完执行的。

### mutation 阶段

1. 遍历 effectList，并调用`commitMutationEffects`

2. `commitMutationEffects`会遍历 effectList，对每个 Fiber 节点执行如下三个操作：

   1. 根据 ContentReset effectTag 重置文字节点

   2. 更新 ref（对应生命周期图中的 更新 DOM 和 refs）

   3. 根据 effectTag 分别处理，其中 effectTag 包括（Placement | Update | Deletion | Hydrating）

#### Placement effect

当 Fiber 节点含有 Placement effectTag，意味着该 Fiber 节点对应的 DOM 节点需要插入到页面中。调用 commitPlacement

1. 向上递归获取该 Fiber 节点的父级 Fiber 节点。

2. 根据 fiber 节点找到对应的 DOM 节点（通过 fiber 节点上的 stateNode 属性），然后根据 Fiber 的 Tag 判断是不是 container（HostRoot 和 HostPortal 标记为 true，HostComponent 和 FundamentalComponent 标记为 false）

3. 获取该 Fiber 节点的兄弟 DOM。

4. 根据 DOM 兄弟节点存在决定调用`insertBefore` 或`appendChild`执行 DOM 插入操作

- getHostSibling（获取兄弟 DOM 节点）的执行很耗时，当在同一个父 Fiber 节点下依次执行多个插入操作，getHostSibling 算法的复杂度为指数级。

这是由于 Fiber 节点不只包括 HostComponent，所以 Fiber 树和渲染的 DOM 树节点并不是一一对应的。要从 Fiber 节点找到 DOM 节点很可能跨层级遍历。

#### Update effect

当 Fiber 节点含有 Update effectTag，意味着该 Fiber 节点需要更新。调用的方法为 commitWork，他会根据 Fiber.tag 分别处理。

当 fiber.tag 为 FunctionComponent，会调用 commitHookEffectListUnMount。该方法会遍历 effectList，执行所有 useLayoutEffect hook 的销毁函数。

当 fiber.tag 为 HostComponent，会调用 commitUpdate，更新 Props 和 DOM 的属性。最终会在 updateDOMProperties 中将 render 阶段 completeWork 中为 Fiber 节点赋值的 updateQueue 对应的内容（diff 的结果）渲染在页面上。

#### PlacementAndUpdate effect

先执行 placement effect 的内容，再执行 Update effect 的内容

#### Deletion effect

当 Fiber 节点含有 Deletion effectTag，意味着该 Fiber 节点对应的 DOM 节点需要从页面中删除。调用的方法为 commitDeletion。

1. 如果是`HostComponent`或`HostText`,递归查找的，首先找到它的父级 Fiber 节点，然后在找到它的子孙节点（因为这个整体相当于一个树，消除一个节点，他的下级也要被销毁）。然后调用`commitUnmount`。

2. 如果是函数组件及其相似的，遍历 effectList，进行注册 useEffect 的回调（将 fiber 节点和 effect 的回调放到一个 unmountEffects 队列中）进行调度。

3. 如果是类组件，会解绑 Ref，然后调用生命周期中的 componentWillUnmount

4. 如果是 `HostComponent`，会解绑 Ref

### mutation 阶段之后 Layout 阶段之前

在这里会执行双缓存的原理，将 current 指针从 current 树，指向 workInProgress 树。

为什么在这里执行？

简单说就是为了确保每个阶段的树能对应上。

因为 mutation 阶段时需要执行 componentWillUnmount，需要操作 current 树，而 layout 阶段要执行 componentDidMount/Update，需要跟新的 current 树对应上

卡老师总结版：componentWillUnmount 会在 mutation 阶段执行，此时 current Fiber 树还指向前一次更新的 Fiber 树，在生命周期钩子内获取的 DOM 还是更新前的。componentDidMount 和 componentDidUpdate 会在 layout 阶段执行。此时 current Fiber 树已经指向更新后的 Fiber 树，在生命周期钩子内获取的 DOM 就是更新后的。

### Layout 阶段

Layout 阶段也是遍历 effectList，执行 commitLayoutEffects 方法。

1. 如果是函数组件会执行`useLayoutEffect`，如果是类组件会根据 current 有无来判断执行`componentDidMount`还是`componentDidUpdate`，并且还会生成会取一个`updateQueue`，这里存放的其实是 setState 的第二个参数，依赖于未更新前的 dom 属性来操作，也是在这调用的。如果`HostRoot`，也会有一个`updateQueue`，存放的是 render 的第三个参数。

2. hostComponent 或 class Component 存在 Ref 时，处理 Ref。

#### UseEffect 和 UseLayoutEffect 区别

|                   |                  useEffect                   | useLayoutEffect |
| :---------------: | :------------------------------------------: | :-------------: |
|  beforeMutation   |           调度 flushPassiveEffects           |       无        |
|     mutation      |                      无                      |  执行 destroy   |
|      layout       |            注册 destroy 和 create            |   执行 create   |
| commit 阶段完成后 | 执行 flushPassiveEffects，内部执行注册的回调 |       无        |

### useEffect 的异步调用

1. `before mutation`阶段在`scheduleCallback`中调度`flushPassiveEffects`（对应的本文`beforeMutation`阶段的第三步）

2. `layout` 阶段之后将 `effectList` 赋值给 `rootWithPendingPassiveEffects`

3. `scheduleCallback` 触发 `flushPassiveEffects`， `flushPassiveEffects` 内部遍历 `rootWithPendingPassiveEffects`

#### 为什么需要异步调用`useEffect`？

> 与 componentDidMount、componentDidUpdate 不同的是，在浏览器完成布局与绘制之后，传给 useEffect 的函数会延迟调用。这使得它适用于许多常见的副作用场景，比如设置订阅和事件处理等情况，因此不应在函数中执行阻塞浏览器更新屏幕的操作。

所以`useEffect`主要是防止同步执行时阻塞浏览器渲染。

## Diff 算法

![2021/12/05/20211205222940](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2021/12/05/20211205222940.png)

与 DOM 节点有关的概念：

1. current Fiber。如果该 DOM 节点已在页面中，current Fiber 代表该 DOM 节点对应的 Fiber 节点

2. workInProgress Fiber。如果该 DOM 节点将在本次更新中渲染到页面中，workInProgress Fiber 代表该 DOM 节点对应的 Fiber 节点。

3. DOM 节点本身。

4. JSX 对象。即 ClassComponent 的 render 方法的返回结果，或 FunctionComponent 的调用结果。JSX 对象中包含描述 DOM 节点的信息。

diff 的本质就是比较 1 和 4，然后生产 2。

为了降低时间复杂度，React 的 diff 算法有三个限制

1. 只比较同级的元素。如果前后两次中某节点跨级了，那么 React 不会复用。

2. 只比较相同类型的节点。如果元素由 div 变为 p，React 会销毁 div 及其子孙节点，并新建 p 及其子孙节点。

3. 开发者通过 key 来保持稳定。

### diff 如何实现？

`reconcileChildFibers`函数会根据 newChild（即 JSX 对象）类型调用不同的处理函数。

1. 当 newChild 类型为 object、number、string，代表同级只有一个节点

2. 当 newChild 类型为 Array，同级有多个节点

#### 单节点时

- 如果 currentFiber 树中存在对应的节点并遍历。

  - 如果 key 相同，type 相同，标记它的兄弟节点为 Deletion。再复用老的 Fiber，然后 return 出去

  - 如果 key 相同，type 不同，先标记它及其兄弟为 Deletion，跳出循环，再根据 JSX 对象创建一个新的 Fiber 节点

- 如果 currentFiber 树中不存在对应的节点，直接根据 JSX 对象创建一个新 Fiber 节点。

卡老师总结版：

上次更新时的 fiber 节点是否存在相应的 DOM 节点，如果不存在，则新生成一个 Fiber 节点，如果存在则判断该节点是否可以复用，如果不能复用则标记 DOM 需要被删除，然后生成一个新 Fiber 节点。如果可以复用，则将上次更新的 Fiber 节点的副本作为本次新生成的 Fiber 节点并返回。

- 如何判断 DOM 节点是否可以复用？

React 通过先判断 key 是否相同，如果 key 相同则判断 type 是否相同，只有都相同时一个 DOM 节点才能复用。key 相同且 type 不同时执行 deleteRemainingChildren 将 child 及其兄弟 fiber 都标记删除。key 不同时仅将 child 标记删除。

#### 多节点时

有两种情况（一个 ul 下面有多个 li；一个 ul 下面多个 li 是使用 map 出来的），其实流程是一样的。

注意：提到的老 Fiber 树其实是本层中兄弟节点构成的链表。

注意： 因为层级比较深，可能markdown解析出来的不太方便看，请结合该章节头部的图来看。

1. 同时遍历新 jsx 对象数组，老 Fiber 树。

   1. 复用判断
      - 如果key相同且type（就是标签相同）相同，复用之前的Fiber，并返回。
      - 如果key相同且type不同，根据jsx对象创建新Fiber并返回。
      - 如果key不同，返回null，并跳出循环。
   2. 将老的 Fiber 标为 deletion
   3. 将新的 Fiber 节点标为 placement，并记录最后一个可复用的节点在老 Fiber 树中的位置索引。
      1. 记录新 Fiber 的位置（即在 jsx 对象数组中的索引）
      2. 判断新Fiber是否为复用的
         - 是
           1. 拿到老Fiber节点的位置
           2. 如果老位置小于新位置（表示新Fiber节点右移了），则新的Fiber节点被标记为placement，并返回最后一个可复用的节点在老Fiber树中的位置索引。
           3. 如果老位置大于等于新位置，则直接返回老位置（不会标记为placement）
           4. 注：老位置大于新位置表示要由老位置左移得到新位置，但是React中仅进行右移操作，前面的元素右移后，自己自然被顶到前面去了，实现了左移的效果，相当于变相实现了左移。（关于在React中仅进行右移操作请看[精读《DOM diff 原理详解》](https://github.com/ascoders/weekly/blob/master/%E5%89%8D%E6%B2%BF%E6%8A%80%E6%9C%AF/190.%E7%B2%BE%E8%AF%BB%E3%80%8ADOM%20diff%20%E5%8E%9F%E7%90%86%E8%AF%A6%E8%A7%A3%E3%80%8B.md)）
         - 否，直接标记为placement

2. 如果新 jsx 对象数组遍历完了（即删除节点了），标记没有遍历过的老 Fiber 节点为deletion，然后返回一棵新树（即 workInProgress Fiber 树）
3. 如果老 Fiber 树遍历完了且新 jsx 对象数组没遍历完（即新增节点了），遍历剩下的 jsx 对象数组。

   1. 创建新 Fiber 节点
   2. 将新的 Fiber 节点标为 placement，并记录最后一个可复用的节点在老 Fiber 树中的位置索引。
   3. 插入到新 Fiber 树中
   4. 返回 workInProgress Fiber 树。

4. 如果 jsx 对象数组没遍历完且老 Fiber 树也没遍历完（即没增没减）
   1. 新建一个以老 Fiber 节点的 key 或者 index 为索引，老 Fiber 节点为 value 的 map
   2.  遍历 jsx 对象数组，根据 jsx 对象的 key 或者 index 为索引，在 map 中找老 Fiber 节点
   3. 如果老 Fiber 节点和 jsx 对象的 type 相同，则复用并返回新 Fiber 节点，如果不相同，则返回 null
   4. 如果返回的新 Fiber 节点不为 null，则将新的 Fiber 节点标记为 placement 并记录位置，然后插入到新的 Fiber 树中
   5. 如果 map 中还有剩余，就将剩下的全都标记为Deletion

5. 返回 workInProgress Fiber 树。

##### 卡老师总结版

会进行两轮遍历。第一轮遍历处理更新的元素。第二轮遍历处理不属于更新的节点。

- 为什么不用双指针优化？

因为同级的 Fiber 节点间是用 sibling 指针连接形成的单链表。

第一轮遍历的过程：

1. `let i = 0`，遍历`newChildren`，将`newChildren[i]`与`oldFiber`比较，判断 DOM 节点是否可复用。

2. 如果可复用，i++，继续比较`newChildren[i]`与`oldFiber.sibling`，可以复用则继续遍历。

3. 如果不可复用，分两种情况：

   - key 不同导致不可复用，立即跳出整个遍历，第一轮遍历结束。

   - key 相同 type 不同导致不可复用，会将 oldFiber 标记为 DELETION，并继续遍历

4. 如果`newChildren`遍历完（即`i === newChildren.length - 1`）或者`oldFiber`遍历完（即`oldFiber.sibling === null`），跳出遍历，第一轮遍历结束。

第一轮遍历结束有两种结果：

第一种从 3 跳出来的：`newChildren`没遍历完`oldFiber`没遍历完

第二种从 4 跳出来的：`newChildren`没遍历完`oldFiber`遍历完（相当于有新增），`oldFiber`没遍历完`newChildren`遍历完（相当于有删减），`newChildren`和`oldFiber`都遍历完（相当于没增没减）

带着上面的结果进行第二轮遍历

如果`newChildren`和`oldFiber`都遍历完，最理想情况，只在第一轮遍历进行更新。Diff 结束。

如果`newChildren`没遍历完`oldFiber`遍历完，有新节点插入，遍历剩下的`newChildren`为生成的`workInProgress fiber`依次标记`Placement`。

如果`oldFiber`没遍历完`newChildren`遍历完，有节点被删了，遍历剩下的`oldFiber`，一次标记`Deletion`

如果`newChildren`没遍历完`oldFiber`没遍历完，有节点变换了位置。将所有没处理的`oldFiber`存入以`key`为 key，`oldFiber`为 value 的 map 中。然后遍历剩余的`newChildren`，通过`newChildren[i].key`就能在`existingChildren`中找到 key 相同的 oldFiber。先标记最后一个可复用节点的位置，然后保存老节点的位置。两个位置信息比较。如果老位置<最后一个可复用节点的位置，则 该节点 向右移动。如果老位置>=最后一个可复用节点的位置，则该节点不动，然后可复用节点的位置变更为该老位置。

例子

```
abcd->adbc（key和value都为表示的这个）

在第一轮遍历的时候保存得到，a是最后可复用节点,用lastChangeIndex保存改位置:0。剩余的newChildren = dbc , 剩余的oldFiber= bcd。
遍历剩余的newChildren，第一个为d，key也是d。在oldFiber中的位置为oldIndex = 3。 因为oldIndex(3)>=lastChangeIndex(0)，则该点不动，将lasChangeIndex = 3。
剩余的newChildren = bc , 剩余的oldFiber= bc。第二个为b，在oldFiber中的位置为oldIndex = 1。因为oldIndex(1)<lastChangeIndex(3)，所以将该点右移。
剩余的newChildren = c , 剩余的oldFiber= c。最后一个为c，在oldFiber中的位置为oldIndex = 2。oldIndex(2)<lastChangeIndex(3)，所以将该点右移。
```

## 状态更新

### 触发更新的方法

- ReactDOM.render

- this.setState

- this.forceUpdate

- useState

- useReducer


这么多方法如何接入同一种更新机制？

在各自的处理方法里处理出来一个update对象，通过这个update对象进入统一的更新流程

### 流程大纲

0. 触发状态更新（根据场景调用不同方法）

1. 创建update对象

2. 从触发状态更新的`fiber`一直向上遍历到`rootFiber`。

3. 调度更新

4. render阶段

5. commit阶段


### 优先级与Update

```js
// 初始化的无优先级
export const NoPriority = 0;
// 立刻执行的优先级，最高优先级，同步的优先级
export const ImmediatePriority = 1;
// 用户触发的更新，如点击事件
export const UserBlockingPriority = 2;
// 一般优先级，最常见的，如请求数据后setState
export const NormalPriority = 3;
// 低优先级
export const LowPriority = 4;
// 空闲优先级
export const IdlePriority = 5;
```

状态计算公式： `baseState + Update1 + Update2 = newState`。

假设 update1 为 NormalPriority ，update2 为 UserBlockingPriority 。

计算状态的时候会先计算`baseState+update2`得到一个中间状态，然后再去计算`update1`。

#### 更新过程

1. 创建更新
2. 从触发更新的节点向上递归查找，直到找到FiberRootNode
3. 在FiberRootNode上保存对应优先级
4. 以对应优先级调度FiberRootNode。
5. 触发对应的回调函数（render阶段入口）
6. 从FiberRootNode深度优先遍历对路径上的节点进行Diff。
7. 如果有高优先级进来，会先打断之前优先级过程，优先执行高优先级的。

### update计算

ReactDOM.render（同步更新）：按照顺序排成队更新，就好比正常情况下程序进行迭代升级 从1.0->1.1->1.2

ReactDOM.createBlockingRoot和ReactDOM.createRoot（并发更新）：打断现在的过程，先进行优先级高的，比如线上遇到紧急BUG，那得先暂存当前过程，切换到main分支，进行修复后再rebase一下。



### update类型

- ReactDOM.render —— HostRoot
- this.setState —— ClassComponent
- this.forceUpdate —— ClassComponent
- useState —— FunctionComponent
- useReducer —— FunctionComponent

由于不同类型组件工作方式不同，所以存在两种不同结构的`Update`，其中`ClassComponent`与`HostRoot`共用一套`Update`结构，`FunctionComponent`单独使用一种`Update`结构。



#### HostRoot及ClassComponent

#### ClassComponent的update对象

```typescript
const update: Update<*> = {
    eventTime, // 任务时间
    lane, // 优先级相关
    tag: UpdateState, // 更新的类型，包括UpdateState | ReplaceState | ForceUpdate | CaptureUpdate。
    payload: null, //更新挂载的数据，不同类型组件挂载的数据不同。对于ClassComponent，payload为this.setState的第一个传参。对于HostRoot，payload为ReactDOM.render的第一个传参。
    callback: null,// 更新的回调函数，setState的第二个参数，ReactDom.render的第三个参数。对应layout阶段提到的回调函数
    next: null, // 指针，指向另外的update，构成链表
  };
```



#### update链表与Fiber节点有什么关系？

fiber节点的updateQueue存的就是这个update链表。

为什么要有链表？因为可能存在多个更新，比如在一个时间中我连续调用了三个setState。就会有三个update 或者 有多个优先级的update。

#### classComponent的updateQueue

```js
const queue: UpdateQueue<State> = {
    baseState: fiber.memoizedState, // 本次更新前的state，update会基于这个来计算newState
  // 之所以在更新产生前该`Fiber节点`内就存在`Update`，是由于某些`Update`优先级较低所以在上次`render阶段`由`Update`计算`state`时被跳过。
    firstBaseUpdate: null,//本次更新前该`Fiber节点`已保存的`Update`，链表头为`firstBaseUpdate`，
    lastBaseUpdate: null,// 本次更新前该`Fiber节点`已保存的`Update`，链表尾为`lastBaseUpdate`
    shared: { // 触发更新时，本次更新产生的`Update`会保存在`shared.pending`中形成单向环状链表。当由`Update`计算`state`时这个环会被剪开并连接在`lastBaseUpdate`后面。
      pending: null,
    },
    effects: null, // 数组。保存`update.callback !== null`的`Update`。
  };
```

#### update计算过程

`ReactUpdateQueue.old.js的enqueueUpdate`过程

假设有两个更新u1和u2在上一次render时因为优先级不够并且u1->u2，那么这两个会作为下次的`baseUpdate`。

那么这时

```
queue.firstBaseUpdate = u1
queue.lastBaseUpdate = u2
```

如果此时再次触发了两个更新u3和u4。

当插入u3的时候 

```js
queue.shared.pending =  u3 ─────┐ 
                         ^      |                                    
                         └──────┘
												   
```

然后插入 u4的时候

```
queue.shared.pending = u4 ──> u3
                       ^      |                                    
                       └──────┘
```

然后进入 render阶段的 beginWork阶段

```
queue.lastBaseUpdate = u1(->u2->u3->u4)
queue.shared.pending = u4( -> u3)
```

并且也会在 currentFiber 树的对应fiber 节点上保存，确保 update 不会丢失。即`current.updateQueue.lastBaseUpdate = u1(->u2->u3->u4)`。然后再 render 阶段中断并重新开始的时候会再从`current`中 clone 出一份 lastBaseUpdate，如果在 commit 阶段中断并重新开始的时候会从`workInProgress树`上 clone 出一份 lastBaseUpdate

然后以 baseState 为初始状态并遍历 firstBaseUpdate 开始计算newState。在遍历时如果有优先级低的`Update`会被跳过，做出来一个`newFirstBaseUpdate` 和`newBaseState`作为下次更新用的。如果满足优先级条件，会先计算 newState，然后判断 update 的 callback 有没有，有的话就push到workInProgress 的 effect 里，然后移动 update 的 next 指针，如果这个时候 update 为空了，要判断一下`queue.shared.pending`是否为空，如果为空就跳出循环，如果没为空（在 setState 里又 setState 了一个）就执行一遍裁剪环那里的操作。

当遍历完成后判断newLastBaseUpdate是否为空，如果为空则将 newState 赋值给 `workInProgress.updateQueue` 的`baseState`，如果不为空的情况则说明本次 更新有 update 因为优先级不足被跳过了。遍历完成获得的 state就是该`Fiber节点`在本次更新的`state`（源码中叫做`memoizedState`）。



#### 如何保证状态依赖的连续性

```js
baseState: ''
shared.pending: A1 --> B2 --> C1 --> D2
```

其中`字母`代表该`Update`要在页面插入的字母，`数字`代表`优先级`，值越低`优先级`越高。

第一次`render`，`优先级`为1。

```js
baseState: ''
baseUpdate: null
render阶段使用的Update: [A1, C1]
memoizedState: 'AC'
```

其中`B2`由于优先级为2，低于当前优先级，所以他及其后面的所有`Update`会被保存在`baseUpdate`中作为下次更新的`Update`（即`B2 C1 D2`）。

这么做是为了保持`状态`的前后依赖顺序。

第二次`render`，`优先级`为2。

```js
baseState: 'A'
baseUpdate: B2 --> C1 --> D2 
render阶段使用的Update: [B2, C1, D2]
memoizedState: 'ABCD'
```

这里会以 baseState 为初始状态，按照 baseUpdate 的顺序计算，然后得到 memoizedState。

注意这里`baseState`并不是上一次更新的`memoizedState`。这是由于`B2`被跳过了。

即当有`Update`被跳过时，`下次更新的baseState !== 上次更新的memoizedState`。



React 不会保证中间状态即第一次 render 时的 memoizedState 正确，只会保证最终 render 的 memoizedStata 正确





### ReactDOM.render流程

1. 创建rootFiber和fiberRoot
2. 连接rootFiber与fiberRootNode（将fiberRoot的current指向rootFiber）
3. 初始化updateQueue
4. 创建update
5. 从fiber到rootFiber向上递归
6. 调度更新
7. render阶段
8. commit阶段

#### 与ReactDOM.createRoot().render的不同

1. reactDOM.render的lane是1，reactDOM.createRoot的lane是512对应的二进制
2. 在创建rootFiber时传参不一样。代表并发还是同步

### this.setState流程

1. 通过组件实例获取对应fiber
2. 获取优先级
3. 创建update
4. 赋值回调函数
5. 将update插入updateQueue
6. 调度update

## HOOK

### 极简useState 的实现

见[简易版useState](https://github.com/AruSeito/daily-practice/blob/main/others/useState/index.html)



useState 在不同运行时会调用不同的方法，比如 mont 时会调用`mountState`，update 时会调用`updateState`，对应的时简易版的 useState 内的`if(isMount)`的两块内容

其实 useReducer 和 useState 的实现方式是一样的，只不过 useState 在 return`dispatchAction.bind(baseReducer,queue)`时 预设传了一个 reducer。



### useEffect和 useLayout 的实现



同 useState 一样，在 mount 时会调用`mountEffect`,在 update 时会调用`updateEffect`

1. 获取当前 hook 对应的数据

   ```typescript
   const hook: Hook = {
       memoizedState: null,
   
       baseState: null,
       baseQueue: null,
       queue: null,
   
       next: null,
   }
   ```

2. 获取依赖项

3. 标记 flag，useEffect 和 useLayoutEffect 的 flag 是不同的

4. mout 时和 update 的单独操作

   - mount 时，保存 hook 的最后一个 effect 到 hook 的 memoizedState
   - update 时
     1. 取出上一次的 effect，取出上一次 effect 的销毁函数，取出上一次的依赖
     2. 浅比较上一次的依赖和这次的依赖，pushEffect 进去时传入不同的 flag

为什么销毁函数在 update 时取？

因为只有effect 的 create 执行完之后才会有 destroy。

为什么依赖改变了也要 pushEffect 进去？

因为 所有 effect 都是存在 fiber 节点上的一条环状单向链表上的，顺序是不变的。



### useRef的实现

基本流程和上面的两种 hook 一样。

mount 时

1. 通过`mountWorkInProgressHook`获得当前 hook 的数据
2. 把 initialState 挂到current 下
3. 把 ref挂到 `hook.memoizedState`下
4. 把 ref 返回出去

update 时

1. 通过`mountWorkInProgressHook`获得当前 hook 的数据
2. 返回`hook.memoizedState`

classComponet 中 createRef的实现

创建一个包含`currentd`的对象并返回。



#### ref 的工作流程

##### render 阶段（为含有`ref`属性的`fiber`添加`Ref effectTag`）

- 首屏渲染时（`*current* === null && ref !== null`)
- update 时（`*current* !== null && *current*.ref !== ref`)

以上两种情况会进入逻辑，给`fiber`标记上 Ref effectTag

##### commit 阶段（为包含`Ref effectTag`的`fiber`执行对应操作）

- 首屏渲染时，会在 commit 阶段的layout 阶段，判断有没有被标记上 Ref effectTag，被标记了的话就会进入不同类型的组件方法获取实例并赋值上去。如果 ref 时函数类型的话，会先执行得出结果再赋值给ref.current。

- update 时

  - mutation阶段时，对于`ref`属性改变的情况，需要先移除之前的`ref`。

  - 对于`Deletion effectTag`的`fiber`（对应需要删除的`DOM节点`），需要递归他的子树，对子孙`fiber`的`ref`执行类似`commitDetachRef`的操作。
  - 在 commitDetachRef 中，如果 ref 时函数类型的，会先执行一次该函数，再进行解绑。



### useCallback 和 useMemo 的实现

mount 时

1. 通过`mountWorkInProgressHook`获得当前 hook 的数据
2. 获取依赖项
3. 获取计算结果（useCallback 不会有这一步，update 时同理）
4. 将`[计算结果,依赖]`保存到`hook.memoizedState`（useCallback 会`[callback,依赖]`存上，update 时同理）
5. 返回计算结果

update 时

1. 通过`mountWorkInProgressHook`获得当前 hook 的数据
2. 获取依赖项
3. 获取上一次计算结果与依赖`hook.memoizedState`
4. 浅比较上一次的依赖与一下次的依赖，如果相等就返回上一次的结果
5. 如果不想当，就获取新的计算结果
6. 将`[计算结果,依赖]`保存到`hook.memoizedState`
7. 返回计算结果

## concurrent Mode

### scheduler的工作原理及实现

scheduler 的作用：

- 时间切片
- 优先级调度

#### 时间切片原理

时间切片本质是模拟实现requestIdelCallback 



除去“浏览器重排/重绘”，浏览器中一帧可执行 js 的时机

```js
一个task(宏任务) -- 队列中全部job(微任务) -- requestAnimationFrame -- 浏览器重排/重绘 -- requestIdleCallback
```

`requestIdleCallback`是在“浏览器重排/重绘”后如果当前帧还有空余时间时被调用的。

浏览器并没有提供其他`API`能够在同样的时机（浏览器重排/重绘后）调用以模拟其实现。

唯一能精准控制调用时机的`API`是`requestAnimationFrame`，他能让我们在“浏览器重排/重绘”之前执行`JS`。

所以，退而求其次，`Scheduler`的`时间切片`功能是通过`task`（宏任务）实现的。

最常见的`task`当属`setTimeout`了。但是有个`task`比`setTimeout`执行时机更靠前，那就是[MessageChanne](https://developer.mozilla.org/zh-CN/docs/Web/API/MessageChannel)。

`Scheduler`将需要被执行的回调函数作为`MessageChannel`的回调执行。如果当前宿主环境不支持`MessageChannel`，则使用`setTimeout`。

在`React`的`render`阶段，开启`Concurrent Mode`时，每次遍历前，都会通过`Scheduler`提供的`shouldYield`方法判断是否需要中断遍历，使浏览器有时间渲染

是否中断的依据，最重要的一点便是每个任务的剩余时间是否用完。

在`Schdeduler`中，为任务分配的初始剩余时间为`5ms`。

随着应用运行，会通过`fps`动态调整分配给任务的可执行时间。



#### 优先级调度的实现

`runWithPriority`接受一个`优先级`与一个`回调函数`，在`回调函数`内部调用获取`优先级`的方法都会取得第一个参数对应的`优先级`

scheduler有五种优先级

```js
ImmediatePriority:
UserBlockingPriority:
NormalPriority:
LowPriority:
IdlePriority:
```

在`React`内部凡是涉及到`优先级`调度的地方，都会使用`runWithPriority`。

不同`优先级`意味着不同时长的任务过期时间，优先级越高越快过期，越先执行

#### 不同优先级的排序

按照过期时间，可以将任务分为两类

- 已就绪任务
- 未就绪任务

所以 scheduler 存在两个队列

- timerQueue：保存未就绪任务
- taskQueue：保存已就绪任务

每当有新的未就绪的任务被注册，我们将其插入`timerQueue`并根据开始时间重新排列`timerQueue`中任务的顺序。

当`timerQueue`中有任务就绪，即`startTime <= currentTime`，我们将其取出并加入`taskQueue`。

取出`taskQueue`中最早过期的任务并执行他：当注册的回调函数执行后的返回值`continuationCallback`为`function`，会将`continuationCallback`作为当前任务的回调函数。如果返回值不是`function`，则将当前被执行的任务清除出`taskQueue`。

为了能在O(1)复杂度找到两个队列中时间最早的那个任务，`Scheduler`使用[小顶堆 ](https://www.cnblogs.com/lanhaicode/p/10546257.html)实现了`优先级队列`。

### Lane 模型的实现

卡老师总结：[Lane模型的实现](https://react.iamkasong.com/concurrent/lane.html)

### 异步可中断更新与饥饿问题

如果低优先级的更新一直被高优先级的更新打断，随着时间的推移，低优先级的更新会过期，这个时候会被设为 `同步优先级`，来解决饥饿问题。



在`workLoopConcurrent`方法内，会使用`!shouldYeid`来判断当前时间片是否用尽。

在 `scheduler.js`中有个`workLoop`方法会取到当前被执行任务的 callBack，然后判断 callBack类型，如果是函数，会执行callBack，然后在判断 callback 的执行结果是否还是为 function，如果还是 function ，会把这个执行结果赋值给当前任务的 callback 然后再次调度这个 task，如果不是了，就考虑从小顶堆中剔除出去，高优先级中断低优先级任务的逻辑之一。



### batchedUpdates的实现

react 的内部优化方法。用来合并 update的。

老版本的实现：在`ReactFiberWorkLoop.old.js`下的`unbatchedUpdates`方法

获取 setState 时的上下文，当获取到的上下文包含`BatchedContext`时，不会马上触发更新，在事件回调结束时，才会触发更新。

缺陷：

都是同步的操作。比如：如果给这个事件回调将 setState 做异步调用时，就不会生效了。

因为异步调用后，他已经脱离了当前的上下文。

新版本的实现：在`ReactFiberWorkLoop.old.js`下的`ensureRootIsScheduled`方法

基于 lane 模型实现，第一个setState 进去的时候按照正常的流程安排调度，第二个 setState 进去的时候因为这两个优先级分配的都是一样的就直接 return 出去了，所以第二次调度就不会调度回调函数了（也就是进入 render 阶段的函数了）

关键点在于他们的 lane 是相同的。相同 lane 的条件：

- 相同的优先级
- 当前事件的 lanes 相同（`currentEventWipLanes`)

### 高优先级更新如何插队

1. 先取消掉低优先级的callback
2. 在 render 阶段通过 prepareFreshStack 取消低优先级带来的影响。
3. 调度高优先级的任务
4. 再调度低优先级的任务













