---
title: MWeb发布服务配置与图床配置教程
categories:
  - 旧博客文章
tags:
  - MWEB
  - 工具
date: 2021-02-14 22:09:55
updated: 2021-02-15 00:34:32
index_img: https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg25.jpg
banner_img: https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg25.jpg
---
## 前言

使用MWeb完全是因为写博客，反复打开博客进行编辑不太方便。就去找了一下是否有本地的东西能跟博客接口连接的东西。

## 发布服务的配置

1. 首先进入typecho的后台，打开`设置-基本`找到`XMLRPC 接口`将其设置为打开
2. 打开`控制台-个人设置`，打开`在 XMLRPC 接口中使用 Markdown 语法`（不打开的话会被解析为html，当时被这个纠结过。）
3. 打开MWeb的`偏好设置-发布服务`，点击`Metawebblog API`。按照要求填写即可。然后点击测试即可。

> 注：API地址为：博客网址/action/xmlrpc 账号密码为发布人的账号密码。

## 图床配置
我们需要两个插件，`coscmd`和`qcloud-cos-mweb`。他们的github连接如下。

[button color="info" icon="glyphicon glyphicon-download-alt" url="https://github.com/tencentyun/coscmd" type=""]Coscmd[/button]

[button color="info" icon="glyphicon glyphicon-download-alt" url="https://github.com/scue/qcloud-cos-mweb" type=""]qcloud-cos-mweb[/button]

1. 安装`coscmd`，打开控制台。输入`pip3 install coscmd == 1.8.5.5`（需要安装过python3,为什么选择coscmd的1.8.5.5版本？因为最新版有BUG。查过issue后得知只有1.8.5.5可以使用。）
2. 找个自己能找到的地方输入`git clone https://github.com/scue/qcloud-cos-mweb.git`将其下载到本地。
3. 输入`coscmd config -a <secret_id> -s <secret_key> -b <bucket> -r <region>`，或者直接`vim ~/.cos.conf`来设置相关信息
    * `<secret_id>` 与 `<secret_key>`可以在腾讯云的`控制台-访问管理-API密钥管理`中查看
    * `<bucket>`对应`对象存储-相应的存储桶-基础配置`中的空间名称
    * `<region>`对应`所属地域`后的`ap-xxxx`
    * 如果是通过vim修改的配置需要以下信息：![-w453](https://chenxiumiao-1252816278.cos.ap-beijing.myqcloud.com/blog/15562976545322.jpg)
4. 用控制台进入到`qcloud-cos-mweb`，输入`./qcloud-cos-upload -help`查看监听地址。然后输入`./qcloud-cos-upload`运行该服务。
5. 在图床自定义 API地址输入：`http://监听地址/upload`，其余按照喜好填写即可。

## 结尾
以后使用Mweb发布文章时，如果文章内有图片的话需要先点把图片上传至图床，然后在点击博客名称就可以发布文章了。在发布文章时一定要选择发布为MarkDown。