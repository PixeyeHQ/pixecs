# pixecs 🚀
A pragmatic entity-component-system ([ECS](https://en.wikipedia.org/wiki/Entity_component_system)) module for my gamedev needs.

[![Twitter Follow](https://img.shields.io/twitter/follow/PixeyeHQ?color=blue&label=Follow%20on%20Twitter&logo=%20&logoColor=%20&style=flat-square)](https://twitter.com/PixeyeHQ)
[![Discord](https://img.shields.io/discord/320945300892286996.svg?label=Discord)](http://discord.pixeye.games)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](https://github.com/PixeyeHQ/pixecs/blob/master/LICENSE)
[![Build Status](https://travis-ci.com/PixeyeHQ/pixecs.svg?branch=master)](https://travis-ci.com/PixeyeHQ/pixecs)
[![stars](https://img.shields.io/github/stars/PixeyeHQ/pixecs?style=social)](https://github.com/PixeyeHQ/pixecs/stargazers)
# Archived
For learning purpose I leave code as it is. It was one of my first attempts to make something on Nim. This ecs implementation is rough on edges and might not work as expected. The next iteration of pixecs will be included in little game engine I'm currently working on in Nim language. 


### Introduction
This project is a part of my future gamedev tech-stack on language called [Nim](https://nim-lang.org/), a powerful language with great promise for gamedev. Pixecs is an independant module so it can be used seperately. It's a ongoing project so there will be more changes and info in the future.

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

ecsInit(1_000_000)

ecsAdd CompHealth
ecsAdd CompMotion
ecsAdd TagStunned, AsTag

ecsEntity player:
  let chealth = player.get CompHealth
  let cmotion = player.get CompMotion
  chealth.val = 10
  cmotion.speed = 2

for x in 0..<60: # sort of update loop as example :)
  
  if x == 10:
    player.inc TagStunned, 10
    echo "Alpaca strikes! Player is stunned for 10 ticks"
 
  if x == 50:
    player.chealth.val -= 20
    echo "Platypus sends player to eternal sleep!"

  for e, chealth in ecsQuery(Ent, CompHealth):
    if chealth.val <= 0:
      e.release
      echo e, " got killed"

  for e in ecsGroup(CompMotion,!TagStunned):
    let cmotion = e.compMotion
    cmotion.x += cmotion.speed
    echo e, "is moving to x: ", cmotion.x
    
  for e in ecsGroup(TagStunned):
    e.dec TagStunned
    echo e, " is stunned and can't move"
  
```
## 📖 Overview
### 🔖 Initialization
To initialize you need to call 
```nim 
ecsInit(AMOUNT_OF_ENTITIES) # where AMOUNT_OF_ENTITIES is desired number of entities you want in the game.
```
The ecs is generated staticly for that amount and do not get resized in the runtime of your app. 

### 🔖 Entity
Entities in Pixecs are tuples of id and age. There are several types that represent an entity:
- ```ent```: a tuple of id and age. This is what you get when creating a new entity.
- ```eid```: a distinct ```ent``` id. This is used in iterators. The reason is simple: you don't need to check age in the iterators as you always get valid entites there so no reason to iterate extra value. Eid is compatible with ent type and converted automatically.
- ```EntMeta```: this is an inhouse type for dealing with parents and childs of an entity. Also ```EntMeta``` holds info about component types used for an entity and groups that hold an entity. Developer will never touch the EntMeta directly. EntMeta keeps performance stable in a long distance when you add more and more stuff to your app.


### 🔖 Component
In Pixecs you generate api, storage and aliases for a component by calling ```ecsAdd YOUR_TYPE```
```nim
# define object type
type CompHealth* = object
  val* : int

# generate api, storage and aliases for the component
ecsAdd CompHealth
```
Now you can use the CompHealth with entities.
```nim
let player : ent # some entity. for brevity we will assume that it's defined somewhere.
player.chealth.val = 10 # valid short name alias. It's the same name as type but word Component/Comp is shortened to c.
player.compHealth.val = 10 # valid long name alias. It's the same name as type but with first letter lowercased.
```

> 💡 *The short alias is generated only if you use Component or Comp in the name of a type. This is a part of my style how to write code and I don't force people to write like that.*


### ⚡ Performance
Good enough for any types of games I hope. It's relatively fast and way faster then my previous [framework](https://github.com/PixeyeHQ/actors.unity) designed for Unity. 
You can build benchmark with ```nimble bench``` to get some info.


#### Reference
Working station: AMD Ryzen 5 2600X, 16336MB RAM  
Entities amount: 1000000
| Description     | Measurement                        |
|-----------------|------------------------------------|
| Create Empty    | 0.001576                           |
| Create 1 comp   | 0.0358798                          |
| Create 2 comp   | 0.05099                            |
| Deletion 1 comp | 0.0015519                          |

### 💬 Credits
Developed by Dmitry Mitrofanov and every direct or indirect contributors to the GitHub.     
Recurring contributors (2020): Dmitry Mitrofanov @PixeyeHQ

### 📘 License
Pixecs is licensed under the MIT License, see LICENSE for more information.
