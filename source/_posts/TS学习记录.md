---
title: TS学习记录
categories:
  - 旧博客文章
tags:
 - 前端
date: 2021-02-14 22:16:28
index_img: /img/banner/bg26.jpg
banner_img: /img/banner/bg26.jpg
---
# TS 常用点整理

[scode type="green"]具体实践可以看
github：[component-with-ts][1]
本来想详细介绍组件的开发过程的，但是奈何语言组织能力比较差，脑子知道如何去做，但是不知道转换成文字怎么描述，所以就先暂时隐藏了实现过程
[/scode]

## 原始数据类型

1. boolean `let isOk：boolean = false`
2. number `let age: number = 20`
3. string `let message: string = 'isOk'`
4. undefined `let u: undefined = undefined`
5. null `let n : null = null`

## any 类型和 联合类型

1. any 类型  `let notSure:any = 4` `notSure = 'maybe'`
2. 联合类型 `let numberOrString: number|string = 234` `numberOrString = 'abc'`

## Array和元祖

1. Array `let arrOfNumbers: number[] = [1,2,3,4]`
2. 元祖 `let user:[string, number] = ['isOk','234']`

元祖实际上就是规定了不同类型的已知长度数组
typescript
## interface 接口

接口的主要功能：

1. 对对象的形状进行描述
2. 对类进行抽象
3. Duck Typing（对象的一种推断策略）

```typescript
interface IPerson {
    readonly id: number; //只读属性
    name: string;
    age?: number; // ?代表可选属性
}

let chenxiumiao: IPreson = {
    id: 1
    name : 'chenxiumiao',
    age: 23
}


```

readonly 与 const 区别：readonly 是用在属性上的，const 是用在变量上的。

## 函数
描述函数时描述的为参数与返回值

```typescript
//函数声明
function add (x: number , y: number , z?: number): number //可选参数要放在最后
{
    if(typeof z === 'number'){
        return x + y + z
    }else {
        return x+y
    }
    
}

//函数表达式

const add = function(x: number , y: number , z: number = 10): number
{
    if(typeof z === 'number'){
        return x + y + z
    }else {
        return x+y
    }
}

const add2 :(x: number , y: number , z?: number) => number = add //=>不是箭头函数，而是函数表达式返回值的表达方式。

```

## 类

```typescript
class Animal {
    public name:string;
    static categoies: string[] = ['mammal','bird']  //静态属性，与实例关系不大
    static isAnimal(a){
        return a instanceof Animal;
    }
    constructor(name:string){
        this.name = name
    }
    run(){
        return `${this.name} is running`
    }
}

const snake = new Animal('lily')

class Dog extends Animal{
    bark(){
        return `${this.name} is barking`
    }
}

const xiaobao = new Dog('xiaobao')

class Cat extends Animal{
    constructor(name){
        super(name)
        console.log(this.name)
    }
    run(){
        return 'Meow,' + super.run()
    }
}

const maomao = new Cat('maomao')

```

|           | 自身权限 | 子类权限 |
|-----------|------|------|
| public    | 可以   | 可以   |
| private   | 可以   | 不可以  |
| protected | 可以   | 可以   |
| readonly  | 只读   | 只读   |

## interface接口与类

```typescript
//找不出Car 与 Cellphone共性，所以提取为 interface
interface Radio{
    switchRadio(triggerL:boolean):void
}

interface Battery{
    checkBatteryStatus();
}

interface RadioWithBattery extends Radio{
    checkBatteryStatus();
}
class Car implements Radio{
    switchRadio(){
        
    }
}

class Cellphone implements /*Radio,Battery*/ RadioWithBattery{
    switchRadio(){
    
    }
    checkBatteryStatus(){
    
    }
}


```

## 枚举 enums

```typescript
//使用 const 可以提升性能，具体看 ts 编译后的 js 文件对比
const enum Direction{
    Up,//进行数字赋值后，后续会按照自增方式进行赋值。字符串赋值时必须将每项都赋值
    Down,
    Left,
    Right
}
console.log(Direction.Up)
console.log(Direction[0])
```

## 泛型 Generics

泛型：定义函数接口或类时，不预先指定具体类型，在使用时指定类型。

```typescript
function echo<T>(arg:T):T{//<>是泛型名称，相当于创建了一个占位符
    return arg
}
const str: string = 'str'

const result = echo(str)


function swap<T,U>(tuple:[T,U]):[U,T]{
    return [tuple[1],tuple[0]]
}

const result = swap(['str',1234])
```

约束泛型

```typescript
//函数
function echoWitchArr<T>(arg:T[]):T[]{
    console.log(arg.length)
    return arg
}

const arrs = echoWitch([1,2,3,4])


interface IWitchLength{
    length:number
}
function echoWitchLength<T extends IWithLength>(arg:T):T{
    console.log(arg.length)
    return arg
}
const str = echoWithLength('str')
const obj = echoWithLength({length:10,width:12})//只要包含 length 属性就可以
const arr2 = echoWithLength([1,2,3])

```

```typescript
//类
class Queuq<T>{
    private data = [];
    
    push(item:T){
        return this.data.push(item)
    }
    
    pop():T{
        return this.data.shift()
    }
}

const queue = new Queue<number>()

```

```typescript
//interface
interface KeyPair<T,U>{
    key:T;
    value:U;
}
let kp1:KeyPair<number,string> = {key:111,value:'str'}

let arr: number[]=[1,2,3]
let arrTwo: Array<number> = [1,2,3]

interface IPlus<T>{
    (a:T,b:T):T
}
function plus(a:number,b:number):number{
    return a+b;
}
function connect(a:string,b:string):string{
    return a+b;
}
const a:IPlus<number> = plus
const b:IPlus<string> = connect
```

## 类型

```typescript
//type aliases
type PlusType = (x:number,y:number)=>number

function sum(x:number,y:number):number{
    return x + y;
}

const sum2:PlusType = sum

type NameResolver = ()=>string
type NameOrResolver = string | NameResolver
function getName(n:NameOrResolver):string{
    if(typeof n === 'string'){
        return n
    }else{
        return n()
    }
}

//type assertion 类型断言
function getLength(input:string | number):number{
   // const str = input as String
   // if(str.length){
   //     return str.length
   // }else{
   //    const number = input as Number
   // }
   // return number.toString().length
   
   if((<string>input).length){
        return (<string>input).length
   }else{
        return input.toString().length
   }
}

```

## 声明文件

```typescript
//声明文件以.d.ts 为后缀
declare var jQuery:(selector: string)=>any
```











  [1]: https://github.com/chenxiumiao/component-with-ts  
  
  



