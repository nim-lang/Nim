#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## 这个模块包含了Nim对锁和条件变量的支持。

const insideRLocksModule = false
include "system/syslocks"

type
  Lock* = SysLock ## Nim的锁; 重入或者不重入。
  Cond* = SysCond ## Nim的条件变量

{.push stackTrace: off.}

proc initLock*(lock: var Lock) {.inline.} =
  ## 初始化指定的锁。
  initSysLock(lock)

proc deinitLock*(lock: var Lock) {.inline.} =
  ## 释放锁的相关资源。
  deinitSys(lock)

proc tryAcquire*(lock: var Lock): bool =
  ## 试图获取指定的锁。成功返回 `true` 。
  result = tryAcquireSys(lock)

proc acquire*(lock: var Lock) =
  ## 获取指定的锁。
  acquireSys(lock)

proc release*(lock: var Lock) =
  ## 释放指定的锁。
  releaseSys(lock)


proc initCond*(cond: var Cond) {.inline.} =
  ## 初始化指定的条件变量。
  initSysCond(cond)

proc deinitCond*(cond: var Cond) {.inline.} =
  ## 释放条件变量的相关资源。
  deinitSysCond(cond)

proc wait*(cond: var Cond, lock: var Lock) {.inline.} =
  ## 等待条件变量 `cond`.
  waitSysCond(cond, lock)

proc signal*(cond: var Cond) {.inline.} =
  ## 发送一个信号给条件变量 `cond`.
  signalSysCond(cond)

template withLock*(a: Lock, body: untyped) =
  ## 获取指定锁, 执行body中的语句，并且在语句执行完成之后释放锁。
  mixin acquire, release
  acquire(a)
  {.locks: [a].}:
    try:
      body
    finally:
      release(a)

{.pop.}
