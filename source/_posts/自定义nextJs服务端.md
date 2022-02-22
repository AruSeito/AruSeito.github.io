---
title: 自定义nextJs服务端
categories:
  - 前端工程化
tags:
  - node中间件
keywords:
  - nextJS
  - express
  - 自定义服务器
index_img: 'http://www.dmoe.cc/random.php?2022-01-21 14:57:38'
banner_img: 'http://www.dmoe.cc/random.php?2022-01-21 14:57:38'
abbrlink: d693fb46
date: 2022-01-21 22:57:38
---

## 背景

我司在进行一个项目拆分，将静态展示页都拆出去，以方便构建的时候按需构建。但是遇到了问题，在迁移到一半的时候迁移不下去了，因为需要给部分页面写nginx匹配规则进入另外的项目，这个时候规则已经非常难写了。为了不再折磨人，所以改成统一入口，在node层进行路由匹配
![2022/01/03/优化前的路由](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2022/02/14/优化前的路由.png)

![2022/02/14/优化后的路由](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2022/02/14/优化后的路由.png)

## 原理

之前我们的项目A是使用express后端渲染，项目B和C都是nextJS来写的。

所以我们这个时候要做的就是让项目A的express同时承担两部分能力

1. 渲染

2. 路由

nextJS部分只承担渲染工作。


首先进行路由匹配，在不同的路由逻辑内制定渲染规则，如果是未迁移页面的话不需要改动，还是用原来的渲染逻辑。如果是已经迁移的页面，使用 nextJS 暴露出的接口进行渲染。

![2022/02/14/整体情况](https://cdn.jsdelivr.net/gh/AruSeito/image-hosting-service@main/2022/02/14/整体情况.png)

## 核心代码

```js
const { createServer } = require('http');
const next = require('next');

const nextApp = next({ dev:false, hostname:"localhost", port:3000 });

const nextHandle = app.getRequestHandler()

app.prepare().then(() => {

  const expressApp = express();

  // 处理express的中间件
  // expressApp.use(xxx);

  // 处理一下router，将nextHandle穿进去,在router里写个集合来匹配需要用next的规则，直接调用nextHandle即可
  // router(expressApp,nextHandle)


  createServer(expressApp).listen(port, (err) => {
    if (err) throw err
    console.log(`> Ready on http://${hostname}:${port}`)
  })
})
```


## 参考文档

- [Set Up Next.js with a Custom Express Server](https://nextjs.org/docs/advanced-features/custom-server)

- [Advanced Features: Custom Server | Next.js](https://levelup.gitconnected.com/set-up-next-js-with-a-custom-express-server-typescript-9096d819da1c)