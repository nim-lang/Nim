# issue #10900

import std/options

type
  AllTypesInModule =
    bool | string | seq[int]

converter toOptional[T: AllTypesInModule](x: T): Option[T] =
  some(x)

proc foo(
    a: Option[bool] = none[bool](),
    b: Option[string] = none[string](),
    c: Option[seq[int]] = none[seq[int]]()) =
  discard

# works:
foo(a = true)
foo(true)
foo(b = "asdf")
foo(c = @[1, 2, 3])

# fails:
foo(
  a = true,
  b = "asdf")
foo(true, "asdf")
foo(
  a = true,
  c = @[1, 2, 3])
foo(
  b = "asdf",
  c = @[1, 2, 3])
foo(
  a = true,
  b = "asdf",
  c = @[1, 2, 3])
