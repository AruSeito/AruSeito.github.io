---
title: Router简易实现
categories:
  - 其他
index_img: 'http://www.dmoe.cc/random.php?2022-01-16 13:14:04'
banner_img: 'http://www.dmoe.cc/random.php?2022-01-16 13:14:04'
abbrlink: bce8a1b7
date: 2022-01-16 21:14:04
---

在使用React-router时分别对应的是`HashRouter`和`BrowserRouter`


从名字上就可以知道了，对应的是前端中的 `hash路由` 和 `history路由`

## 区别

- `hash路由`：监听 url 中 hash 的变化，不向服务器发送请求，不需要服务端的支持。

- `history路由`：监听 url 中的路径变化，需要客户端和服务端共同的支持，但是如果通过`pushState` 和 `replaceState`来改变URl，则不会发起网络请求


## 实现

其实不管是什么路由，都是基于一部分变化，然后根据新的路由渲染新的内容。

所以我们先定个小目标，要实现的内容：

1. 监听路由变化，当路由变化做出不同动作。

2. 可以配置路由。


### HashRouter

先来实现最简单的，只要客户端自己支持就好。`hashRouter`的底层依赖于url的hash变化的，[`hashchange`事件](https://developer.mozilla.org/zh-CN/docs/Web/API/HashChangeEvent)可以满足我们的需求，那其实我们就加个监听事件就可以完成第一点。


```js
window.addEventListener("hashchange",()=>{
  // doSomeThing;
})
```

那要怎么实现可配置路由呢？也就是一个hash对应一个动作。

答案是Map，凑成形成[key,value]的键值对，key为router地址，value为回调也就是方法，每次添加一个路由，就是往map里放个键值对，然后hashChange的时候取出对应的方法，执行即可。

```js
class HashRouter {
  constructor() {
    // 保存path与cb的关系
    this.routes = new Map();
    // 绑定方法
    this.refresh = this.refresh.bind(this);
    this.route = this.route.bind(this);
    // 监听事件
    // window.addEventListener("load", this.refresh);
    window.addEventListener("hashchange", this.refresh);
  }

  // 注册路由
  route(path, cb) {
    this.routes.set(path, cb);
  }

  // hash改变时执行的动作
  refresh() {
    const hash = window.location.hash;
    const path = hash.slice(1) || "/"
    if (path) {
      const cb = this.routes.get(path);
      cb && cb();
    }
  }
}

const router = new HashRouter();

const body = document.body;

function changeBgColor(color) {
  body.style.backgroundColor = color;
}

router.route("/", () => {
  changeBgColor("red")
})
router.route("/blue", () => {
  changeBgColor("blue")
})
router.route("/grey", () => {
  changeBgColor("grey")
})
router.route("/green", () => {
  changeBgColor("green")
})
```
以上运行之后我们发现，`/`这个路由在刚进来的时候并未生效，所以我们取消这层注释就可以了，在刚进来的时候进行一次初始化操作。

![2022/01/16/Hash路由工作原理](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2022/01/16/Hash路由工作原理.png)

### historyRouter

在写完hashRouter之后是不是觉得historyRouter就是把hashchange改一下就可以了？其实并不是，在官方API上查询可以看到，并没有监听pushState和replaceState的这种事件，只有popState的事件。

那我们就不监听事件好了，我们可以点击时阻止a标签的默认操作，然后拿到path，将path使用pushState更改浏览器的URL显示，最后从router这个map里取出来相应事件执行就好了。

```js
class HistoryRouter {
  constructor() {
    // 保存path与cb的关系
    this.routes = new Map();
    // 绑定方法
    this.refresh = this.refresh.bind(this);
    this.route = this.route.bind(this);
    this.push = this.push.bind(this);
    this.pop = this.pop.bind(this);
    // 监听事件
    window.addEventListener("load", this.refresh);
    window.addEventListener("popstate", this.pop);
  }

  // 注册路由
  route(path, cb) {
    this.routes.set(path, cb);
  }

  // hash改变时执行的动作
  refresh() {
    const hash = window.location.hash;
    const path = hash.slice(1) || "/"
    if (path) {
      const cb = this.routes.get(path);
      cb && cb();
    }
  }

  // 执行跳转动作，相当于自己封装的pushState
  push(path){
    const cb = this.routes.get(path);
    cb && cb();
    history.pushState({},{},path);
  }

  // 执行回退
  pop(){
    const pathName = location.pathname;
    const cb = this.routes.get(pathName);
    cb && cb();
  }
}
// 初始化route
const router = new HistoryRouter();

const body = document.body;

function changeBgColor(color) {
  body.style.backgroundColor = color;
}

router.route("/", () => {
  changeBgColor("red")
})
router.route("/blue", () => {
  changeBgColor("blue")
})
router.route("/grey", () => {
  changeBgColor("grey")
})
router.route("/green", () => {
  changeBgColor("green")
})

// 屏蔽默认点击事件，并调用自己封装好的pushState
const handleClickLink = (e)=>{
  e.preventDefault();
  const pathName = new URL(e.target.href).pathname;
  router.push(pathName);
}

document.querySelector("#green").addEventListener("click", handleClickLink)
document.querySelector("#grey").addEventListener("click", handleClickLink)
```

![2022/01/18/History路由工作原理](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2022/01/18/History路由工作原理.png)