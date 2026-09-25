import std/macros, std/macrocache

const procs* = CacheTable"mmacrocacheproc.procs"

macro remember*(p: untyped) =
  ## Stores the untyped routine AST (its exported name is an `nkPostfix`).
  procs[p[0][1].strVal] = p.copy()
  result = p

proc hello*(): int {.remember.} = 42
