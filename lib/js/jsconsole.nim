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

{.push importcpp .}

proc log*[A](console: Console, a: A)
proc debug*[A](console: Console, a: A)
proc info*[A](console: Console, a: A)
proc error*[A](console: Console, a: A)

{.pop.}

proc log*(console: Console, a: string) = console.log(cstring(a))
proc debug*(console: Console, a: string) = console.log(cstring(a))
proc info*(console: Console, a: string) = console.log(cstring(a))
proc error*(console: Console, a: string) = console.log(cstring(a))

var console* {.importc, nodecl.}: Console