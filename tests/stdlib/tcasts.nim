import std/[strutils]
import std/[assertions, objectdollar]

# bug #19101
type
  Small = object
    a: int

  Big = object
    a, b, c, d: int

proc main =
  var
    n = 1'i8
    f = 2.0
    s = Small(a: 1)
    b = Big(a: 12345, b: 23456, c: 34567, d: 45678)

  doAssert $cast[int](f).toBin(64) == "0100000000000000000000000000000000000000000000000000000000000000"
  f = cast[float](n)
  doAssert $cast[int](f).toBin(64) == "0000000000000000000000000000000000000000000000000000000000000001"

  doAssert $b == "(a: 12345, b: 23456, c: 34567, d: 45678)"
  b = cast[Big](s)
  doAssert $b == "(a: 1, b: 0, c: 0, d: 0)"
main()
