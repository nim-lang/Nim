discard """
  output: '''some(str), some(5), none
some(5!)
some(10)
34'''
"""

import strutils

type Option[A] = object
  case isDefined*: bool
    of true:
      value*: A
    of false:
      nil

proc some[A](value: A): Option[A] =
  Option[A](isDefined: true, value: value)

proc none[A](): Option[A] =
  Option[A](isDefined: false)

proc `$`[A](o: Option[A]): string =
  if o.isDefined:
    "some($1)" % [$o.value]
  else:
    "none"

let x = some("str")
let y = some(5)
let z = none[int]()

echo x, ", ", y, ", ", z

proc intOrString[A : int | string](o: Option[A]): Option[A] =
  when A is int:
    some(o.value + 5)
  elif A is string:
    some(o.value & "!")
  else:
    o

#let a1 = intOrString(none[String]())
let a2 = intOrString(some("5"))
let a3 = intOrString(some(5))
#echo a1
echo a2
echo a3


# bug #10033

type
  Token = enum
    Int,
    Float

  Base = ref object of RootObj
    case token: Token
    of Int:
      bInt: int
    of Float:
      bFloat: float

  Child = ref object of Base

let c = new Child
c.token = Int
c.bInt = 34
echo c.bInt
