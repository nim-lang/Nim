#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import locks

type
  FunKind = enum kClosure, kNoconv # extend as needed
  Fun = object
    case kind: FunKind
    of kClosure: fun1: proc () {.closure.}
    of kNoconv: fun2: proc () {.noconv.}

var
  gFunsLock: Lock
  gFuns: seq[Fun]

initLock(gFunsLock)

when defined(js):
  proc addAtExit(quitProc: proc() {.noconv.}) =
    when defined(nodejs):
      asm """
        process.on('exit', `quitProc`);
      """
    elif defined(js):
      asm """
        window.onbeforeunload = `quitProc`;
      """
else:
  proc addAtExit(quitProc: proc() {.noconv.}) {.
    importc: "atexit", header: "<stdlib.h>".}

proc callClosures() {.noconv.} =
  withLock gFunsLock:
    for i in countdown(gFuns.len-1, 0):
      let fun = gFuns[i]
      case fun.kind
      of kClosure: fun.fun1()
      of kNoconv: fun.fun2()

template fun() =
  if gFuns.len == 0:
    addAtExit(callClosures)

proc addExitProc*(cl: proc () {.closure.}) =
  ## Adds/registers a quit procedure. Each call to `addExitProc` registers
  ## another quit procedure. They are executed on a last-in, first-out basis.
  # Support for `addExitProc` is done by Ansi C's facilities here.
  # In case of an unhandled exception the exit handlers should
  # not be called explicitly! The user may decide to do this manually though.
  withLock gFunsLock:
    fun()
    gFuns.add Fun(kind: kClosure, fun1: cl)

proc addExitProc*(cl: proc() {.noconv.}) =
  ## overload for `noconv` procs.
  withLock gFunsLock:
    fun()
    gFuns.add Fun(kind: kNoconv, fun2: cl)

when not defined(nimscript):
  proc getProgramResult*(): int =
    when defined(js) and defined(nodejs):
      asm """
`result` = process.exitCode;
"""
    elif not defined(js):
      result = programResult
    else:
      doAssert false

  proc setProgramResult*(a: int) =
    # pending https://github.com/nim-lang/Nim/issues/14674
    when defined(js) and defined(nodejs):
      asm """
process.exitCode = `a`;
"""
    elif not defined(js):
      programResult = a
    else:
      doAssert false
