---
title: hybrid原理解析
categories:
  - 原理解析
tags:
  - hybrid
keywords:
  - hybrid
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg2.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg2.jpg
abbrlink: e4052a99
date: 2021-11-14 13:01:45
updated: 2021-11-14 13:01:45
---

## hybrid 是什么？

hybrid 其实可以简单粗暴的理解为 一个原生应用内调用 webview，然后 h5 嵌套在 webview 中，并且 h5 可以与 native 应用进行交互。一个非常好的例子就是微信小程序/微信 H5 这种，在使用的时候通过调用 jsbridge 的方法，来调用微信原生的一些操作，比如分享到 xxx 这种。

所以 hybrid 开发重点应该是中间这个 jsbridge。

## jsbridge 通信的方式

1. URL Schema：客户端通过拦击 webview 请求来完成。

2. native 向 webview 中的 js 执行环境,注⼊ API, 以此来完成通讯。

### URL Schema

1. 原理

在 webview 中发送的请求都会被客户端监听到捕获到。

2. 定义自己的私有协议

3. 请求的发送

webview 中请求的发送，一般用 iframe 方式。

```js
const doc = window.document;
const body = doc.body;
const iframe = doc.createElement("iframe");

iframe.style.display = "none";
iframe.src = "jsbridge://openCamera";

body.append(iframe);

setTimeout(() => {
  // 采用回掉的方式更合理，发送请求成功后，客户端返回给我们，然后我们收到消息去移除。
  body.removeChild(iframe);
}, 200);
```

这种会有个安全性问题。所以客户端一般情况下会设置个域名白名单，只有发出的请求是从白名单内发的才可以。

4. 客户端拦截协议请求。

具体操作不太清楚，客户端需要处理的事情了。

拦截到请求之后对`iframe.scr`进行一个分解，提取方法名，参数等。

5. 请求处理完成后的回调

- H5 调用特定方法的时候，需要通过 webviewApi 的名称+参数作为唯一标识，注册事件

```js
const handlerId = Symbol();
const eventName = `setLeftButton_${handlerId}`;

const event = new Event(eventName);

window.addEventListener(eventName, (res) => {
  // 做一些业务逻辑
});

// 然后用上面封装好的iframe那个方法给他发送出去。
```

- 客户端在接收到请求的时候，完成自己的处理后，dispatchEvent，携带回调的数据处罚自定义事件

```js
event.data = { error: 0 };

window.dispatchEvent(event);
```

真正与客户端交互的逻辑靠我自己不太好搞，还得搞一些原生方法，所以我们可以用 websocket 来模拟一下。

在 node 层起个 staticServer+websocket，然后在 html 里触发相应的 native 方法的时候就发送个 ws 消息，然后 node 层就相当于 native 层，再处理收到消息后的逻辑，然后再把消息发送回去。[模拟源码](https://github.com/AruSeito/daily-practice/blob/main/others/jsBridge/index.js)

### 注入 API

URL Schema 缺点：如果使用 iframe 这样发出请求，url 过长的话会造成 url 被截断。

注入 API 缺点：

注入时机不确定，需要实现注入失败后重试的机制，保证注入的成功率，同时 JavaScript 端在调用接口时，需要优先判断 JSBridge 是否已经注入成功。

如果方法特别多的话，window 上挂超多方法，内存泄露问题很严重。

1. 向 native 传递信息

native 会在 window 上挂载一个对象，然后直接 window.方法调用就可以传递消息了。

一般情况下会对参数进行编码，比如转换为 base64

2. 准备接收 native 的回调

在 window 上去声明接收回调的 api

3. native 调用回调函数
