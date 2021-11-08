---
title: 再探webpack-dev-server
categories:
  - 前端工程化
tags:
  - webpack
keywords:
  - webpack-dev-server
  - 热更新
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg3.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg3.jpg
abbrlink: d836125a
date: 2021-11-08 21:55:36
updated: 2021-11-08 21:55:36
---

之前写过一篇关于热更新的文章:[开着飞机修引擎-热更新](https://aruseito.github.io/article/57ff1b88/)，但是只描述了 ws 是如何通知的，只是简单带过了客户端这面的更新流程，这次我们打开[源码](https://github.com/webpack/webpack-dev-server)，从头到尾一探究竟。

## 服务端

我们在上一篇文章中已经知道热更新的推送是依赖于 ws 的，所以我们先从熟悉的地方入手，找到创建 ws 的方法

```js
// lib/Server.js
createWebSocketServer() {
    this.webSocketServer = new (this.getServerTransport())(this);
    this.webSocketServer.implementation.on("connection", (client, request) => {
      // ...一些配置的准备与检查

      if (this.options.hot === true || this.options.hot === "only") {
        this.sendMessage([client], "hot");
      }

      if (this.options.liveReload) {
        this.sendMessage([client], "liveReload");
      }

      if (this.options.client && this.options.client.progress) {
        this.sendMessage([client], "progress", this.options.client.progress);
      }

      if (this.options.client && this.options.client.reconnect) {
        this.sendMessage([client], "reconnect", this.options.client.reconnect);
      }

      if (this.options.client && this.options.client.overlay) {
        this.sendMessage([client], "overlay", this.options.client.overlay);
      }

      if (!this.stats) {
        return;
      }

      this.sendStats([client], this.getStats(this.stats), true);
    });
  }
```

咱们在启用的时候仔细看 ws 的响应就是上面这串代码。在看一下它的`sendMessage`的实现。
一顿操作结束后调了个`sendStats`

```js
  sendStats(clients, stats, force) {
    const shouldEmit =
      !force &&
      stats &&
      (!stats.errors || stats.errors.length === 0) &&
      (!stats.warnings || stats.warnings.length === 0) &&
      this.currentHash === stats.hash;

    if (shouldEmit) {
      this.sendMessage(clients, "still-ok");

      return;
    }

    this.currentHash = stats.hash;
    this.sendMessage(clients, "hash", stats.hash);

    if (stats.errors.length > 0 || stats.warnings.length > 0) {
      if (stats.warnings.length > 0) {
        this.sendMessage(clients, "warnings", stats.warnings);
      }

      if (stats.errors.length > 0) {
        this.sendMessage(clients, "errors", stats.errors);
      }
    } else {
      this.sendMessage(clients, "ok");
    }
  }
```

这个方法主要是拿到了编译好的文件的 hash,并记录下来，然后广播出去。如果有错误或者警告就将错误/警告发送出去，不然发送 ok，

```js
 sendMessage(clients, type, data) {
    for (const client of clients) {
      // `sockjs` uses `1` to indicate client is ready to accept data
      // `ws` uses `WebSocket.OPEN`, but it is mean `1` too
      if (client.readyState === 1) {
        client.send(JSON.stringify({ type, data }));
      }
    }
  }
```

这里他为什么要遍历呢？不知道大家有没有仔细看过，如果我有两个 tab 页都打开了这个页面，更改一个的话，两个都会触发热更新，其实是跟这里有关，他把链接好的客户端都存在了一个数组里，然后开始遍历，只有状态为 Open 的时候才会发送日志。

我们更新内容之后 ws 还会发送一个"invalid"的内容，我们根据这个找到

```js
  setupHooks() {
    this.compiler.hooks.invalid.tap("webpack-dev-server", () => {
      if (this.webSocketServer) {
        this.sendMessage(this.webSocketServer.clients, "invalid");
      }
    });
    this.compiler.hooks.done.tap("webpack-dev-server", (stats) => {
      if (this.webSocketServer) {
        this.sendStats(this.webSocketServer.clients, this.getStats(stats));
      }

      this.stats = stats;
    });
  }
```

这里的`this.webSocketServer`就是在上面 createWebSocketServer 中 new 出来的。
`this.compiler.hooks.invalid`是指 webpack 的 compiler 的勾子：在一个观察中的 compilation 无效时执行。
`this.compiler.hooks.done`也是指 webpack 的 compiler 的钩子：在 compilation 完成时执行。
`tap`是指绑定某方法到事件钩子上，还有`tapAsync`,`tapPromise`异步的钩子。

在编译完成时又调用了`this.sendStats`，以上就是服务端处理的一个流程。

## 客户端

服务端发送了，客户端肯定得会接收，所以我们去客户端下面找一下关于 ws 的方法

```js
// client-src/socket.js
const socket = function initSocket(url, handlers, reconnect) {
  client = new Client(url);

  // ...
  // 打开/关闭的方法。

  client.onMessage((data) => {
    const message = JSON.parse(data);

    if (handlers[message.type]) {
      handlers[message.type](message.data);
    }
  });
};
```

可以看到他接收到消息的时候调了个`handlers`,然后再看看哪里调用了`socket`

```js
// client-src/index.js
import socket from "./socket.js";
// ...
socket(socketURL, onSocketMessage, options.reconnect);
```

ok,再根据第二个参数找到 handlers

```js
const onSocketMessage = {
  hot() {
    if (parsedResourceQuery.hot === "false") {
      return;
    }

    options.hot = true;

    log.info("Hot Module Replacement enabled.");
  },
  liveReload() {
    if (parsedResourceQuery["live-reload"] === "false") {
      return;
    }

    options.liveReload = true;

    log.info("Live Reloading enabled.");
  },
  invalid() {
    log.info("App updated. Recompiling...");

    // Fixes #1042. overlay doesn't clear if errors are fixed but warnings remain.
    if (options.overlay) {
      hide();
    }

    sendMessage("Invalid");
  },
  hash(hash) {
    status.previousHash = status.currentHash;
    status.currentHash = hash;
  },
  // ...省略一堆方法
  ok() {
    sendMessage("Ok");

    if (options.overlay) {
      hide();
    }

    reloadApp(options, status);
  },
};
```

`hot`和`liveReload`都是改变了某个选项的值，不管他。
接着看 invalid,再接收到服务端的`invalid`后会再向服务端发一个`Invalid`
hash ，将上一个 hash 和当前 hash 存起来。
ok，执行 reloadApp 的方法。status 如下。

```js
const status = {
  isUnloading: false,
  // TODO Workaround for webpack v4, `__webpack_hash__` is not replaced without HotModuleReplacement
  // eslint-disable-next-line camelcase
  currentHash: typeof __webpack_hash__ !== "undefined" ? __webpack_hash__ : "",
};
```

然后我们再来看`reloadApp`方法

```js
function reloadApp({ hot, liveReload }, status) {
  if (status.isUnloading) {
    return;
  }

  const { currentHash, previousHash } = status;
  const isInitial = currentHash.indexOf(previousHash) >= 0;

  if (isInitial) {
    return;
  }
  // ...省略
}
```

先根据 status 判断是不是没有 loading 上，然后再判断当前 hash 与上一个 hash 是否相等，如果相等则不需要更新。

```js
function reloadApp({ hot, liveReload }, status) {
  // ...省略
  const search = self.location.search.toLowerCase();
  const allowToHot = search.indexOf("webpack-dev-server-hot=false") === -1;
  const allowToLiveReload =
    search.indexOf("webpack-dev-server-live-reload=false") === -1;

  if (hot && allowToHot) {
    log.info("App hot update...");

    hotEmitter.emit("webpackHotUpdate", status.currentHash);

    if (typeof self !== "undefined" && self.window) {
      // broadcast update to window
      self.postMessage(`webpackHotUpdate${status.currentHash}`, "*");
    }
  }
  // allow refreshing the page only if liveReload isn't disabled
  else if (liveReload && allowToLiveReload) {
    let rootWindow = self;

    // use parent window for reload (in case we're in an iframe with no valid src)
    const intervalId = self.setInterval(() => {
      if (rootWindow.location.protocol !== "about:") {
        // reload immediately if protocol is valid
        applyReload(rootWindow, intervalId);
      } else {
        rootWindow = rootWindow.parent;

        if (rootWindow.parent === rootWindow) {
          // if parent equals current window we've reached the root which would continue forever, so trigger a reload anyways
          applyReload(rootWindow, intervalId);
        }
      }
    });
  }
}
```

接着搜索 url 参数，如果 url 参数包含`webpack-dev-server-hot=false`则不会进入热更新的逻辑，如果包含`webpack-dev-server-live-reload=false`则不会进刷新的逻辑。

如果进了热更新逻辑，则广播`webpackHotUpdate`事件。
如果进了刷新的逻辑，就刷新页面了。

再接着找`webpackHotUpdate`在哪注册的。发现是在 webpack 内置的一个消息，我们去`"webpack/hot/emitter.js"`下找。

```js
// webpack/hot/dev-server.js
var upToDate = function upToDate() {
  return lastHash.indexOf(__webpack_hash__) >= 0;
};
hotEmitter.on("webpackHotUpdate", function (currentHash) {
  lastHash = currentHash;
  if (!upToDate() && module.hot.status() === "idle") {
    log("info", "[HMR] Checking for updates on the server...");
    check();
  }
});
```

存储最后一次的 hash 值，判断是否更新了并且当前是否处于空闲状态。

```js
var check = function check() {
  module.hot
    .check(true)
    .then(function (updatedModules) {
      // ...省略
    })
    .catch(function (err) {
      // ...省略
    });
};
```

可以看到 check 里调用了一个 module.hot.check，我们找到这个东西，进去看看返回的 promise 是什么
在`/HotModuleReplacement.runtime.js`文件内找到 hotCheck

```js
function hotCheck(applyOnUpdate) {
  if (currentStatus !== "idle") {
    throw new Error("check() is only allowed in idle status");
  }
  return setStatus("check")
    .then($hmrDownloadManifest$)
    .then(function (update) {
      if (!update) {
        return setStatus(applyInvalidatedModules() ? "ready" : "idle").then(
          function () {
            return null;
          },
        );
      }

      return setStatus("prepare").then(function () {
        var updatedModules = [];
        blockingPromises = [];
        currentUpdateApplyHandlers = [];

        return Promise.all(
          Object.keys($hmrDownloadUpdateHandlers$).reduce(function (
            promises,
            key,
          ) {
            $hmrDownloadUpdateHandlers$[key](
              update.c,
              update.r,
              update.m,
              promises,
              currentUpdateApplyHandlers,
              updatedModules,
            );
            return promises;
          },
          []),
        ).then(function () {
          return waitForBlockingPromises(function () {
            if (applyOnUpdate) {
              return internalApply(applyOnUpdate);
            } else {
              return setStatus("ready").then(function () {
                return updatedModules;
              });
            }
          });
        });
      });
    });
}
```

这里的操作总结一句话就是先设置成 check 状态，然后再设置 prepare 状态，如果 applyOnUpdate 为 false 再设置成 ready。

这两个`$`包裹的是运行时方法，在他的上一层有替换。

```js
	generate() {
		return Template.getFunctionContent(
			require("./HotModuleReplacement.runtime.js")
		)
			.replace(/\$getFullHash\$/g, RuntimeGlobals.getFullHash)
			.replace(
				/\$interceptModuleExecution\$/g,
				RuntimeGlobals.interceptModuleExecution
			)
			.replace(/\$moduleCache\$/g, RuntimeGlobals.moduleCache)
			.replace(/\$hmrModuleData\$/g, RuntimeGlobals.hmrModuleData)
			.replace(/\$hmrDownloadManifest\$/g, RuntimeGlobals.hmrDownloadManifest)
			.replace(
				/\$hmrInvalidateModuleHandlers\$/g,
				RuntimeGlobals.hmrInvalidateModuleHandlers
			)
			.replace(
				/\$hmrDownloadUpdateHandlers\$/g,
				RuntimeGlobals.hmrDownloadUpdateHandlers
			);
	}
```

`hmrDownloadManifest`大概就是对照`hash`进行文件请求一个`[hash].update.json` 下来,然后传递给下一层，这块最好是打断点进去看，不然找源文件有点头秃，都是运行时代码。总结一句话：`hmrDownloadUpdateHandlers`里面会有个 jsonp 方法，如果配置了 CSS 的相关 loader 还会有个`miniCss`的方法，jsonp 方法里面会调用`loadUpdateChunk`，然后`loadUpdateChunk`内又调用了`loadScript`

```js
// lib/runtime/LoadScriptRuntimeModule.js
fn = "loadScript"`${fn} = ${runtimeTemplate.basicFunction(
  "url, done, key, chunkId",
  [
    "if(inProgress[url]) { inProgress[url].push(done); return; }",
    "var script, needAttach;",
    "if(key !== undefined) {",
    Template.indent([
      'var scripts = document.getElementsByTagName("script");',
      "for(var i = 0; i < scripts.length; i++) {",
      Template.indent([
        "var s = scripts[i];",
        `if(s.getAttribute("src") == url${
          uniqueName
            ? ' || s.getAttribute("data-webpack") == dataWebpackPrefix + key'
            : ""
        }) { script = s; break; }`,
      ]),
      "}",
    ]),
    "}",
    "if(!script) {",
    Template.indent([
      "needAttach = true;",
      createScript.call(code, this.chunk),
    ]),
    "}",
    "inProgress[url] = [done];",
    "var onScriptComplete = " +
      runtimeTemplate.basicFunction(
        "prev, event",
        Template.asString([
          "// avoid mem leaks in IE.",
          "script.onerror = script.onload = null;",
          "clearTimeout(timeout);",
          "var doneFns = inProgress[url];",
          "delete inProgress[url];",
          "script.parentNode && script.parentNode.removeChild(script);",
          `doneFns && doneFns.forEach(${runtimeTemplate.returningFunction(
            "fn(event)",
            "fn",
          )});`,
          "if(prev) return prev(event);",
        ]),
      ),
    ";",
    `var timeout = setTimeout(onScriptComplete.bind(null, undefined, { type: 'timeout', target: script }), ${loadTimeout});`,
    "script.onerror = onScriptComplete.bind(null, script.onerror);",
    "script.onload = onScriptComplete.bind(null, script.onload);",
    "needAttach && document.head.appendChild(script);",
  ],
)};`;
```

loadScript 的操作：创建个 script 标签，把 url 赋值给 src 吧啦吧啦一系列操作，最后给给这个加到 html 的 head 的尾部，如果给断点打在最后一行这个，就可以看到了。等到 onLoad 完之后，会再把这个 script 标签移除掉。`script.parentNode && script.parentNode.removeChild(script)`相关逻辑

## 总结

首次启动：

源代码 => 编译（compiler） => bundle.js 产物（这里是默认不分割代码的结果） => 浏览器访问端口 => 服务器返回静态资源（html，css，js 等）
浏览器与 dev-server 建立 Socket 连接，首次收到 hash

更新：

源代码修改 => 增量编译（compiler） => HMR（基于新内容生成[hash].update.js(on)）=> 向浏览器推送消息（包括新的 hash） => 浏览器创建 script 标签下载[hash].update.js => 调用页面更新的方法（module.hot.accept）
