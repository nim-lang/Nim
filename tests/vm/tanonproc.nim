discard """
  output: '''`Test`'''
"""

# bug #3561

import macros, sugar, strutils

type
  Option[T] = ref object
    case valid: bool
    of true:
      data: T
    else:
      discard

proc some[T](v: T): Option[T] = Option[T](valid: true, data: v)
proc none[T](v: T): Option[T] = Option[T](valid: false)
proc none(T: typedesc): Option[T] = Option[T](valid: false)

proc map[T,U](o: Option[T], f: T -> U): Option[U] =
  case o.valid
  of true:
    f(o.data).some
  else:
    U.none

proc notEmpty(o: Option[string]): Option[string] =
  case o.valid
  of true:
    if o.data.strip == "": string.none else: o.data.strip.some
  else:
    o

proc getOrElse[T](o: Option[T], def: T): T =
  case o.valid
  of true:
    o.data
  else:
    def

proc quoteStr(s: string): Option[string] =
  s.some.notEmpty.map(v => "`" & v & "`")

macro str(s: string): void =
  let x = s.strVal
  let y = quoteStr(x)
  let sn = newStrLitNode(y.getOrElse("NONE"))
  result = quote do:
    echo `sn`

str"Test"
