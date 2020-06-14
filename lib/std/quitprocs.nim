#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  FunKind = enum kClosure, kNoconv # extend as needed
  Fun = object
    case kind: FunKind
    of kClosure: fun1: proc () {.closure.}
    of kNoconv: fun2: proc () {.noconv.}

var
  gFuns: seq[Fun]

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
  for i in countdown(gFuns.len-1, 0):
    let fun = gFuns[i]
    case fun.kind
    of kClosure: fun.fun1()
    of kNoconv: fun.fun2()

template fun() =
  if gFuns.len == 0:
    addAtExit(callClosures)

proc addQuitProc*(cl: proc () {.closure.}) =
  ## Adds/registers a quit procedure. Each call to `addQuitProc` registers
  ## another quit procedure. They are executed on a last-in, first-out basis.
  # Support for `addQuitProc` is done by Ansi C's facilities here.
  # In case of an unhandled exception the exit handlers should
  # not be called explicitly! The user may decide to do this manually though.
  fun()
  gFuns.add Fun(kind: kClosure, fun1: cl)

proc addQuitProc*(cl: proc() {.noconv.}) =
  ## overload for `noconv` procs.
  fun()
  gFuns.add Fun(kind: kNoconv, fun2: cl)
