---
title: 小试PWA
categories:
  - 前端工程化
tags:
  - PWA
keywords:
  - PWA
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg6.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg6.jpg
abbrlink: 246388ad
date: 2021-11-01 20:32:05
updated: 2021-11-01 20:32:05
---

## 文件结构

首先 PWA 的与正常的 web 都是一样的，只是在 html 引入了一个叫`manifest.webmanifest`的 json 文件。官方名：应用清单

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <link rel="manifest" href="./manifest.webmanifest" />
    <title>Progressive Web App</title>
  </head>
  ...
</html>
```

文件内容如下：

```json
// manifest.webmanifest
{
  "name": "Progressive Web App",
  "short_name": "PWA",
  "description": "test pwa",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#fff",
  "icons": [
    {
      "src": "./icon.png",
      "sizes": "672x672",
      "type": "image/png"
    }
  ]
}
```

字段说明

- name：应用程序的全名（必须）
- short_name：简称
- description：程序的简介
- icons：安装下来显示的图标（必须）
- start_url：启动程序时启动的入口 比如我是`localhost/1/2/index.html`访问的主页，那我这个地方就要填写`./1/2/index.html`
- display：程序的显示方式。可以是 fullscreen，standalone，minimal-ui，browser。
- background_color：默认背景的颜色，在安装期间和启动时会用到。

更多可查看[Manifest 字段说明](https://developer.mozilla.org/en-US/docs/Web/Manifest)

## 过程

因为 pwa 是基于 service worker 的，所以需要搞个证书，搭建一个 HTTPS 环境。

### 生成 SSL 证书

首先新建一个配置文件 ssl.conf 如下：

```conf
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = GB
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = England
localityName                = Locality Name (eg, city)
localityName_default        = Brighton
organizationName            = Organization Name (eg, company)
organizationName_default    = Hallmarkdesign
organizationalUnitName            = Organizational Unit Name (eg, section)
organizationalUnitName_default    = IT
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_max              = 64
commonName_default          = localhost

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
IP.1    = 127.0.0.1
DNS.1   = localhost
```

1. 生成私钥 `openssl genrsa -out private.key 4096`

2. 生成证书请求文件（CSR）`openssl req -new -sha256 -out private.csr -key private.key -config ssl.conf`

3. 生成证书 `openssl x509 -req -days 3650 -in private.csr -signkey private.key -out private.crt -extensions req_ext -extfile ssl.conf`

然后在 nginx 啥的上导入进去就可以了

TIPS:VSCODE 可以安装个[liveServer](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)，然后在设置里填入一下 key 和 crt 的绝对路径就可以了。

环境准备好了，可以开始撸代码了

### 代码环节

因为 SW 可以缓存请求，我们可以先搞个请求出来。

```js
async function getNews() {
  const res = await fetch(
    "https://www.fastmock.site/mock/90081b6542ca917fc651013fe10b3815/api/getNews",
  );
  const json = await res.json();

  const main = document.querySelector("#main");
  main.innerHTML = json.title;
}
```

注册 SW

```js
async function registerSW() {
  // 判断浏览器是否支持SW
  if ("serviceWorker" in navigator) {
    try {
      // 注册SW
      await navigator.serviceWorker.register("./sw.js");
    } catch (e) {
      console.error("SW register failed");
    }
  }
}

window.addEventListener("load", () => {
  getNews();
  registerSW();
});
```

然后开始写 SW 具体的一些操作。

首先定义一个`cacheName`,`const cacheName = "news@v2"`。

然后再定义一下我们要缓存的文件

```js
// 这个一定要写全，不然在浏览器上不会出现安装的按钮
const staticAssets = ["./", "./index.html", "./index.js", "./sw.js"];
```

接着再安装 SW

```JS
// self相当于window，只不过这个self此时代表的SW
self.addEventListener("install", async () => {
  // SW环境下用来存储的东西
  const cache = await caches.open(cacheName);
  await cache.addAll(staticAssets);

  // 手动触发sw的activate生命周期
  return self.skipWaiting();
})
```

再写激活状态的需要执行的东西

```js
self.addEventListener("activate", async () => {
  // 更新客户端上的sw相关文件
  self.clients.claim();
});
```

因为我们还有一个网络请求，所以我们要对网络请求也进行缓存

```js
self.addEventListener("fetch", async (e) => {
  // e是请求
  const req = e.request;
  const url = new URL(req.url);

  // 如果请求的origin和当前origin相等，进行缓存匹配
  if (url.origin === location.origin) {
    e.respondWith(cacheFirst(req));
  } else {
    e.respondWith(newtworkAndCache(req));
  }
});

async function cacheFirst(req) {
  // 打开存储器
  const cache = await caches.open(cacheName);
  // 查询是否有匹配的缓存
  const cached = await cache.match(req);
  // 如果有就返回，没有就进行网络请求。
  return cached || fetch(req);
}

async function newtworkAndCache(req) {
  // 打开存储器
  const cache = await caches.open(cacheName);
  try {
    // 进行网络请求
    const fresh = await fetch(req);
    // 将缓存放到存储里去
    await cache.put(req, fresh.clone());
  } catch (e) {
    // 如果请求失败后，找缓存中是否有该请求
    const cached = await cache.match(req);
    return cached;
  }
}
```

这时再进入网页请求的话就会看到所有资源请求之前都带有一个小齿轮，这代表 SW 已经好了

在 chromeDevTools-应用分栏下可以看到有个清单和 ServiceWorker 的分类，可以在清单下看到为什么不能安装，按照提示进行修改就可以了。
