---
title: 手写一个Promise/A+
categories:
  - 源码
  - 手撕源码
tags:
  - Promise
  - 手撕代码
keywords:
  - Promise/A+
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg34.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg34.jpg
abbrlink: ba852590
date: 2021-07-04 16:37:34
updated: 2021-07-05 20:02:34
---

{% note success %}
2021/07/04 更新日志： 手写一个符合 Promise/A+规范的 Promise
2021/07/05 更新日志： 完成 Promise.resolve(),Promise.reject(),Promise.race();
{% endnote %}

Promise 在日常开发中经常用到，使用频率相当的高了。为了能够更好的应用 Promise 需要对 Promise 进行一些更深的理解，所以尝试着按照 Promise/A+规范进行了一次手撕代码。

Promise/A+的内容就不细致展开描述一边了，直接开始手撕代码，将规范的内容分解开始进行实践。(具体原版描述请看 Promise/A+)

## 手撕一个 Promise

Promise 有三个状态，两个过程，FULFILLED 有一个 value，REJECTED 有一个 reason

```JavaScript
// 三个状态
const PENDING = "pending";
const FULFILLED = "fulfilled";
const REJECTED = "rejected";

class MyPromise{
  constructor() {
    this.status = PENDING;
    this.value = null;
    this.reason = null;
  }

  // 两个过程来改变状态。并且状态只能从PENDING开始到FULFILLED/REJECTED结束。
  resolve(value) {
    if (this.status === PENDING) {
      this.status = FULFILLED;
      this.value = value;
    }
  }

  reject(reason) {
    if (this.status === PENDING) {
      this.status = REJECTED;
      this.reason = reason;
    }
  }
}
```

在我们使用 Promise 的时，可以这样：

```JavaScript
const promise = new Promise((resolve,reject)=>{
  // doSomethings
})
```

所以我们还需要在构造函数中传入一个函数,并且在初始化的时候传入的函数就已经执行了。

```JavaScript
class MyPromise{
  constructor(fn) {
    this.status = PENDING;
    this.value = null;
    this.reason = null;

    // 在初始化的时候执行传入的函数
    try{
      fn(this.resolve.bind(this),this.reject.bind(this))
    }catch(e){
      this.reject(e);
    }
  }

  // 省略
}
```

按照规范所说，then 方法接收两个参数 onFulfilled,onRejected.并且返回的是一个也是一个 Promise。

```JavaScript
class MyPromise{
  // 省略

  then(onFulfilled,onRejected){
    const promise2 = new MyPromise();
    return promise2;
  }
}
```

onFulfilled/onRejected 必须是个函数，如果不是一个函数则要忽略它，但是我们在使用过程中可以

```JavaScript
const promise = new Promise((resolve,reject)=>{
  // doSomethings
}).then(11111)
```

这是因为传入非函数时，参数会被处理成函数。

```JavaScript
class MyPromise{
  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ?onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise();
    return promise2;
  }
}
```

然后根据当前状态调用不同的函数

```JavaScript
class MyPromise{
  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise((resolve,reject)=>{
      switch(this.status){
        case FULFILLED:
          realOnFulfilled();
          break;
        case REJECTED:
          realOnRejected();
          break;
      }
    });
    return promise2;
  }
}
```

这时可能 status 还没变成终态，因此需要搞个监听，当 status 变成终态时在调用对应的回调。所以，如果这时是 pending 的时候，先将成功和失败的回掉分别存储。

```JavaScript
class MyPromise{
  FULFILLED_CALLBACK_LIST = [];
  REJECTED_CALLBACK_LIST = [];
  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise((resolve,reject)=>{
      switch(this.status){
        case FULFILLED:
          realOnFulfilled();
          break;
        case REJECTED:
          realOnRejected();
          break;
        case PENDING:
          this.FULFILLED_CALLBACK_LIST.push(realOnFulfilled);
          this.REJECTED_CALLBACK_LIST.push(realOnRejected);
      }
    });
    return promise2;
  }
}
```

接下来在 status 变化的时候执行所有的回掉。

```JavaScript
class MyPromise{
  FULFILLED_CALLBACK_LIST = [];
  REJECTED_CALLBACK_LIST = [];
  _status=PENDING;

  get status(){
    return this._status;
  }

  set status(newStatus){
    this._status = newStatus;
    switch(newStatus){
      case FULFILLED:
        this.FULFILLED_CALLBACK_LIST.forEach(callback=>{
          callback(this.value);
        })
        break;
      case REJECTED:
        this.REJECTED_CALLBACK_LIST.forEach(callback=>{
          callback(this.reason);
        })
        break;
    }
  }


  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise((resolve,reject)=>{
      switch(this.status){
        case FULFILLED:
          realOnFulfilled();
          break;
        case REJECTED:
          realOnRejected();
          break;
        case PENDING:
          this.FULFILLED_CALLBACK_LIST.push(realOnFulfilled);
          this.REJECTED_CALLBACK_LIST.push(realOnRejected);
      }
    });
    return promise2;
  }
}
```

如果 then 中的 onFulfilled/onRejected 抛出异常了，则 promise2 不能被执行并且返回 e

```JavaScript
class MyPromise{
  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise((resolve,reject)=>{
      const fulfilledMicrotask = ()=>{
        try{
          realOnFulfilled(this.value);
        }catch(e){
          reject(e)
        }
      }

      const rejectedMicrotask = ()=>{
        try{
          realOnRejected(this.reason);
        }catch(e){
          reject(e);
        }
      }
      switch(this.status){
        case FULFILLED:
          fulfilledMicrotask();
          break;
        case REJECTED:
          rejectedMicrotask();
          break;
        case PENDING:
          this.FULFILLED_CALLBACK_LIST.push(fulfilledMicrotask);
          this.REJECTED_CALLBACK_LIST.push(rejectedMicrotask);
          break;
      }
    });
    return promise2;
  }
}
```

如果 onFulfilled/onRejected 返回值是 X，那么运行 resolvePromise

```JavaScript
class MyPromise{
  // 省略

  isFunction(param){
    return typeof param === "function"
  }

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }
    const promise2 = new MyPromise((resolve,reject)=>{
      const fulfilledMicrotask = ()=>{
        try{
          const x = realOnFulfilled(this.value);
          this.resolvePromise(promise2,x,resolve,reject)
        }catch(e){
          reject(e)
        }
      }

      const rejectedMicrotask = ()=>{
        try{
          const x = realOnRejected(this.reason);
          this.resolvePromise(promise2,x,resolve,reject)
        }catch(e){
          reject(e);
        }
      }
      switch(this.status){
        case FULFILLED:
          fulfilledMicrotask();
          break;
        case REJECTED:
          rejectedMicrotask();
          break;
        case PENDING:
          this.FULFILLED_CALLBACK_LIST.push(fulfilledMicrotask);
          this.REJECTED_CALLBACK_LIST.push(rejectedMicrotask);
          break;
      }
    });
    return promise2;
  }
}
```

接下来完成 resolvePromise 方法。

根据规范，如果 resolvePromise 中 promise2 和 x 是全等，则用 TypeError 作为 reject 的参数。

```JavaScript
class MyPromise{
  //省略

  resolvePromise(promise2,x,resolve,reject){
    if(promise2 === x){
      return reject(new TypeError("promise2和x不能相同"))
    }
  }
}
```

如果 x 是一个 promise，则采用它的状态。
如果 x 是一个对象或者函数，让 then=x.then，如果此时抛出异常 e，则使用 e 作为 reject 参数。
如果 then 是一个函数，用 x 调用(call)它，第一个参数是 resolvePromise，第二个参数是 rejectPromise。如果同时调用 resolvePromise 和 rejectPromise，或者多次调用同一个参数，保证第一个被调用的有效，后续的调用将被忽略。如果 then 不是一个函数，则用 resolve(x)。
如果 x 不是一个对象或函数，则用 resolve(x)。

```JavaScript
class MyPromise{
  //省略

  resolvePromise(promise2,x,resolve,reject){
    if(promise2 === x){
      return reject(new TypeError("promise2和x不能相同"))
    }

    // 如果 x 是一个 promise，则采用它的状态。
    if(x instanceof MyPromise){
      queueMicrotask(()=>{
        x.then((y)=>{
        this.resolvePromise(promise2,y,resolve,reject);
        },reject)
      })
    }
    // 如果 x 是一个对象或函数
    else if(this.isObject(x) || this.isFunction(x)){
      // typeof null会认为null为object,则使用x直接resolve
      if(x === null){
        return resolve(x);
      }

      // 如果 x 是一个对象或者函数，让 then=x.then，如果此时抛出异常 e，则使用 e 作为 reject 参数。
      let then = null;
      try{
        then = x.then
      }catch(e){
        return reject(e);
      }

      // 如果 then 是一个函数，用 x 调用它，第一个参数是 resolvePromise，第二个参数是 rejectPromise。
      if(isFunction(then)){
        // 使用called标记，确保只调用一次。
        let called = false;
        try{
          then.call(x,(value)=>{
            if(called) return;
            called = true;
            this.resolvePromise(promise2,value,resolve,reject);
          },(reason)=>{
            if(called) return;
            called = true;
            reject(reason)
          })
        }catch(e){
          if(called) return;
          return reject(e)
        }
      }
      // 如果 then 不是一个函数，则用resolve(x)
      else{
        resolve(x);
      }

    }
    // 如果 x 不是一个对象或函数，则用resolve(x)。
    else{
      resolve(x);
    }

  }
}
```

这个时候其实已经大概写完了。

但是呢，onFulfilled 和 onRejected 都是微任务，所以我们需要给他们再包装一层

```JavaScript
class MyPromise{
  //省略

  then(onFulfilled,onRejected){
    const realOnFulfilled = this.isFunction(onFulfilled) ? onFulfilled:(value)=>{
      return value;
    }

    const realOnRejected = this.isFunction(onRejected) ? onRejected:(reason)=>{
      throw reason;
    }

    const promise2 = new MyPromise((resolve,reject)=>{
      const fulfilledMicrotask = ()=>{
        queueMicrotask(()=>{
          try{
            const x = realOnFulfilled(this.value);
            this.resolvePromise(promise2,x,resolve,reject);
          }catch(e){
            reject(e)
          }
        })
      }

      const rejectedMicrotask = ()=>{
        queueMicrotask(()=>{
          try{
            const x = realOnRejected(this,reason);
            this.resolvePromise(promise2,x,resolve,reject);
          }catch(e){
            reject(e);
          }
        })
      }

      // 省略
    })
  }
}
```

好了 这就已经写完了。完整代码可见[github](https://github.com/AruSeito/daily-practice/blob/main/others/Promise/promise.js)

使用 promises-aplus-tests 跑了一下测试，全部通过。

在来更新些手写的其他 API

我们在使用 Promise 的时候经常会用到 Promise.resolve()/Promise.reject()这种用法，但是以上写法并不支持直接使用 MyPromise.resolve/reject。这种无需实例即可调用的方法我们称之为静态方法。

Promise.resolve()方法会返回一个 Promise 且状态为 fulfilled。Promise.reject()返回一个 Promise 且状态为 rejected。

```JavaScript
class MyPromise{
  // 省略

  static resolve(value){
    if(value instanceof MyPromise){
      return value;
    }

    return new MyPromise((resolve)=>{
      resolve(value);
    })
  }

  static reject(reason){
    return new MyPromise((resolve,reject)=>{
      reject(reason);
    })
  }
}
```

race 方法：将多个 Promise 实例，包装成一个新的 Promise 实例。只要 p1、p2、p3 之中有一个实例率先改变状态，p 的状态就跟着改变。那个率先改变的 Promise 实例的返回值，就传递给 p 的回调函数。

```JavaScript
class MyPromise{

  static race(promiseList){
    return MyPromise((resolve,reject)=>{
      const length = promiseList.length;

      if(length === 0){
        return resolve();
      }

      promiseList.forEach((promise)=>{
        MyPromise.resolve(promise).then((value)=>{
          return resolve(value)
        },(reason)=>{
          return reject(reason)
        })
      })
    })
  }
}
```
