---
title: JavaScript之事件循环
categories:
  - JavaScript
tags:
  - Node.js
  - JavaScript
index_img: /img/banner/bg1.jpg
banner_img: /img/banner/bg1.jpg
date: 2021-02-22 10:45:20
updated: 2021-02-22 10:45:20
---

> 本文摘抄自[淘宝技术](https://mp.weixin.qq.com/s/a6aFweCiLF0Mx03fARP8qQ)

## 事件循环是什么？

在EcmaScript的标准定义中没有提到事件循环（Event Loop）这个定义，反而是HTML的标准定义中定义了事件循环。

>To coordinate events, user interaction, scripts, rendering, networking, and so forth, user agents must use event loops as described in this section. Each agent has an associated event loop, which is unique to that agent.

根据标准中对事件循环的定义描述，发现事件循环本质上是user agent用于协调用户交互（鼠标、键盘）、脚本（如 JavaScript）、渲染（如 HTML DOM、CSS 样式）、网络等行为的一个机制。

各种浏览器事件同时触发时，肯定有一个先来后到的排队问题。决定这些事件如何排队触发的机制，就是事件循环。这个排队行为以 JavaScript 开发者的角度来看，主要是分成两个队列：

- 一个是 JavaScript 外部的队列。外部的队列主要是浏览器协调的各类事件的队列，标准文件中称之为 Task Queue。下文中为了方便理解统一称为外部队列。

- 另一个是 JavaScript 内部的队列。这部分主要是 JavaScript 内部执行的任务队列，标准中称之为 Microtask Queue。下文中为了方便理解统一称为内部队列。

值得注意的是，虽然为了好理解管这个叫队列 (Queue)，但是本质上是有序集合 (Set)，因为传统的队列都是先进先出（FIFO）的，而这里的队列则不然，排到最前面但是没有满足条件也是不会执行的（比如外部队列里只有一个 setTimeout 的定时任务，但是时间还没有到，没有满足条件也不会把他出列来执行）。

## 外部队列

外部队列就是 JavaScript 外部的事件的队列，事件源主要有：

- DOM 操作 (页面渲染)

- 用户交互 (鼠标、键盘)

- 网络请求 (Ajax 等)

- History API 操作

- 定时器 (setTimeout 等) 

HTML 标准中明确指出一个事件循环由一个或多个外部队列，而每一个外部事件源都有一个对应的外部队列。不同事件源的队列可以有不同的优先级（例如在网络事件和用户交互之间，浏览器可以优先处理鼠标行为，从而让用户感觉更加流程）。

## 内部队列

内部队列（Microtask Queue），即 JavaScript 语言内部的事件队列，在 HTML 标准中，并没有明确规定这个队列的事件源，通常认为有以下几种：

- Promise 的成功 (.then) 与失败 (.catch)

- MutationObserver

- Object.observe (已废弃)

## 处理模型

在标准定义中事件循环的步骤比较复杂，这里我们简单描述一下这个处理过程：

1. 从外部队列中取出一个可执行任务，如果有则执行，没有下一步。

2. 挨个取出内部队列中的所有任务执行，执行完毕或没有，则下一步。

3. 浏览器渲染。

![事件循环简化模型](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222142647.png)

由上文标准中提到的标准可知：JavaScript 的执行也是一个浏览器发起的外部事件。

所以本质的执行顺序是：

1. 一次外部事件

2. 所有内部事件

3. HTML 渲染

4. 回到到 1

eg.:

```HTML
<html>
    <body>
        <pre id="main"></pre>
    </body>
    <script>
        const main = document.querySelector('#main');
        const callback = (i, fn) => () => {
            console.log(i)
            main.innerText += fn(i);
        };
        let i = 1;
        while(i++ < 5000) {
            setTimeout(callback(i, (i) => '\n' + i + '<'))
        }

        while(i++ < 10000) {
            Promise.resolve().then(callback(i, (i) => i +','))
        }
        console.log(i)
        main.innerText += '[end ' + i + ' ]\n'
</script>
</html>
```

1. JavaScript 执行完毕 innerText 首先加上 [end 10001]

2. 内部队列：Promise 的 then 全部任务执行完毕，往 innerText 上追加了很长一段字符串

3. HTML 渲染：1 和 2 追加到 innerText 上的内容同时渲染

4. 外部队列：挨个执行 setTimeout 中追加到 innerText 的内容

5. HTML 渲染：将 4 中的内容渲染。

6. 回到第 4 步走外部队列的流程（内部队列已清空）

## 浏览器与 Node.js 的事件循环差异

浏览端是将 JavaScript 集成到 HTML 的事件循环之中，Node.js 则是将 JavaScript 集成到 libuv 的 I/O 循环之中。

HTML (浏览器端) 与 libuv (服务端) 面对的场景有很大的差异。首先能直观感受到的区别是：

- 事件循环的过程没有 HTML 渲染。只剩下了外部队列和内部队列这两个部分。

- 外部队列的事件源不同。Node.js 端没有了鼠标等外设但是新增了文件等 IO。

- 内部队列的事件仅剩下 Promise 的 then 和 catch。

Node.js （libuv）在最初设计的时候是允许执行多次外部的事件再切换到内部队列的，而浏览器端一次事件循环只允许执行一次外部事件。

```JavaScript
setTimeout(()=>{
  console.log('timer1');
  Promise.resolve().then(function() {
      console.log('promise1');
  });
});

setTimeout(()=>{
  console.log('timer2');
  Promise.resolve().then(function() {
      console.log('promise2');
  });
});
```

这个例子在浏览器端执行的结果是 timer1 -> promise1 -> timer2 -> promise2，而在 Node.js 早期版本（11 之前）执行的结果却是 timer1 -> timer2 -> promise1 -> promise2。

### 浏览器端

1. 外部队列：代码执行，两个 timeout 加入外部队列

2. 内部队列：空

3. 外部队列：第一个 timeout 执行，promise 加入内部队列

4. 内部队列：执行第一个 promise

5. 外部队列：第二个 timeout 执行，promise 加入内部队列

6. 内部队列：执行第二个 promise

### Node.js 服务端

1. 外部队列：代码执行，两个 timeout 加入外部队列

2. 内部队列：空

3. 外部队列：两个 timeout 都执行完

4. 内部队列：两个 promise 都执行完


setImmediate 的引入是为了解决 setTimeout 的精度问题，由于 setTimeout 指定的延迟时间是毫秒（ms）但实际一次时间循环的时间可能是纳秒级的，所以在一次事件循环的多个外部队列中，找到某一个队列直接执行其中的 callback 可以得到比 setTimeout 更早执行的效果。我们继续以开始的场景构造一个例子，并在 Node.js 10.x 的版本上执行

```JavaScript
setTimeout(()=>{
  console.log('setTimeout1');
  Promise.resolve().then(() => console.log('promise1'));
});

setTimeout(()=>{
  console.log('setTimeout2');
  Promise.resolve().then(() => console.log('promise2'));
});

setImmediate(() => {
  console.log('setImmediate1');
  Promise.resolve().then(() => console.log('promise3'));
});

setImmediate(() => {
  console.log('setImmediate2');
  Promise.resolve().then(() => console.log('promise4'));
});
```

输出结果：

1. setImmediate1
2. setImmediate2
3. promise3
4. promise4
5. setTimeout1
6. setTimeout2
7. promise1
8. promise2

这里 setTimeout 在 setImmediate 后面执行的原因是因为 ms 精度的问题，想要手动 fix 这个精度可以插入一段 const now = Date.now(); wihle (Date.now() < now + 1) {} 即可看到 setTimeout 在 setImmediate 之前执行了。


根据这个执行结果，我们可以推测出 Node.js 中的事件循环与浏览器类似，也是外部队列与内部队列的循环，而 setImmediate 在另外一个外部队列中。

![Node.js事件循环图](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222143802.png)

接下来，我们再来看一下当 Node.js 在与浏览器端对齐了事件循环的事件之后，这个例子的执行结果为：

1. setImmediate1
2. promise3
3. setImmediate2
4. promise4
5. setTimeout1
6. promise1
7. setTimeout2
8. promise2

其中主要有两点需要关注，一是外部队列在每次事件循环只执行了一个，另一个是 Node.js 固定了多个外部队列的优先级。setImmediate 的外部队列没有执行完的时候，是不会执行 timeout 的外部队列的。了解了这个点之后，Node.js 的事件循环就变得很简单了，我们可以看下 Node.js 官方文档中对于事件循环顺序的展示：

![Node.js官方文档之事件循环](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222143917.png)

其中 check 阶段是用于执行 setImmediate 事件的。结合本文上面的推论我们可以知道，Node.js 官方这个所谓事件循环过程，其实只是完整的事件循环中 Node.js 的多个外部队列相互之间的优先级顺序。

eg:

```JavaScript
const fs = require('fs');

setImmediate(() => {
  console.log('setImmediate');
});

fs.readdir(__dirname, () => {
  console.log('fs.readdir');
});

setTimeout(()=>{
  console.log('setTimeout');
});

Promise.resolve().then(() => {
  console.log('promise');
});
```

输出：
> 1. promise
> 2. setTimeout
> 3. fs.readdir
> 4. setImmediate

根据输出结果，我们可以梳理出来：

1. 外部队列：执行当前 script

2. 内部队列：执行 promise

3. 外部队列：执行 setTimeout

4. 内部队列：空

5. 外部队列：执行 fs.readdir

6. 内部队列：空

7. 外部队列：执行 check （setImmediate）

这个顺序符合 Node.js 对其外部队列的优先级定义：

![第一部分](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222145007.png)

timer（setTimeout）是第一阶段的原因在 libuv 的文档中有描述 —— 为了减少时间相关的系统调用（System Call）。setImmediate 出现在 check 阶段是蹭了 libuv 中 poll 阶段之后的检查过程（这个过程放在 poll 中也很奇怪，放在 poll 之后感觉比较合适）。

idle, prepare 对应的是 libuv 中的两个叫做 idle 和 prepare 的句柄。由于 I/O 的 poll 过程可能阻塞住事件循环，所以这两个句柄主要是用来触发 poll （阻塞）之前需要触发的回调：

![第二部分](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222145015.png)

由于 poll 可能 block 住事件循环，所以应当有一个外部队列专门用于执行 I/O 的 callback ，并且优先级在 poll 以及 prepare to poll 之前。

另外我们知道网络 IO 可能有非常多的请求同时进来，如果该阶段如果无限制的执行这些 callback，可能导致 Node.js 的进程卡死该阶段，其他外部队列的代码都没发执行了。所以当前外部队列在执行一定数量的 callback 之后会截断。由于截断的这个特性，这个专门执行 I/O callbacks 的外部队列也叫 pengding callbacks：

![完整](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2021/02/22/20210222145027.png)