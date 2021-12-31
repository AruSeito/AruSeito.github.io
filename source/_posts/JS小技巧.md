---
title: JS小技巧
categories:
  - JS
index_img: 'http://www.dmoe.cc/random.php'
banner_img: 'http://www.dmoe.cc/random.php'
abbrlink: 4f47bf3c
date: 2021-12-29 22:41:09
---

## 前言

最近沉迷于原神，无心学习。每天都在打原神哈哈哈哈哈，发的博客越来越水了。先定个小目标，这周先水一下一些小技巧，下周开始多总结一下，不在这么水下去了。


## 判断对象的某属性是否存在

原版：
```js
if (obj.a || obj.b || obj.c || obj.d ...) {
  // do something
} else {
  // 条件不符
} 
```
新：
```js
// 这个其实最好是显示的写出来。这里主要是为了简单。
const arr = [obj.a,obj.b,obj.c,obj.d,...]
const isTrue = arr.some(item => Boolean(item))
if (isTrue) {
  // do something
} else {
  // 条件不符
} 
```