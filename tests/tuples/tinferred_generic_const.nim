discard """
  action: run
"""
block:
  proc something(a: string or int or float) =
    const (c, d) = (default a.type, default a.type)

block:
  proc something(a: string or int) =
    const c = default a.type

block:
  proc something(a: string or int) =
    const (c, d, e) = (default a.type, default a.type, default a.type)
