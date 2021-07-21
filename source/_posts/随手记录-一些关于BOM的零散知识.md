---
title: (随手记录)-一些关于BOM的零散知识
categories:
  - 随手记录
keywords:
  - BOM
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg33.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg33.jpg
abbrlink: 668e3aae
date: 2021-07-12 00:29:39
updated: 2021-07-12 00:29:39
---

## 用 setTimeout 实现一个 setInterval

```javascript
const run = setTimeout(() => {
  // DoSomethings
  run();
}, 3000);
```

这种实现的方式与 setInterval 的区别：setInterval 不关心方法是否还在运行；setTimeout 实现的一定是在有了结果之后才继续执行第二次的。

## 封装个支持超时的 fetch 方法

```javascript
const fetchWithTimeout = (url, init, timeout = 3000) => {
  return new Promise((resolve, reject) => {
    fetch(url, init).then(resolve).catch(reject);
    setTimeout(() => {
      reject("超时了");
    }, timeout);
  });
};
```

利用 Promise 的特性：只能从 Pending 到 Fulfilled 或只能从 Pending 到 Rejected。

同理可以封装个通用的异步函数超时逻辑;

## fetch 的中断

```javascript
const controller =  new AbortController();


fetch(url,{
  signal:controller.signal;
})


controller.abort();
```

## 为什么 cdn 域名与业务域名不相同？

1. 安全问题：cookie 中存着的多为用户身份信息，如果是同域名的话会携带着 cookie 一起去请求资源，会造成信息泄漏。

2. 节省带宽：不会带 cookie

3. 并发请求数：HTTP/1.1 会限制同域请求只能有 6 个，会阻塞业务的请求。

## 强缓存与协商缓存

### 强缓存

- Expires：设置过期时间，弊端：可能存在客户端时间跟服务端时间不一致的问题。

- max-age

### 协商缓存

- Last-Modified + If-Modified-Since ：弊端同 Expires

- ETag + If-None-Match：弊端：因为需要针对文件生成唯一标识，会影响性能。

#### 如果是 SPA 页面的 HTML 用什么缓存？

- 最好不缓存。因为内容中引用的 js 和 css 都带 hash，html 内容会频繁变更，如果用强缓存会导致更新不及时。

- 可以采用协商缓存，每次打包出来的 html 内容都会变更。

## 事件监听

```javascript
// 第三个参数代表监听阶段，true为捕获阶段，false/默认为冒泡阶段。IE只有冒泡。
element.addEventListener(type, callBack, option);
```

## 事件委托

优点：节省内存，减少注册事件。
原理：利用事件冒泡.

完整代码见:[事件委托](https://github.com/AruSeito/daily-practice/blob/main/others/BomEvent/%E4%BA%8B%E4%BB%B6%E5%A7%94%E6%89%98/index.html)

```javascript
// HTML结构如下 ul>li*7

const ul = document.querySelector("ul");

ul.addEventListener("click", (e) => {
  const target = e.target;
  const liNodeList = document.querySelectorAll("li");
  if (target.tagName.toLowerCase() === "li") {
    const liList = Array.from(liNodeList);
    const index = liList.indexOf(target);
    console.log(`index=${index}`);
  }
});
```

## 阻止事件传播

```javascript
e.stopPropagation();
```

### 场景设计

一个页面有很多的元素，每个元素都有属于自己的 click 事件。如果一个用户进入页面，会有一个 banned 的属性。如果为 true 则用户无论点击页面的哪里都不会触发之前的点击事件，只能触发弹窗提醒被封禁了.如果为 false，则按照之前的执行就可以。

#### 方案一：建一个最高层的透明遮罩层。点击就弹。

#### 方案二：运用`stopPropagation()`

```javascript
window.addEventListener("click", (e) => {
  if (banned) {
    e.stopPropagation();
    alert("你被封禁了");
    return;
  }
  // OriganThings
});
```
