---
title: webpack5之Module Federation
categories:
  - 微前端
tags:
  - 微前端
  - Module Federation
keywords:
  - Module Federation
  - webpack5
index_img: 'http://www.dmoe.cc/random.php'
banner_img: 'http://www.dmoe.cc/random.php'
abbrlink: b60a0549
date: 2021-12-23 23:12:47
---

[Module Federation 文档](https://webpack.docschina.org/concepts/module-federation/#root)
[参考代码](https://github.com/krzwc/research-on-microfrontends/tree/b1ef215e5e5b4363bae99dcc96e126e93440fac5/micro-frontends-single-spa-module-federation)

## Module Federation 是什么？

webpack5 的新插件，主要功能是我们将项目中的部分组件或全部组件暴露给外部。看起来其实和 npm 一样。其实不然。

加入我们有两个项目 a、b，a 会使用 b 中的一些功能。对于 npm 包的形式的话，把 b 打包，然后给 a 使用，如果说 b 有个 bug，我修复了，那我要先给 b 打包，然后再给 a 打包才可以。如果 MF 的话只需要更新 b 就可以了。

## MF 怎么用？

```js
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      // 与singleSPA的name一样，需要全局唯一
      name: 'main',
      library:{type:"var",name:"main"},
      // 暴露给外部的属性的文件
      fileName:"remoteEntry.js",
      // 引用的远程项目，映射关系。
      remotes: {
        app1: 'app1',
        app2: 'app2',
      },
      // 对外暴露的东西
      exposes:{
        SideNav:"./src/SideNav",
        Page:"./src/Page",
      }，
      // 父子应用中公用的包,如果main项目里有这些，会优先使用main的，如果没有才会使用remoteEntry.js中的
      shared:["react","react-dom","react-router-dom"]
    }),
  ],
};
```

webpack 配置完了之后需要改一下 html，引入暴露给外部的文件`remoteEntry.js`。
然后引用的时候就可以`const Button = React.lazy(() => import("app_three/Button"));`这么引入一下就能用了

## MF 的工作过程

可以查看一下打包产物，总结如下：
1. 加载其他应用的组件通过 mf 打包后暴露出来的文件 remoteEntry.js

2. 执行 remoteEntry.js，在全局作用域下挂载一个名为在 mf 中定义的 name 的属性，这个属性暴露了 get 和 override 这两个方法

3. 在组件中引用的时候，会通过`__webpack_require__.e`去进行引用。

4. `__webpack_require__.e`中调用`__webpack_require__.f`中的对应的方法，从而得到相应的组件。

## 与其他微前端方案的区别

不同点：

1. `qiankun`与`single-spa`是基于应用的，而mf是基于组件的。

2. mf对于无限套娃模式支持比较友好。（无限套娃就是指main引用了app1，然后有暴露了一些组件，然后app1又引用了main里的一些东西，又暴露了一些）

3. mf对于老项目不太友好，需要升级对应的webpack，不能直接使用.html文件。

4. 与`single-spa`一样，不支持js沙盒环境，需要自己进行实现。

5. 第一次需要将引用的依赖前置，会导致加载时间变长的问题
