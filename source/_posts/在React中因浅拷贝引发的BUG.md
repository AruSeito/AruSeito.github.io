---
title: 在React中因浅拷贝引发的BUG
categories:
  - React
tags:
  - 深拷贝/浅拷贝
  - 数据结构
  - React.Memo
keywords:
  - React.Memo
  - 深拷贝/浅拷贝
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg29.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg29.jpg
abbrlink: db2c0d0e
date: 2021-07-21 23:29:56
updated: 2021-07-21 23:29:56
---

今天在开发过程中遇到一个 BUG：useEffect 没有按照想象中的执行。所以有了本篇文章。

需求如下：有个列表，列表项中的`content`字段如果内容大于 3 行，则仅显示三行，并有个展开的按钮。

现象：通过接口拉回来的数据，如果本来就大于三行，会显示展开的按钮。当点击列表内的项时，呼出原生 APP 的修改页面，修改内容后，调用我准备好的方法，来进行数据更新。如果原来的内容小于三行，修改到三行以上的时候不会被收起，也不会有展开按钮。

分析：模拟这种行为的[代码](https://codesandbox.io/s/admiring-bose-28noo)

当我们点击的时候发现，仅有初次渲染时 useEffect 的输出，并没有我点击更改后的输出，但是他的内容却变了。

![第一次点击](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210721/firstAfterClick.png)

开始我胸有成竹的认为因为在更新的时候进行的是浅比较，所以没触发更新流程。（现在冷静下来想下，没触发更新流程数据怎么会更新呢 23333333）

然后我就非常潇洒的在`Card`这层包裹了`React.memo`,如代码中注释的那样，让他进行个自定义比较去，然后触发更新流程。

再次点击按钮后，发现视图居然没更新！！！，并且神奇的是`prevProps`和`nextProps`竟然都是最新的。

![第二次点击](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210721/secondClick.png)。

百思不得其解，为什么会这样。

在经过搜索后发现[github](https://github.com/facebook/react/issues/16643)这条 issues。

然后将在进行操作的地方对数据进行了深拷贝，就能顺利触发 useEffect 了。

问题解决了。但是这是为什么呢？为什么深拷贝再操作就能解决问题呢？

看图：

![有问题的情况](https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/20210721/wrongProps.png)

因为在 newList 里存的还是老地址。当对老地址的数据进行修改的时候，`prevProps`取到的也就是最新的值了。

所以在对 newList 内的数组项进行复制的时候要进行深拷贝，让他们不再指向老地址，这样就不会互相影响了。

解决方案：

一：深拷贝

二：数据结构优化，使用扁平化处理。充分利用 React 中默认的浅比较。可以采用 Immutable 等库进行数据处理。
