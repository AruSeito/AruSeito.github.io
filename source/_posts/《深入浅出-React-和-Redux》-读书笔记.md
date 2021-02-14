---
title: 《深入浅出 React 和 Redux》 读书笔记
categories:
  - 旧博客文章
tags:
 - 前端
 - React
 - Redux
date: 2021-02-14 22:18:05
index_img: /img/banner/bg2.jpg
banner_img: /img/banner/bg2.jpg
---
# 《深入浅出 React 和 Redux》 读书笔记

React 与 Redux 的核心：UI=render(state)

## React
### 关于 prop 与 state

- prop 用于定义外部接口，state 用于记录内部状态；
- prop 的赋值在外部世界使用组件时，state 的赋值在组件内部；
- 组件不应该改变 prop 的值，而 state 存在的目的就是让组件来改变的。

### 组件的生命周期

React 生命周期可能会经历如下三个阶段：

- 装载过程（Mount）：把组件第一次在 DOM 树中渲染的过程
- 更新过程（Update）：当组件被重新渲染的过程
- 卸载过程（Unmount）：组件从 DOM 中删除的过程

#### 装载过程

装在过程中会依次调用以下函数：

- constructor
- getInitialState
- getDefaultProps
- componentWillMount
- render
- componentDidMount

##### constructor

创造一个组件类的实例，会调用对应的构造函数。无状态的 React 组件不需要定义构造函数。目的：
    
- 初始化 state
- 绑定成员函数的 this 环境
    
##### getInitialState 和 getDefaultProps

getInitialState 这个函数的返回值会用来初始化组件的 this.state。getDefaultProps 函数的返回值可以作为 props 的初始值。这两个函数只有用 React.createClass 方法创造的组件类才会发生作用。getInitialState 只出现在装载过程中，在一个组件的整个生命周期过程中，这个函数只被调用一次。使用 Es6 的话，在构造函数中通过给 this.state 赋值完成状态的初始化，通过给类属性 defaultProps 赋值指定 props 初始值。
    
##### render

render 函数并不做实际的渲染动作，它只是返回一个 jsx 描述的结构，最终由 React 来操作渲染过程。render 函数应该是一个纯函数。

##### componentWillMount 和 componentDidMount

componentWillMount发生在“将要装载”的时候，这个时候没有任何渲染结果。
当 render 函数被调用完之后，componentDidMount 函数并不会被立刻调用，componentDidMount 被调用的时候，render 函数返回的东西已经引发了渲染，组件已经被“装载”到了 DOM 树上。
componentWillMount 可以再服务器端被调用，也可以在浏览器端被调用；而 componentDidMount 只能在浏览器端被调用。

#### 更新过程

更新过程中会依次调用以下函数（并不是所有更新都会执行全部函数）：

- componentWillReceiveProps
- shouldComponentUpdate
- componentWillUpdate
- render
- componentDidUpdate

##### componentWillReceiveProps

当父组件的 render 函数被调用就会调用该函数。这个函数适合根据新的 props 值（也就是参数 nextProps）来计算出是不是要更新内部状态 state。

##### shouldComponentUpdate

这个函数返回一个布尔值，告诉 react库这个组件在这次更新过程中是否要继续。可以作为优化点。

##### componentWillUpdate 和 componentDidUpdate

当在服务器端使用 React 渲染时，componentDidUpdate 函数，并不是只在浏览器端才执行的，无论更新过程发生在服务器端还是浏览器端都会被调用。使用 React 做服务器渲染时，基本不会经历更新过程，正常情况下服务器端不会调用 componentDidUpdate

#### 卸载过程

##### componentWillUnmount

componentWillUnmount中的工作往往和 componentDidMount 有关

## Redux

redux 强调的三个基本原则：

- 唯一数据源
- 保持状态可读
- 数据改变只能通过纯函数完成

### 使用 Redux 过程

1. 定义 ActionType 和 Action 构造函数。
2. 创建 reducer，根据 actionType分发动作，reducer 只负责计算状态，不负责存储状态
3. 确定 Store 状态，创建 Store
4. 在 view 中，保持 sotre 上状态和 this.state 同步。
5. 派发 action                

### 容器组件和傻瓜组件

承担第一个任务的组件，负责和 Redux Store 打交道的组件，处于外层，叫做容器组件。承担第二个任务的组件，专心负责渲染页面的组件，处于内层，叫做展示组件。

![容器组件和傻瓜组件的分工](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2019/09/29/rong-qi-zu-jian-he-sha-gua-zu-jian-de-fen-gong.png)

傻瓜组件就是一个纯函数，根据 props 产生结果，不需要 state
容器组件，承担所有和 Store 关联的工作，它的 render 函数是渲染傻瓜组件，负责传递必要的 prop。

### 组件 Context

目的：入口文件引入 Store，其余组件避免直接导入 Store

![React 的 Context](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2019/09/30/react-de-context.png)

使用：创建一个特殊的 React 组件，实现一个实例```getChildContext```方法，让其仅返回```store```，让 render 函数把子组件渲染出来。再定义 childContextTypes。子组件中也要定义相同的 childContextTypes，子组件中定义的构造函数参数要加上 context，store 的访问方式变为```this.context.store.xxx```

### React-Redux

React-Redux 中的 connect：连接容器组件和傻瓜组件，Provider: 提供包含 Store 的 context

##  模块化 React 和 Redux 应用

### 代码文件的组织方式

每个基本功能对应一个功能模块，每个模块对应一个目录

### 模块接口

明确这个模块的对外的接口，这个接口应实现把内部封装起来。

### 状态树的设计

- 一个模块控制一个状态节点：如果 A 模块的 reducer 负责修改状态树上 a 字段下的数据，name 另一个模块 B 的 reducer 就不能修改 a 字段下的数据。
- 避免冗余数据
- 树形结构扁平


## React 组件的性能优化

### 性能分析（[React 16 与 Chrome 开发者工具](https://calibreapp.com/blog/react-performance-profiling-optimization/)）

### 单个 React 组件的性能优化

#### React-Redux 的 shouldComponentUpdate 实现

React 组件类的父类 Component 提供了 shouldComponentUpdate 的默认实现方式，只简单返回 true。当需要达到更高性能时需要自定义 shouldComponentUpdate。

react-redux 用的是尽量简单的方法，做的是“浅层比较”（和 js 中的===类似），如果 prop 的类型是字符串或者数字，只要值相同，那么“浅层比较”的方法会认为二者相同，如果 prop 的类型是复杂对象，那么“浅层比较”的方式只看这两个 prop 是不是同一对象的引用。

### 多个 React 组件的性能优化

#### React 的调和过程

当 React 要对比两个 Virtual DOM 的树形结构的时候，从根节点开始递归往下比对，在树形结构上，每个节点都可以看作一个这个节点以下部分子树的根节点。所以其实这个对比算法可以从 Virtual DOm 上任何一个节点开始。

React 首先检查两个树形的根节点的类型是否相同，根据相同或者不同有不同处理方式。

##### **节点类型不同的情况**

如果树形结构根节点类型不相同，直接认为原来那个树形结构已经没用，可以扔掉，需要重新构建新的 DOM 树，原有的树形上的 React 组件会经历“卸载”的生命周期。这时候componentWillUnmount 方法会被调用，取而代之的组件则会经历装载过程的生命周期，组件的 componentWillMount、render 和 componentDidMount 方法依次被调用。也就是说，对于 Virtual DOM 树这是一个“更新”过程，但是却可能引发这个树结构上某些组件的“装载”和“卸载”过程。

作为开发者，一定要避免作为包裹功能的节点类型被随意改变。

如果 React 对比两个树形结构的根节点发现类型相同，那么就觉得可以重用原来的节点，进入更新阶段，按照下一步骤来处理。
    
##### **节点类型相同的情况**

两个树形结构的根节点类型相同，React 就认为原来的根节点只需要更新过程，不会将其卸载，也不会引发根节点的重新装载。

对于 DOM 类型元素，React 会保留节点对应的 DOM 元素，只对树形结构根节点上的树形和内容做一下比对，然后只更新修改的部分。

对于 React 组件类型，React能做的只是根据新节点的 props 去更新原来根节点的组件实例，引发这个组件实例的更新过程。在这个过程中，如果 shouldComponentUpdate 函数返回 false，更新过程就此打住，不再继续。

在处理完根节点的对比后，React 的算法会对根节点的每个子节点重复一样的动作，这时候每个子节点就成为它所覆盖部分的根节点，处理方式和它的父节点完全一样。

##### **多个子组件的情况**

在序列后增加一个新的组件，React 会发现多出了一个组件，会创建一个新的组件实例，这个组件实例需要经历装载过程，对于之前的实例，React 会引发他们的更新过程，只要shouldComponentUpdate 函数实现恰当，检查 props 之后就返回 false 的话，可以避免实质的更新操作。

在序列前增加一个新的组件，React 会挨个比较，认为新增的组件是之前第一个组件属性的变更，并增加了最后一个组件。

使用 key 可以克服这种浪费

#### key

key 在代码中可以明确的告诉 react 每个组件的唯一标识。

当遇到在序列前添加一个新的组件时，React 根据 key 值，可以知道之前的组件，所以 React 会把新创建的组件插在前面，对于原有组件实例只用原有的 props 来启动更新过程。

### 用 reselect 提高数据获取性能

#### 原理

只要相关状态没有改变，那就直接使用上一次的缓存结果。

#### 计算过程

1. 从输入参数 state 抽取第一层结果，将这第一层结果和之前抽取的第一层结果做比较，如果发现完全相同，就没有必要进行第二部分运算了，选择器直接把之前第二部分的运算结果返回就可以了。这里的比较就是 js 中的`===`操作符比较，如果第一层结果是对象的话，只有是同一对象才会被认为是相同。
2. 根据第一层结果计算出选择器需要返回的最终结果

#### 原则

步骤一运算因为每次选择器都要使用，所以一定要快，运算要非常简单，最好是一个映射运算，通常就只是从 state 参数中得到某个字段的引用就足够，把剩下来的重活累活都交给步骤二去做。 

## React 高级组件（大概略读了一下，以后再细看，待更新）

## Redux 和 服务器通信

### React 组件访问服务器

通常在组件的 ComponentDidMount 函数中做请求服务器的事情，因为当该函数被调用时，装载过程已完成，组件需要渲染的内容已经出现在 DOM 树上。


#### fetch

![-w615](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2019/10/12/15708622641712.jpg)


fetch 函数返回的结果是一个 Promise 对象。fetch 认为只要服务器返回一个合法的 HTTP 响应就算成功，就会调用 then 提供的回调函数。也就是说 当 HTTP 响应的状态码为 400 或者 500 的时候也会调用 then。


### Redux 访问服务器

#### redux-thunk 中间件

Redux-thunk 的思路：在 Redux 的单向数据流中，在 action 对象被 reducer 函数处理之前，是插入异步功能的时机。

在 Redux 架构下，一个 action 对象在通过 store.dispatch 派发，在调用 reducer 函数之前，会先经过一个中间件的环节，这就是产生异步操作的机会，实际上 redux-thunk 提供的就是一个 Redux 中间件，需要在创建 Store 时用上这个中间件。

![Redux 的 action 处理流程](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/2019/10/12/redux-de-action-chu-li-liu-cheng.png)
### 异步 action 对象

redux-thunk 的工作是检查 action 对象是否为函数，如果不是函数就放行，完成普通 action 对象的生命周期，如果发现 action 对象是函数，那就执行这个函数，并把 Store 的 dispatch 的函数和 getState 函数作为参数传递到函数中去，处理过程到此为止，会让这个异步 action 对象继续往前派发到 reducer 函数。

异步 action 构造函数的代码基本上都是如下套路：

```JavaScript
export const sampleAsyncAction = ()=>{
    return (dispatch,getState)=>{
        //在这个函数里可以调用一步函数，
        //自行决定在合适的实际通过 dispatch 参数
        //派发出新的 action 对象
    }
}
```