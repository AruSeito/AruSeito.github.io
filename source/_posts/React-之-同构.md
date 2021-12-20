---
title: React 之 同构
categories:
  - React
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg15.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg15.jpg
abbrlink: 529a2369
date: 2021-12-20 00:43:08
---

## WEB 渲染发展历程

### 第一阶段

所有东西都堆在 html/php/jsp 等文件内，访问网址，就直接把 html 的全部内容返回，然后服务端根据 html 进行渲染

### 第二阶段

SPA 阶段，将前后端分离，浏览器拿到 html 后根据其中的 js ，进行计算得出完整的 html，再渲染

### 第三阶段

服务端渲染 SSR，跟第一阶段异曲同工，只不过不会再和后端代码耦合。

### 为什么要用 SSR（server side render）

SPA 存在的问题：

1. 白屏时间长：因为拿到 html 和 js 后，需要 js 进行一波计算，才能得出完整的 html，所以会耗时久。
2. SEO 不友好：部分老的搜索引擎可能并不支持 SPA，导致无法拿到页面的完整内容，即不能进行 js 的计算得到完整 HTML
   所以出现了现在的同构，同构可以理解为：在服务端运行一遍拿到完整的 HTML，在浏览器端运行一遍将响应事件等绑定到元素上。

## 使用 renderToString 在服务端渲染
[参考代码](https://github.com/AruSeito/daily-practice/tree/main/SSR)

首先如何用 React 实现第一阶段的呢？直出 html 呢？
React 官方其实提供了 api：`renderRoString`。
当我们访问的时候

```js
import { renderToString } from 'react-dom/server';

const express = require('express');

const app = express();
const PORT = 3000;

app.use(express.static('dist'));
app.get('/', function (req, res) {
  const content = renderToString(React.createElement('h1', null, 'Hello'));
  console.log(content);
  res.send(content);
});
```

顾名思义，`renderToString`仅仅是将组件转换成字符串。然后穿插到 html 里去，是不是有点 php 那味儿了？

简单配置一下 webpack

```js
// webpack-server.config.js
const path = require("path");
const nodeExternals = require("webpack-node-externals");
const CopyWebpackPlugin = require("copy-webpack-plugin");
module.exports = {
  entry: {
    index: path.resolve(__dirname, "../server.js")
  },
  mode: "development",
  target: "node",
  devtool: "cheap-module-eval-source-map",
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, "../dist/server")
  },
  // 不要将 node 的东西打包进去
  externals: [nodeExternals()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "../src")
    },
    extensions: [".js"]
  },
  module: {
    rules: [{
      test: /\.js$/,
      use: "babel-loader",
      exclude: /node_modules/
    }]
  },
  plugins: [
    new CopyWebpackPlugin([{
      from:path.resolve(__dirname,"../public"),
      to:path.resolve(__dirname,"../dist")
    }]),
  ]
}
// package.json
scripts:{
  "build:server": "webpack --config build/webpack-server.config.js --watch",
}
```

这样我们就可以不用再写`React.createElement`了，可以直接用 jsx 语法了，但是别忘记配置 babel 哦。

然后我们尝试在以上 express 的代码中给 div 绑定事件，访问后发现事件并不会绑定上。
这时候我们就要使用同构了。

## 同构

前文说过，同构其实就是服务端执行一遍，浏览器端再执行一遍。

那我们按照 React 的写法，搞个客户端，先给搞个 webpack 配置

```js
// webpack-client.config.js
const path = require('path');

module.exports = {
  entry: {
    index: path.resolve(__dirname, '../index.js'),
  },
  mode: 'development',
  devtool: 'cheap-module-eval-source-map',
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, '../dist/client'),
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '../src'),
    },
    extensions: ['.js'],
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: 'babel-loader',
        exclude: /node_modules/,
      },
    ],
  },
};
```

然后写代码

```js
// index.js
import React from 'react';
import { render } from 'react-dom';
import App from './app';

render(<App />, document.querySelector('#root'));
// app.js
import React from 'react';

const App = () => {
  const handleClick = () => {
    alert('点我干啥！');
  };
  return <h1 onClick={handleClick}>Hello</h1>;
};
```

咱们因为 `index.js`中需要挂载到 root 上去，所以 express 那面需要微调一下

```js
res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ssr</title>
</head>
<body>
  <div id="root">${content}</div>
  <script src="/client/index.js"></script>
</body>
</html>`);
```

ok，我们先构建一下客户端，在构建一下服务端，然后启动服务端，再访问一下。
都没问题。

我们打开控制台，会发现有个提醒，大概就是说让我们用 hydrate。

## hydrate(水和)

为什么要用 hydrate 来取到 render 呢？
因为按照源码中 render 所示在 commit 阶段会直接将要挂载到的 dom 节点下的所有节点都清空，然后再给他挂载上去。相当于我们在服务端干的都白干了。
而 hydrate 会以 服务端渲染出来的为基础，继续执行。
要改的话其实很简单，直接给 render 换成 hydrate 就可以。

### 同构的流程

1. 客户端发起请求，服务端根据 react 代码生成 html
2. 客户端收到服务端发送的 html，解析并展示
3. 客户端加载 js 等文件。
4. 客户端执行 js，完成 hydrate。
5. 客户端接管整个应用。

但是我们的正常的应用不可能这么简单啊。一定还会有 router 的。那我们怎么处理 router 呢？

其实`react-router`他有解决方案:`StaticRouter`。

我们先在服务端加上这个

```js
app.get('*', function (req, res) {
  const content = renderToString(
    <StaticRouter location={req.url}>
      <Route exact path="/user">
        <UserPage />
      </Route>
      <Route exact path="/login">
        <LoginPage />
      </Route>
    </StaticRouter>,
  );
  res.send(`<!DOCTYPE html>
    <html lang="en">
      <head>
      <meta charset="UTF-8">
    <title>ssr</title>
    </head>
    <body>
      <div id="root">${content}</div>
    <script src="/client/index.js"></script>
    </body>
  </html>`);
});
```

ok，我们上浏览器看一眼`/user`，我们发现他会先显示`user`然后在显示`hello`。为什么？

因为我们只对服务端处理了路由，没对客户端处理，所以先接收到 html 显示为`user`然后执行客户端代码，就挂了。

所以我们再给客户端搞个路由

```js
import { BrowserRouter, Route } from 'react-router-dom';

hydrate(
  <BrowserRouter>
    <Route exact path="/user">
      <UserPage />
    </Route>
    <Route exact path="/login">
      <LoginPage />
    </Route>
  </BrowserRouter>,
  document.querySelector('#root'),
);
```

ok 再看一下结果，没问题了。

但是这有个小问题，服务端代码的 router 和客户端的 router 其实是耦合的。

ok，我们来写个转换器就完事了。

```js
// routes/routerConfig.js
import React from 'react';
import LoginPage from '../pages/login';
import UserPage from '../pages/user';
import NotFoundPage from '../pages/notFound';

export default [
  {
    type: 'redirect',
    exact: true,
    from: '/',
    to: '/user',
  },
  {
    type: 'route',
    path: '/user',
    exact: true,
    component: UserPage,
  },
  {
    type: 'route',
    path: '/login',
    exact: true,
    component: LoginPage,
  },
  {
    type: 'route',
    path: '*',
    component: <NotFoundPage />,
  },
];
//routes/index.js
import React from 'react';
import { createBrowserHistory } from 'history';
import { Router, StaticRouter, Route, Redirect, Switch } from 'react-router';
import routeConfig from './routeConfig';

const routes = routeConfig.map((conf, index) => {
  const { type, ...otherConf } = conf;
  if (type === 'redirect') {
    return <Redirect key={index} {...otherConf} />;
  } else {
    return <Route key={index} {...otherConf} />;
  }
});

export const createRoute = (type) => (params) => {
  if (type === 'client') {
    const history = createBrowserHistory();
    return (
      <Router history={history}>
        <Switch>{routes}</Switch>
      </Router>
    );
  } else if (type === 'server') {
    return (
      <StaticRouter {...params}>
        <Switch>{routes}</Switch>
      </StaticRouter>
    );
  }
};

//server.js
app.get('*', function (req, res) {
  const content = renderToString(
    createRoute('server')({ location: req.url, context }),
  );

  res.send(`<!DOCTYPE html>
    <html lang="en">
      <head>
      <meta charset="UTF-8">
    <title>ssr</title>
    </head>
    <body>
      <div id="root">${content}</div>
    <script src="/client/index.js"></script>
    </body>
  </html>`);
});

//index.js
import React from "react";
import { hydrate } from "react-dom"
import App from "./app";

hydrate(<App />, document.querySelector("#root"))
//app.js
import React from "react";
import { createRoute } from "./router/index"
const App = ()=>{
  render() {
    return createRoute("client")();
  }
}
export default App;
```

再上浏览器看一眼，完美渲染。这样也就真的没问题了吗？
我们访问一下`/`,看一下 devTools 里的 netWork，发现他的 html 文件并不是`location/user`，而是`location`。
正常我们重定向过去之后，会拿到个 302 响应，然后再去请求新的。
那我们再改一下

```js
// server.js
app.get("*", function (req, res) {
  const context = {};
  const content = renderToString(createRoute("server")({ location: req.url, context }))
  if (context.url) {
    return res.redirect(context.url);
  } else {
    res.send(`<!DOCTYPE html>
    <html lang="en">
      <head>
      <meta charset="UTF-8">
    <title>ssr</title>
    </head>
    <body>
      <div id="root">${content}</div>
    <script src="/client/index.js"></script>
    </body>
  </html>`)
  }
})

```
我们通过 context 透传到 react-router 里去，让他改这个值，然后我们判断他有没有 context.url 就好了，有的话就直接用服务端重定向。

这样也没问题了吗？并不。
我们随便输入一个不存在的路由，我们的预期是跳转到 notFound 的页面。我们看一下，可以。仔细看一下 netWork，并不是 404。
再改一下
```js
// server.js
app.get("*", function (req, res) {
  const context = {};
  const content = renderToString(createRoute("server")({ location: req.url, context }))
  if (context.url) {
    return res.redirect(context.url);
  } else {
    if (context.NOT_FOUND) {
      res.status(404);
    }
    res.send(`<!DOCTYPE html>
    <html lang="en">
      <head>
      <meta charset="UTF-8">
    <title>ssr</title>
    </head>
    <body>
      <div id="root">${content}</div>
    <script src="/client/index.js"></script>
    </body>
  </html>`)
  }

})
// routes/routerConfig.js
import React from "react";
import LoginPage from "../pages/login";
import UserPage from "../pages/user";
import NotFoundPage from "../pages/notFound"

export default [
  // ...
  {
    type: "route",
    path: "*",
    render:({staticContext})=>{
      if (staticContext){
        staticContext.NOT_FOUND= true;
      }
      return <NotFoundPage />
    }
  },
]
```

在访问一下，ok 完工。一切如预期。