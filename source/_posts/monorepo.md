---
title: monorepo
categories:
  - 前端工程化
tags:
  - monorepo
  - lerna
keywords:
  - monorepo
index_img: 'http://www.dmoe.cc/random.php'
banner_img: 'http://www.dmoe.cc/random.php'
abbrlink: 7b6bc5a
date: 2021-12-28 20:47:17
---

## 背景

我司代码存放方式比较复杂，n个项目都在同一个代码仓库下，主要是每个项目都没有关系，然后外面搞个大的webpack，每个项目里都有个小的gulp/webpack这样处理,而且没个小项目下都有个`.npmrc`，指向的文件还都不同。每次即使只修改了其中的某一个小东西，就要全部发布一遍。所以打算搞一下有没有办法优化，在查找资料的时候看到了「monorepo」这种方案，不过最后放弃了这种方案，所以本篇只记录一下自己了解到的monorepo

## 长话短说

由于这个仓库下的每个项目都没关系，也不会有互相引用的这种，甚至都不存在公用逻辑部分，唯一通用的可能也就只有框架选择方面，直接拆成了多个仓库来管理。过几天可以分享一下自己的对于这些项目制作cli的经验。

## monorepo

单一代码库「monorepo」 与之相对的概念还有「multirepo」多代码库。像react、babel这种管理的都是用monorepo的理念来进行管理的。
其中比较成熟的实现方案有[lerna](https://lerna.js.org/)

这里不会去讨论lerna怎么用，而是单纯从体验来聊聊monorepo

monorepo最直观的好处就是调试方便，比如：我们有一个包，在某项目中引用了，但是如果我们发现在这个项目中的场景下有bug，要修改这个npm包，我们可能要先npm link，然后到这个项目里来看。这个时候调试起来就比较麻烦了。monorepo的话就直接引用本地的也没这么花里胡哨的操作，直接一把梭。

还有一点就是基建成本降低，只需要做一套基建流程，直接复用即可。

commit简化，比如之前修改一个功能，可能要横跨两三个库，在这种情况下直接一个commit就可以了，cr起来也更方便。

如果有依赖关系使用这种monorepo的倒是还可以，但是考虑到我们公司这里，只有框架共用的情况，组件都不通用的情况其实多个repo也没什么影响，毕竟也不会直接放到一起去联调。如果单纯为了减少node_modules的话，可能会得不偿失，因为有的项目都好多年没人维护了，但是现在还在用，react版本特别低。频繁改动的项目react版本就会比较高。这种情况可能抽离出来的也比较少了，就需要单独给这个项目处理。

相对的monorepo也是有缺陷的，单从定义来看monorepo要一个repo，所有代码都在里面，硬盘压力大，我明明不需要维护A，我却也要一起给A拉下来。

还有就是构建/测试问题，单repo的话就需要考虑一下 增量构建/测试，按需构建的问题,虽然可以全量，但是搞前端基建不就是为了开发的舒服吗？构建个东西等个1小时那就一点不幸福了。

## 总结

Monorepo 的开发模式就是将各自独立的项目，变成一个统一的工程整体，使用统一的工作流程，公用基建。


## 可参考资料

- [应用级 Monorepo 优化方案](https://github.com/worldzhao/blog/issues/9)
- [精读《Monorepo 的优势》](https://github.com/ascoders/weekly/blob/master/%E5%89%8D%E6%B2%BF%E6%8A%80%E6%9C%AF/102.%E7%B2%BE%E8%AF%BB%E3%80%8AMonorepo%20%E7%9A%84%E4%BC%98%E5%8A%BF%E3%80%8B.md)


