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

type Console* = ref object of RootObj

proc log*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/log

proc debug*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/debug

proc info*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/info

proc error*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/error

template exception*(console: Console, args: varargs[untyped]) =
  ## Alias for `console.error()`.
  error(console, args)

proc trace*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/trace

proc warn*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/warn

proc clear*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/clear

proc count*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/count

proc countReset*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/countReset

proc group*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/group

proc groupCollapsed*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Console/groupCollapsed

proc groupEnd*(console: Console) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/groupEnd

proc time*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/time

proc timeEnd*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/timeEnd

proc timeLog*(console: Console, label = "".cstring) {.importcpp.}
  ## https://developer.mozilla.org/docs/Web/API/Console/timeLog

proc table*(console: Console) {.importcpp, varargs.}
  ## https://developer.mozilla.org/docs/Web/API/Console/table

var console* {.importc, nodecl.}: Console
