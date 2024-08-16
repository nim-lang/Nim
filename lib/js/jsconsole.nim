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
##
## Styled Messages
## ===============
##
## CSS-styled messages in the browser are useful for debugging purposes.
## To use them, prefix the message with one or more `%c`,
## and provide the CSS style as the last argument.
## The amount of `%c`'s must match the amount of CSS-styled strings.
##
runnableExamples("-r:off"):
  console.log "%c My Debug Message", "color: red" # Notice the "%c"
  console.log "%c My Debug %c Message", "color: red", "font-size: 2em"

import std/private/since, std/private/miscdollars  # toLocation

when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

type Console* = ref object of JsRoot

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

since (1, 5):
  type InstantiationInfo = tuple[filename: string, line: int, column: int]

  func getMsg(info: InstantiationInfo; msg: string): string =
    var temp = ""
    temp.toLocation(info.filename, info.line, info.column + 1)
    result.addQuoted("[jsAssert] " & temp)
    result.add ','
    result.addQuoted(msg)

  template jsAssert*(console: Console; assertion) =
    ## JavaScript `console.assert`, for NodeJS this prints to stderr,
    ## assert failure just prints to console and do not quit the program,
    ## this is not meant to be better or even equal than normal assertions,
    ## is just for when you need faster performance *and* assertions,
    ## otherwise use the normal assertions for better user experience.
    ## https://developer.mozilla.org/en-US/docs/Web/API/Console/assert
    runnableExamples:
      console.jsAssert(42 == 42) # OK
      console.jsAssert(42 != 42) # Fail, prints "Assertion failed" and continues
      console.jsAssert('`' == '\n' and '\t' == '\0') # Message correctly formatted
      assert 42 == 42  # Normal assertions keep working

    const
      loc = instantiationInfo(fullPaths = compileOption("excessiveStackTrace"))
      msg = getMsg(loc, astToStr(assertion)).cstring
    {.line: loc.}:
      {.emit: ["console.assert(", assertion, ", ", msg, ");"].}

  func dir*(console: Console; obj: auto) {.importcpp.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/Console/dir

  func dirxml*(console: Console; obj: auto) {.importcpp.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/Console/dirxml

  func timeStamp*(console: Console; label: cstring) {.importcpp.}
    ## https://developer.mozilla.org/en-US/docs/Web/API/Console/timeStamp
    ##
    ## ..warning:: non-standard


var console* {.importc, nodecl.}: Console
