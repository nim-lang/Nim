
# bug #3584

type
  ConsoleObj {.importc.} = object of RootObj
    log*: proc() {.nimcall varargs.}
  Console = ref ConsoleObj

var console* {.importc nodecl.}: Console

when isMainModule:
  console.log "Hello, world"
