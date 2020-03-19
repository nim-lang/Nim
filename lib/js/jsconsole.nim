#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Wrapper for the `console` object for the `JavaScript backend
## <backends.html#backends-the-javascript-target>`_.

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
proc warnImpl(console: Console) {.importcpp: "warn", varargs.}
proc traceImpl(console: Console) {.importcpp: "trace", varargs.}

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

macro exception*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "errorImpl", args)

macro trace*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "traceImpl", args)

macro warn*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]): untyped =
  makeConsoleCall(console, bindSym "warnImpl", args)

proc clear*(console: Console) {.importcpp: "clear".}

proc count*(console: Console, label = "".cstring) {.importcpp: "count".}

proc countReset*(console: Console, label = "".cstring) {.importcpp: "countReset".}

proc group*(console: Console, label = "".cstring) {.importcpp: "group".}

proc groupCollapsed*(console: Console, label = "".cstring) {.importcpp: "groupCollapsed".}

proc groupEnd*(console: Console) {.importcpp: "groupEnd".}

proc time*(console: Console, label = "".cstring) {.importcpp: "time".}

proc timeEnd*(console: Console, label = "".cstring) {.importcpp: "timeEnd".}

proc timeLog*(console: Console, label = "".cstring) {.importcpp: "timeLog".}

proc table*(console: Console, data: seq[cstring|bool|SomeNumber]) {.importcpp: "table".}


var console* {.importc, nodecl.}: Console
