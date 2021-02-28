---
title: enzyme学习记录之Shallow,Mount,render的区别
categories:
  - 自动化测试
tags:
  - 自动化测试
  - jest
  - enzyme
index_img: https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg6.jpg
banner_img: https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg6.jpg
date: 2021-02-20 18:38:03
updated: 2021-02-20 18:38:03
---

## render
```JavaScript
/**
 * Render react components to static HTML and analyze the resulting HTML structure.
 */
export function render<P, S>(node: ReactElement<P>, options?: any): cheerio.Cheerio;

```
通过跟进方法可以看到注释表明：是将React组件渲染为HTML结构。
通过查阅资料又得出：该render方法仅调用组件内的render方法，但是会渲染全部的子组件

## shallow
浅渲染，一个真正的单元测试。子组件并不会渲染。渲染的结果为React树。
在调用该方法时，会调用组件内的生命周期：`constructor`和`render`。
在使用该方法渲染后会得到一个：`ShallowWrapper`,`ShallowWrapper`内部又包含又`setProps`方法，在调用`setProps`方法时，则会调用生命周期： 
- `componentWillReceiveProps`
- `shouldComponentUpdate`
- `componentWillUpdate`
- `render`
当`ShallowWrapper`调用`unmount`方法时，仅调用生命周期的`componentWillUnmount`

## mount
测试`componentDidMount`和`componentDidUpdate`的唯一方式，会渲染包括子组件在内的所有组件。渲染结果为React树
在调用该方法时，会调用组件内的生命周期
- `constructor`
- `render`
- `componentDidMount`
使用`mount`的返回值为`ReactWrapper`，也可以调用`setProps`方法，调用的生命周期为
- `componentWillReceiveProps`
- `shouldComponentUpdate`
- `componentWillUpdate`
- `render`
- `componentDidUpdate`
在使用`unmount`时，
- `componentWillUnmount`

## 总结
- 如果需要测试`componentDidMount`和`componentDidUpdate`，就使用`mount`
- 如果没必要渲染子组件，使用`shallow`
- 如果不涉及到生命周期函数，使用`render`
