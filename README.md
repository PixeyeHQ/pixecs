# pixecs 🚀
A pragmatic entity-component-system ([ECS](https://en.wikipedia.org/wiki/Entity_component_system)) module for my gamedev needs.

[![Twitter Follow](https://img.shields.io/twitter/follow/PixeyeHQ?color=blue&label=Follow%20on%20Twitter&logo=%20&logoColor=%20&style=flat-square)](https://twitter.com/PixeyeHQ)
[![Discord](https://img.shields.io/discord/320945300892286996.svg?label=Discord)](http://discord.pixeye.games)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](https://github.com/dimmpixeye/Actors-Unity3d-Framework/blob/master/LICENSE)
[![openupm](https://img.shields.io/npm/v/com.pixeye.ecs?label=openupm&registry_uri=https://package.openupm.com)](https://openupm.com/packages/com.pixeye.ecs/)
[![stars](https://img.shields.io/github/stars/PixeyeHQ/actors.unity?style=social)](https://github.com/PixeyeHQ/actors.unity/stargazers)
 

### Introduction
This project is a part of my future gamedev tech-stack on language called [Nim](https://nim-lang.org/), a powerful language with great promise for gamedev. Pixecs an independant module so it can be used seperately. It's a ongoing project so there will be more changes and info in the future.

## ⭐ Why Pixecs ?
Pixecs is designed as a sparse based ecs with aggressive memory consumption primarly for making pc/consoles games. Aggressive memory consumption is not a cool feature you dream of *but* there are few things I want to stress out:
- Memory is cheap and will become cheaper.
- 99% of the games made by indies or even bigger fellas are relatively small and are faar below the point when memory optimizations for ecs matters.

Key principles for the Pixecs are:
- Pragmatic, [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) approach
- Clean, non-bloated syntax
- Good enough performance

Ecs is very data driven and declarative in it's nature and normally you type a lot with this approach. Pixecs remove a lot of boilerplate code thanks to great Nim macros and templating.

### 📖 Code example

```nim
import pixecs

type CompHealth* = object
  val* : int
type CompMotion* = object
  x*     : float
  speed* : float
type TagStunned* = distinct int

ecs.init(1_000_000)

ecs.add CompHealth
ecs.add CompMotion
ecs.add TagStunned, AsTag

ecs.entity player:
  let chealth = player.get CompHealth
  let cmotion = player.get CompMotion
  chealth.val = 10
  cmotion.speed = 2

for x in 0..<60: # sort of update loop as example :)
  
  if x == 10:
    player.inc TagStunned, 10
    echo "Alpaca strikes! Player is stunned for 10 ticks"
 
  if x == 50:
    echo "Platypus sends player to eternal sleep!"
    player.chealth.val -= 20
  
  for e, chealth in ecs.query(Ent, CompHealth):
    if chealth.val <= 0:
      e.kill
      echo e, " got killed"

  for e in ecs.group(CompMotion,!TagStunned):
    let cmotion = e.compMotion
    cmotion.x += cmotion.speed
    echo e, "is moving to x: ", cmotion.x
    
  for e in ecs.group(TagStunned):
    e.dec TagStunned
    echo e, " is stunned and can't move"
  
```
### ⚡ Performance
Good enough for any types of games I hope. It's relatively fast and way faster then my previos [framework](https://github.com/PixeyeHQ/actors.unity) designed for Unity. 
You can build benchmark with ```nimble bench``` to get some info.

My results:
Create 1_000_000 entities with components.
```
Time elapsed for Create Entity + one comp: 0.047000000 seconds
Time elapsed for Create Entity + two comp + group: 0.104000000 seconds
```
Kill 1_000_000 entities with components.
```
Time elapsed for Kill Entity with one comp: 0.035000000 seconds
```
Iterate 1_000_000 entities via group/query
```
Time elapsed for iterate group: 0.004000000 seconds
Time elapsed for iterate query: 0.002000000 seconds
Time elapsed for iterate query with ent: 0.002000000 seconds
```
Working station: AMD Ryzen 5 2600X, 16336MB RAM  

### 💬 Credits
Developed by Dmitry Mitrofanov and every direct or indirect contributors to the GitHub.     
Recurring contributors (2020): Dmitry Mitrofanov @PixeyeHQ

### 📘 License
Pixecs is licensed under the MIT License, see LICENSE for more information.
