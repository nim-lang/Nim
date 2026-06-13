discard """
  errormsg: "deferred size expressions only supported for imported types"
  line: 7
"""
## Reject test: deferred size pragma requires importc/importcpp

type NonImported[T] {.size: sizeof(T).} = object
  x: int
