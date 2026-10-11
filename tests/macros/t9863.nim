# bug #9863: a `static seq` param with an empty default value
import std/macros

macro foo(a: static seq[string] = @[]): untyped =
  newLit(a.len)

proc main() =
  doAssert foo() == 0
  doAssert foo(@["a", "b"]) == 2

main()
