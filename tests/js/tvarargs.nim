discard """
  output: "Hello, world"
"""

# bug #3584

type
  ConsoleObj {.importc.} = object of RootObj
    log*: proc() {.nimcall varargs.}
  Console = ref ConsoleObj

var console* {.importc.}: Console

when true:
  console.log "Hello, world"
