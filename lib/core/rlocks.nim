#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Anatoly Galiulin
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## 这个模块包含Nim对可重入锁的支持.


when not compileOption("threads") and not defined(nimdoc):
  {.error: "Rlocks requires --threads:on option.".}

const insideRLocksModule = true
include "system/syslocks"

type
  RLock* = SysLock ## Nim的可重入锁

proc initRLock*(lock: var RLock) {.inline.} =
  ## 初始化指定的锁。
  when defined(posix):
    var a: SysLockAttr
    initSysLockAttr(a)
    setSysLockType(a, SysLockType_Reentrant())
    initSysLock(lock, a.addr)
  else:
    initSysLock(lock)

proc deinitRLock*(lock: var RLock) {.inline.} =
  ## 释放锁的相关资源。
  deinitSys(lock)

proc tryAcquire*(lock: var RLock): bool =
  ## 试图获取指定的锁。成功返回 `true` 。
  result = tryAcquireSys(lock)

proc acquire*(lock: var RLock) =
  ## 获取指定的锁。
  acquireSys(lock)

proc release*(lock: var RLock) =
  ## 释放指定的锁。
  releaseSys(lock)

template withRLock*(lock: var RLock, code: untyped): untyped =
  ## 获取指定锁, 执行code
  block:
    acquire(lock)
    defer:
      release(lock)
    {.locks: [lock].}:
      code
