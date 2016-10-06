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

type Console* {.importc.} = ref object of RootObj

proc convertToConsoleLoggable*[T](v: T): RootRef {.importcpp: "#".}
template convertToConsoleLoggable*(v: string): RootRef = cast[RootRef](cstring(v))

proc log*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]) {.importcpp: "#.log.apply(null, #)".}
proc debug*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]) {.importcpp: "#.debug.apply(null, #)".}
proc info*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]) {.importcpp: "#.info.apply(null, #)".}
proc error*(console: Console, args: varargs[RootRef, convertToConsoleLoggable]) {.importcpp: "#.error.apply(null, #)".}

var console* {.importc, nodecl.}: Console