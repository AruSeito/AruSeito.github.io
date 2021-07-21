---
title: (随手记录)-GIT解决合并错分支
categories:
  - 随手记录
tags:
  - GIT
keywords:
  - revert
  - 回滚merge操作
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg32.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg32.jpg
abbrlink: afdedcbf
date: 2021-07-14 22:56:58
updated: 2021-07-14 22:56:58
---

今天在进行大版本升级完，将版本分支归档到 main 分支的时候，发现 commits 特别多，一共有 2000 多条。

感觉不太对劲，第一反应就是有人把 dev 分支合并进了某个功能分支，然后在从功能分支合并到版本分支的时候没有仔细看。（因为在上一家公司就遇到过一次。。。）

然后抓紧打开 Graph（VSCode 也有插件）看一下路径。

发现果然如我所料。

那其实是需要仅仅将这个 merge 的请求回滚的。方法很多。

1. 最简单粗暴的：先使用 `git reflog`看一下操作，找到 merge 时的 Head，直接把头重新定到 merge 前一个就可以。

2. 还可以使用 rebase git rebase -i merge 操作前的 commitID.然后在信息里面把 merge 进来的信息前缀从 pick 改为 drop

3. revert 反作

在合并错的分支我们本意是没有 dev 分支里的内容的。也就是没有 dev 这个文件,并且 main 文件内同时保留合并后的修改内容。

直接`git revert merge的commitId -m 1/2` 。

这个 1 和 2 代表主分支是谁。

可以通过`git show merge的commitId查看parent`。

如果要以 parent 的第一个为基准就输入 `-m 1` 如果是第二个就是`-m 2`

然后处理一下冲突就可以了。

一句话总结： revert 就是将对应 commitId 的操作反向操作一遍。

更详细的可以查看[Git 之 revert](https://www.cnblogs.com/bescheiden/articles/10563651.html) 和 [Git 撤销某次 merge 的正确实现方法](https://www.dazhuanlan.com/2019/11/15/5dcdd42820309/)
