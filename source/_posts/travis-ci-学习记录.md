---
title: travis-ci学习记录
categories:
  - 旧博客文章
tags:
  - 工程化
  - 持续化集成
index_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg7.jpg
banner_img: >-
  https://cdn.jsdelivr.net/gh/AruSeito/AruSeito.github.io@main/source/img/banner/bg7.jpg
abbrlink: 1dae22d5
date: 2021-02-15 22:06:58
updated: 2021-02-15 22:06:58
---
名词解释大部分均为机器直翻，部分稍加个人理解

## 名词解释

- job：一个自动化的过程，克隆存储库到一个虚拟环境，然后执行一系列的*phases*，如编译代码，运行测试等。如果`script`阶段的返回代码非零，则作业失败。
- phase：*job*的连续步骤。例如，`install`阶段在`script`阶段之前，`script`阶段在可选的`deploy`阶段之前。
- build：按顺序运行的一组*job*。例如，一个*build*可能有两个*job*，每个*job*用不同版本的编程语言测试一个项目。当所有的*job*都完成时，*build*就结束了。
- stage：*build stages*是对*job*进行分组的一种方法，并且在每个*stage*中并行运行*job*，但是要按顺序运行*stage*。

## 生命周期

1. `apt addons` - 可选，用来添加apt源、apt包等
2. `cache component` - 可选，用来设置缓存不经常更改的东西，加快构建速度
3. `before_install` - 在`install`之前
4. `install` - 安装需要的依赖，可以指定自己的脚本来安装依赖，否则取决于语言
5. `before_script` - 在`script`之前
6. `script` - 运行构建脚本
7. `before_cache` - 可选，当切仅当缓存生效时
8. `after_success` 或`after_failure` - 当构建成功/失败后，结果保存在``TRAVIS_TEST_RESULT``环境变量中。
9. `before_deploy` - 可选，当且仅当部署处于活动状态
10. `deploy` - 可选，部署
11. `after_deploy` - 可选，当且仅当部署处于活动状态
12. `after_script` - 在`script`之后

### 中断构建

- 如果`befor_install`、`install`和`before_script`返回一个非0的退出码，则构建出错并且立即退出。
- 如果`script`返回非零退出码，则构建失败，但在被标记为失败之前继续运行。
- `after _ success`、`after _ failure`、`after _ script`、`after _ deploy` 和后续阶段的退出代码不影响构建结果。但是，如果其中一个阶段超时，构建将被标记为失败。

## 实践遇到的问题记录

按照[发布npm](https://docs.travis-ci.com/user/deployment/npm/)配置一个最简单的npm发布。

在配置中并未配置test阶段，但是travisCI会默认在执行完 `npm install`即 `install`阶段后执行 `npm run test`。一开始我在 `package.json`配置的 `"test": "npm run test is running!",`。看travis中的日志发现一直死循环在执行 `npm run test` ，原来这个在里面会转换成相应的命令，想输出配置信息应该 `"test": "echo \" ci run success \""`
