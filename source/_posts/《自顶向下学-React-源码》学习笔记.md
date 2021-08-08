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

## Render 阶段

Render 阶段指 调和器工作的阶段，主要是打标记（effectTag）是 Update 还是 Replace 等操作，并非指 Render 运行的阶段。Render 方法运行的阶段成为 Commit 阶段。

![三个阶段](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210808/三个阶段.png)

用`CRA`创建一个最基础的 React 应用，用 devTool 录制一个从 0 到 1 的火炬图。

在 Render 阶段经历了如下：（可以在 beginWork 和 completeWork 打个断点看一下，看笔记想不起来记得再手动调试一次,记得对着 CRA 创建的 DEMO 代码看）

废话连篇:首先进入 BeginWork 的三个参数分别为 `current, workInProgress, renderLanes`。因为是首次运行，所以 current 的 Tag 为`3`，代表`HostRoot`，然后恢复脚本执行。又到了 BeginWork 的断点处，这时`current`为空,`workInProgress`的 ElementType 为`f APP()`。再放开`workInProgress`又变成`div`。再放开是`header`,然后再放开是`img`，这时候因为 img 没有任何子节点，所以再放开后到了 completeWork，执行完后，会再寻找 img 的兄弟节点，然后找到了 P 标签，进入`beginWork`，再找 P 的子节点，先`Edit `begin 再 completed，接着是`Code`，因为 Code 内的子节点是纯文本，所以直接采用优化方案，不会找子节点，直接进入`completeWork`,然后再是最后的文本`and save to reload.`，执行完后进入父节点的`completeWork`。

总结：根 beginWork->子节点 beginWork-如果有子节点->一直直行到最后一个子节点时，执行父节点的 completeWork; -如果子节点没有子节点->执行自己的 completeWork->然后找到兄弟元素。

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

completeWork：根据 WorkInProgress 的 tag，进入不同操作。首先为 Fiber 节点创建对应的 DOM 节点， 然后挂到 Fiber 节点的 StateNode 上。然后将 DOM 节点插入到之前创建好的 DOM 树中，然后初始化 DOM 对象的属性。

![beginWork](https://react.iamkasong.com/img/beginWork.png)
![completeWork](https://react.iamkasong.com/img/completeWork.png)

作为 DOM 操作的依据，commit 阶段需要找到所有有 effectTag 的 Fiber 节点并依次执行 effectTag 对应操作？

每个执行完 completeWork 且存在 effectTag 的 Fiber 节点会被保存在一条被称为 effectList 的单向链表中。effectList 中第一个 Fiber 节点保存在 fiber.firstEffect，最后一个元素保存在 fiber.lastEffect。类似 appendAllChildren，在“归”阶段，所有有 effectTag 的 Fiber 节点都会被追加在 effectList 中，最终形成一条以 rootFiber.firstEffect 为起点的单向链表。这样，在 commit 阶段只需要遍历 effectList 就能执行所有 effect 了。

## Commit 阶段

主要工作分为三部分：

- before mutation 阶段（执行 DOM 操作前）

- mutation 阶段（执行 DOM 操作）

- layout 阶段（执行 DOM 操作后）

### beforeMutation 阶段

1. 遍历 effectList 并调用`commitBeforeMutationEffects`函数处理

2. commitBeforeMutationEffects 处理有三步

   1. 处理 DOM 节点渲染/删除后 focus 和 blur 逻辑

   2. 调用`getSnapshotBeforeUpdate`生命周期

   3. 调度`useEffect`。

为什么需要异步调用`useEffect`？

> 与 componentDidMount、componentDidUpdate 不同的是，在浏览器完成布局与绘制之后，传给 useEffect 的函数会延迟调用。这使得它适用于许多常见的副作用场景，比如设置订阅和事件处理等情况，因此不应在函数中执行阻塞浏览器更新屏幕的操作。

所以`useEffect`主要是防止同步执行时阻塞浏览器渲染。

### mutation 阶段

1. 遍历 effectList，并调用`commitMutationEffects`

2. `commitMutationEffects`会遍历 effectList，对每个 Fiber 节点执行如下三个操作：

   1. 根据 ContentReset effectTag 重置文字节点

   2. 更新 ref

   3. 根据 effectTag 分别处理，其中 effectTag 包括（Placement | Update | Deletion | Hydrating）

#### Placement effect

当 Fiber 节点含有 Placement effectTag，意味着该 Fiber 节点对应的 DOM 节点需要插入到页面中。调用 commitPlacement

1. 获取该 Fiber 节点的父级 DOM。

2. 获取该 Fiber 节点的兄弟 DOM。

3. 根据 DOM 兄弟节点存在决定调用`insertBefore` 或`appendChild`执行 DOM 插入操作

- getHostSibling（获取兄弟 DOM 节点）的执行很耗时，当在同一个父 Fiber 节点下依次执行多个插入操作，getHostSibling 算法的复杂度为指数级。

这是由于 Fiber 节点不只包括 HostComponent，所以 Fiber 树和渲染的 DOM 树节点并不是一一对应的。要从 Fiber 节点找到 DOM 节点很可能跨层级遍历

#### Update effect

当 Fiber 节点含有 Update effectTag，意味着该 Fiber 节点需要更新。调用的方法为 commitWork，他会根据 Fiber.tag 分别处理。

当 fiber.tag 为 FunctionComponent，会调用 commitHookEffectListUnMount。该方法会遍历 effectList，执行所有 useLayoutEffect hook 的销毁函数。

当 fiber.tag 为 HostComponent，会调用 commitUpdate。最终会在 updateDOMProperties （opens new window）中将 render 阶段 completeWork （opens new window）中为 Fiber 节点赋值的 updateQueue 对应的内容渲染在页面上。

#### Deletion effect

当 Fiber 节点含有 Deletion effectTag，意味着该 Fiber 节点对应的 DOM 节点需要从页面中删除。调用的方法为 commitDeletion。

1. 递归调用 Fiber 节点及其子孙 Fiber 节点中 fiber.tag 为 ClassComponent 的 componentWillUnmount (opens new window)生命周期钩子，从页面移除 Fiber 节点对应 DOM 节点

2. 解绑 ref

3. 调度 useEffect 的销毁函数

### Layout 阶段

Layout 阶段也是遍历 effectList，执行 commitLayoutEffects 方法。

commitLayoutEffects 主要做两件事：调用生命周期钩子和 hook 相关操作；赋值 ref

#### commitLayoutEffectOnFiber（调用生命周期钩子和 hook 相关操作）

commitLayoutEffectOnFiber 方法会根据 fiber.tag 对不同类型的节点分别处理。

- 对于 ClassComponent，他会通过 current === null?区分是 mount 还是 update，调用 componentDidMount （opens new window）或 componentDidUpdate

  - 触发状态更新的 this.setState 如果赋值了第二个参数回调函数，也会在此时调用。

- 对于 FunctionComponent 及相关类型，他会调用 useLayoutEffect hook 的回调函数，调度 useEffect 的销毁与回调函数

useEffect 和 useLayoutEffect 的区别

- useEffect 需要先进行调度，然后在 Layout 阶段完成后异步执行

- useLayoutEffect 是同步执行的。mutation 阶段执行 useLayoutEffect 的销毁函数，然后在 Layout 阶段执行它的回调函数。

#### commitAttachRef（赋值 Ref）

获取 DOM 实例，赋值 Ref

#### Fiber 树的切换

切换时机：mutation 阶段结束后，Layout 阶段开始前。

为什么？

componentWillUnmount 会在 mutation 阶段执行，此时 current Fiber 树还指向前一次更新的 Fiber 树，在生命周期钩子内获取的 DOM 还是更新前的。

componentDidMount 和 componentDidUpdate 会在 layout 阶段执行。此时 current Fiber 树已经指向更新后的 Fiber 树，在生命周期钩子内获取的 DOM 就是更新后的。

## Diff 算法

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

上次更新时的 fiber 节点是否存在相应的 DOM 节点，如果不存在，则新生成一个 Fiber 节点，如果存在则判断该节点是否可以复用，如果不能复用则标记 DOM 需要被删除，然后生成一个新 Fiber 节点。如果可以复用，则将上次更新的 Fiber 节点的副本作为本次新生成的 Fiber 节点并返回。

- 如何判断 DOM 节点是否可以复用？

React 通过先判断 key 是否相同，如果 key 相同则判断 type 是否相同，只有都相同时一个 DOM 节点才能复用。key 相同且 type 不同时执行 deleteRemainingChildren 将 child 及其兄弟 fiber 都标记删除。key 不同时仅将 child 标记删除。

#### 多节点时

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
