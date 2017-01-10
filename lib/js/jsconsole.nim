#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Wrapper for the `console` object for the `JavaScript backend
## <backends.html#the-javascript-target>`_.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

import macros

type Console* {.importc.} = ref object of RootObj

proc convertToConsoleLoggable*[T](v: T): RootRef {.importcpp: "#".}
template convertToConsoleLoggable*(v: string): RootRef = cast[RootRef](cstring(v))

proc logImpl(console: Console) {.importcpp: "log", varargs.}
proc debugImpl(console: Console) {.importcpp: "debug", varargs.}
proc infoImpl(console: Console) {.importcpp: "info", varargs.}
proc errorImpl(console: Console) {.importcpp: "error", varargs.}

proc makeConsoleCall(console: NimNode, procName: NimNode, args: NimNode): NimNode =
  result = newCall(procName, console)
  for c in args: result.add(c)

macro log*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "logImpl", args)

macro debug*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "debugImpl", args)

macro info*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "infoImpl", args)

macro error*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "errorImpl", args)

var console* {.importc, nodecl.}: Console