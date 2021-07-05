---
title: (随手记录)mock方案-jsonServer
categories:
  - 前端工程化
tags:
  - 工程化
  - mock
keywords:
  - mock
  - json-server
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg35.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg35.jpg
abbrlink: 5adf6b08
date: 2021-06-30 23:20:15
updated: 2021-06-30 23:20:15
---

## 前言

又过了好久没更新博客了，前段时间因为工作太忙再加上学习到的都是零散的知识点，没有更新博客的想法。仔细想想，学习的过程不就是无数个小的知识点堆叠起来的吗。

所以又重拾博客，将每天学到的一点点小东西都记录下来。

## JSON-SERVER

之前在上一家公司工作的时候，mock 方案采用的是 Easy-mock 这种 API 托管平台，后端生成 swagger,然后前端开发再将 swagger 同步到托管平台上。本地使用 express 的 http-proxy 中间件进行指定 API 的拦截转发。

但是在这家公司并没有关于 MOCK 的方案，只能进行前端写死数据然后进行模拟，每次要测试时都需要再去手动清除数据，隔了好久的可能还会有漏掉的地方。

所以学习了一下 mock 的方案。

本打算实现一个跟上一家公司的方案，在仔细查看了现公司的代码结构，发现并不适合接入该种方案：

现公司没有 node 层，都是前端静态页面直接请求后端，跨域由后端来进行处理，如果单单为了一个接口转发接入 node 层，有点无意义，所以放弃了该种方案。

采用了 JSON-SERVER 的方案。

但是 JSON-SERVER 更多的是适合处理符合 REST API 的，总是能遇到一些不符合 REST API 的。

这个时候需要写中间件。看 Demo，很简单。

```Javascript
// middleWare Demo
module.exports = (req,res,next)=>{
  if(req.method === "POST" && req.path === "/login"){
    if(req.body.username==="aruseito" && req.body.password === "123456"){
      return res.status(200).json({
        user:{
          token:"123456"
        }
      })
    }else{
      return res.status(500).json({
        message:"账号或者密码错误"
      })
    }
  }
  next();
}
```

然后只需要在启动 json-server 的时候加上`--middlewraes middleware.js`即可。如：`json-server __json_server_mock__/db.json --watch --port 3001 --middlewares __json_server_mock__/middleware.js`。

但是这种方案还是避免不了在上线前要修改接口地址的问题。所以很快就被我放弃了。

## 最终方案

考虑到以上因素，最终选择在本地自己启一个 node，读取配置文件，用 http-proxy 将接口按需转发过去。跟上一家公司的方案一样，只是没有将这个一起耦合到项目中去。

又考虑到我司有多种客户端，各端都不一定有合适的 MOCK 工具，所以打算将这层 node 使用 Electron 包装起来，搞个图形化界面，让各端都方便使用。

目前还在研究 Electron 怎么搞。。。只是刚有初步想法。
