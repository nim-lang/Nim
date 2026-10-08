import std/[macros, strutils]

let initial {.compileTime.} = newLit("init")
var registry {.compileTime.}: seq[string] = @[]
static: registry.add "own"

macro register*(name: static string): untyped =
  registry.add name
  result = newEmptyNode()

macro state*(): untyped =
  result = newLit(initial.strVal & ":" & registry.join(","))
