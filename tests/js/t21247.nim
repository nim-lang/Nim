import std/typetraits

type
  QueryParams* = distinct seq[(string, string)]

converter toBase*(params: var QueryParams): var seq[(string, string)] =
  params.distinctBase

proc foo(): QueryParams =
  # Issue was that the implicit converter call didn't say that it took the
  # address of the parameter it was converting. This led to the parameter not being
  # passed as a fat pointer which toBase expected
  result.add(("hello", "world"))

assert foo().distinctBase() == @[("hello", "world")]
