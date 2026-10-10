discard """
  action: compile
"""

# bug #15607; a {.varargs.} proc passed to a `varargs` parameter
import std/jsffi

proc l() {.varargs, importc: "console.log", cdecl.}

let d3 {.importc.}: JsObject

proc test() =
  discard d3.call(l)
