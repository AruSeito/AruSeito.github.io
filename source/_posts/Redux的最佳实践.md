---
title: Redux的最佳实践
categories:
  - Redux
tags:
  - 翻译
  - 最佳实践
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg11.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg11.jpg
abbrlink: 9fd9559e
date: 2021-03-12 13:56:09
---

本版本为个人机器翻译+渣渣翻译+个人理解写成
原版见[Redux的最佳实践官方文档](https://redux.js.org/style-guide/style-guide#priority-a-rules-essential)


## 必须遵守的

### 不要变异State。

不改变现有state，而是去修改state的副本。

因为state可变是导致Redux出现BUG的最常见原因，而且还会破坏Redux DevTools中的`time-travel debugging `功能

```JavaScript
// 错误实践
function todos(state = [], action) {
  switch (action.type) {
    case 'ADD_TODO':
      //state突变
      state.push({
        text: action.text,
        completed: false
      })
      return state
    case 'COMPLETE_TODO':
      // state[action.index]突变
      state[action.index].completed = true
      return state
    default:
      return state
  }
}
// 最佳实践
function todos(state = [], action) {
  switch (action.type) {
    case 'ADD_TODO':
      //返回一个新的副本
      return [
        ...state,
        {
          text: action.text,
          completed: false
        }
      ]
    case 'COMPLETE_TODO':
      return state.map((todo, index) => {
        if (index === action.index) {
          //返回一个新的副本
          return Object.assign({}, todo, {
            completed: true
          })
        }
        return todo
      })
    default:
      return state
  }
}
```

### Reducer内不能有副作用

Reducer 函数应该只依赖于它们的状态和操作参数，并且应该只计算和返回基于这些参数的新状态值

这个规则的目的是保证reducer在被调用时会表现出可预测的行为。（又出现了函数式编程实现）

### 不要在State和Action内放不可序列化（Non-Serializable）的值

避免将不可[序列化](https://zh.wikipedia.org/wiki/%E5%BA%8F%E5%88%97%E5%8C%96)的值(如 Promises、 Symbols、 Maps/set、函数或类实例)放入到 Redux store state或dispatched actions中。这确保通过 Redux DevTools 进行调试的功能能够按预期的方式工作。它还可以确保用户界面按预期更新。

我觉得这个主要是为了保证程序的可预见性，切合函数式编程的思想。如果不可序列化的东西放进去，进行一系列操作后，可能会出现数据丢失。

### 每个应用程序只有一个 Redux Store

主要为了状态管理、追踪方便。


## 强烈建议

### 使用 Redux Toolkit 编写 Redux 逻辑

它的功能建立在Redux建议的最佳实践中，包括建立存储来捕捉变异并启用 Redux DevTools 扩展，用 Immer 简化不可变更新逻辑等。使用 RTK 可以简化逻辑，并确保你的应用程序设置为良好的默认设置。

### 使用 Immer 编写不可变更新

手工编写不可变更新逻辑通常很困难，并且容易出错。Immer 允许使用“变化”逻辑编写更简单的不可变更新，甚至可以冻结开发中的状态，以捕捉应用程序中其他地方的变化。

面试中问的也只是回答出了该点，该点主要是为了方便组件在判断是否更新时，进行浅比较。

### 将有相同特性的文件放到一个文件夹

主要是为了方便维护。

### 把尽可能多的逻辑放在Reducer中

量将计算新状态的逻辑放到适当的 reducer 中，而不是放在准备和分派操作的代码中(如 click handler)。这有助于确保更多实际的应用程序逻辑易于测试，能够更有效地使用time-travel调试，并帮助避免可能导致变异和错误的常见错误。

在一些有效的情况下，应该首先计算部分或全部新state(例如生成唯一 ID) ，但是应该将其保持在最低限度。

### Reducer 应该拥有State结构

Redux 根state由单根 reducer 函数拥有和计算。为了可维护性，这个 reducer 被按照键/值分割成"slices"，每个“slice reducer”负责提供一个初始值并计算对该状态片的更新。

此外，“slice reducer”应该对作为计算状态的一部分返回的其他值进行控制。尽量减少使用“乱分配/返回”，比如 return action. payload 或 return { ...state，...action.payload } ，因为它们依赖于action是正确格式化的内容，而 reducer 实际上放弃了对该状态的所有权。如果操作内容不正确，就会导致错误。

```JavaScript
const initialState = {
    firstName : null ,
    lastName : null ,
    age : null ,
};

export default usersReducer = (state = initialState, action ) {
    switch ( action.type ) {
      // 完全假定 action.payload 将是一个正确格式化的对象。
        case "users/userLoggedIn" : {
           return action.payload;
        }
        default : return state ;
    }
}

//如果代码的某个部分在操作中分派一个“ todo”对象，而不是一个“ user”对象:
//这个 reducer 会盲目地返回 todo，现在当它试图从商店中读取用户信息时，应用程序的其余部分可能会崩溃。
dispatch ({
  type : 'users/userLoggedIn',
  payload : {
    id : 42,
    text : 'Buy milk'
  }
})
```

如果 reducer 进行了一些验证检查以确保 action.payload 实际上具有正确的字段，或者尝试按名称读出正确的字段，那么至少可以部分修复这个问题。不过，这的确增加了更多的代码，所以这是一个为了安全而牺牲更多代码的问题。

使用静态类型确实使这种代码更安全，也更容易被接受。如果`reducer` 知道`action` 是` PayloadAction<user>` ，那么执行`return action.payload`是安全的。

### 根据存储的数据结构命名“State Slices”

`combineReducers`是将这些`slice reducer`连接成一个更大的`reducer`的标准函数。

传递给`combineReducers`的对象中的键名将定义结果`state`对象中键的名称。确保按照保存在数据中的键名进行命名，并避免在键名中使用“reducer”，例如：`{ users: {} ，posts: {}` ，而不是`{ usersReducer: {} ，postsReducer: {}`

### 将“Reducers”视为“State”机器

许多Redux reducer都是“无条件”（unconditionally）的。它们只查看已调度的action并计算新的state，而不将任何逻辑建立在当前state的基础上。这可能会导致错误，因为根据应用程序逻辑的其余部分，某些操作在某些时候可能在概念上不“有效”。例如，“request succeeded”（请求成功）action只应在state为“loading”（已加载）时计算新值，或者仅当有标记为“being Editing”（正在编辑）的项时才应调度“update this item” action。

为了解决这个问题，将“Reducers”视为“state机”，其中当前state和分派action的组合决定是否实际计算一个新的状态值，而不仅仅是无条件地计算操作本身。

### 规范复杂的嵌套/关系`state`

其实就是将state的结构扁平化。

###  把action当作事件，而不是设置者

```JavaScript
//最佳实践，把action当作事件
{ type: "food/orderAdded",  payload: {pizza: 1, coke : 1} }
//差，把action作为设置者（setter）
{
    type : "orders/setPizzasOrdered",
    payload : {
        amount : getState().orders.pizza + 1,
    }
}
{
    type : "orders/setCokesOrdered",
    payload : {
        amount : getState().orders.coke + 1,
    }
}
```

### action的名字有意义

Type 字段主要用于两个目的：

- Reducer检查action.type，以确定是否应该处理此操作来计算新state
- action.type显示在 reduxDevTools 历史日志中，方便调试

### 允许多个reducer对响应一个action

将action作为“事件”并允许多个reducer响应这些action通常会允许程序的代码更好地伸缩，并最小化为完成一个有意义的更新而分派多个操作所需的次数。

### 避免连续分派多个action

通常会导致多个相对昂贵的 UI 更新，造成新能损耗，并且一些中间State可能会被应用程序逻辑的其他部分无效。

最好分派一个单独的“事件”类型的action，这样可以同时产生所有适当的State更新，或者考虑使用action批处理插件来分派多个动作，最后只有一个 UI 更新。

### 评估每个state应该存在哪里

有的state存在store里不合适，更适合存放在组件内部。

### 使用 redux Hooks API

hooks 更容易以多种方式使用。hooks具有更少的间接性，更少的代码编写，并且比 connect 更容易与Typescript一起使用。
主要是使用方便，便于维护。

### 连接更多组件以从store读取数据

有更多的 UI 组件订阅到 Redux Store，并以更细粒度的级别读取数据。这通常会带来更好的 UI 性能，因为在给定的state更改时，需要呈现的组件更少。

与其仅仅连接一个 `<userlist>` 组件并读取整个用户数组，不如让 `<userlist>` 检索所有用户id的列表，将列表项作为 `<UserListItem userId={userId}>`呈现，并将 `<UserListItem>` 连接起来并从store中提取它自己的用户条目。

### 将mapDispatch的对象速记形式与connect一起使用

要连接的 mapDispatch 参数可以定义为作为参数接收分派的函数，也可以定义为包含动作创建者的对象。建议使用 mapDispatch 的“ object 速记”形式，因为它可以大大简化代码。几乎从来没有真正需要将 mapDispatch 编写为一个函数。

### 在函数组件中多次调用useSelector

当使用 useSelector 钩子检索数据时，最好多次调用 useSelector 并检索较小数量的数据，而不是使用单个较大的 useSelector 调用返回一个对象中的多个结果。与 mapState 不同，useSelector 不需要返回对象，而且Selector读取较小的值意味着给定的State更改不太可能导致该组件呈现

### 使用静态类型

类型系统将捕获许多常见错误，改进文档，并具有更好的长期可维护性。

### 使用 Redux DevTools 扩展进行调试

可以查看到：

- 发送Action的历史记录
- 每个action的内容
- action发出后的最后state
- action发出前后state中的差异
- 函数堆栈跟踪显示实际调度操作的代码

### 对Statse而言使用纯JS对象

在状态树中使用纯 JavaScript 对象和数组，而不是使用类似 Immutable.js 这样的专门库。虽然使用 Immutable.js 有一些潜在的好处，但是大多数常见的目标，比如简单的引用比较，通常是不可变更新的属性，不需要特定的库。这还可以使 bundle 大小更小，并降低数据类型转换的复杂性。特别推荐使用 Immer



## 建议

### 将action.type写成domain/eventName

例如：`todos/addTodo`

### 按照“Flux Standard Actions”约定写action

- 总是把他们的数据放入一个payload field 字段

- 可能有一个`meta`字段来获取更多信息

- 可能有一个`error`字段来表示某种失败

### 使用Action Creators

使用Action Creators可以提供一致性，特别是在需要某种准备或额外逻辑来填充action内容的情况下（例如生成唯一的 ID）。

最好使用Action Creators来分派任何动作。但是建议使用 Redux Toolkit 中的 createSlice 函数，而不是手动编写Action Creators，它将自动生成Action Creators和Action.type。

### 使用[Redux-thunk](https://github.com/reduxjs/redux-thunk)进行异步

建议默认使用 Redux Thunk 中间件，因为它对于大多数典型用例(例如基本的 AJAX 数据获取)已经足够了。此外，在 thunks 中使用 async/await 语法使它们更易于阅读。

如果有真正复杂的异步工作流，包括取消、清除、在给定操作发出后运行逻辑或者“后台线程”类型的行为，那么可以考虑添加更强大的异步中间件，如 Redux-Saga 或者 Redux-Observable。

### 将复杂逻辑移出组件

将复杂的同步或异步部件移到组件之外，使用“容器/展示”组件分离。展示组件是外观，容器组件内放业务逻辑，给展示组件提供数据

### 使用 Selector函数从Store读取

### Selector函数的名字应该为`selectThing`格式

### 避免在 Redux 中放置表单状态

数据不是真正的全局数据，不会被缓存，也不会被多个组件同时使用。将表单连接到 Redux 通常需要在每个变更事件上执行调度操作，这会导致性能开销，并且不会带来实际的好处




