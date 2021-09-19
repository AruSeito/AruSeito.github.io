---
title: 手撕一个eventBus
categories:
  - 手撕源码
tags:
  - eventBus
keywords:
  - eventBus
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg15.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg15.jpg
abbrlink: 27b53d37
date: 2021-08-29 22:53:16
updated: 2021-08-29 22:53:16
---

首先需要知道 eventBus 中的方法都有哪些。按照方法进行基础框架的搭建

```js
class eventBus {
  // 初始化
  constructor() {}

  // 触发事件
  emit(eventName, ...args) {}

  // 注册事件
  on(eventName, cb) {}

  // 注册事件但只触发一次
  onOnce(eventName, cb) {}

  // 取消事件
  off(eventName) {}
}
```

new 的时候对 event 进行初始化。然后分别填入逻辑

```js
class eventBus {
  constructor() {
    this.events = {};
  }

  emit(eventName, ...args) {
    const cb = this.events[eventName];
    if (!cb) {
      throw new Error("没这个事件啊");
    }

    cb.forEach((cb) => cb.apply(this, args));
    return this;
  }

  on(eventName, cb) {
    if (!this.events[eventName]) {
      this.events[eventName] = [];
    }
    this.events[eventName].push(cb);
    return this;
  }

  onOnce(eventName, cb) {
    const func = (...args) => {
      this.off(eventName, func);
      cb.apply(this, args);
    };
    this.on(eventName, func);
  }

  off(eventName, cb) {
    if (!cb) {
      this.events[eventName] = null;
    } else {
      this.events[event] = this.events[event].filter((item) => item !== cb);
    }
    return this;
  }
}
```
