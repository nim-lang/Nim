discard """
  output: '''some(str), some(5), none
some(5!)
some(10)'''
"""

import strutils

type Option[A] = object
  case isDefined*: Bool
    of true:
      value*: A
    of false:
      nil

proc some[A](value: A): Option[A] =
  Option[A](isDefined: true, value: value)

proc none[A](): Option[A] =
  Option[A](isDefined: false)

proc `$`[A](o: Option[A]): String =
  if o.isDefined:
    "some($1)" % [$o.value]
  else:
    "none"

let x = some("str")
let y = some(5)
let z = none[Int]()

echo x, ", ", y, ", ", z

proc intOrString[A : Int | String](o: Option[A]): Option[A] =
  when A is Int:
    some(o.value + 5)
  elif A is String:
    some(o.value & "!")
  else:
    o

#let a1 = intOrString(none[String]())
let a2 = intOrString(some("5"))
let a3 = intOrString(some(5))
#echo a1
echo a2
echo a3
