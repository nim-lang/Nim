discard """
  output: '''proc
proc
proc
100.0
template
template
template
100.0
macro
macro
macro
100.0
proc
template
template
100.0
template
template
template
100.0'''
"""

import macros

type
  Foo1 = object
    v: array[10,float]
  Foo2 = object
    v: array[10,float]
  Foo3 = object
    v: array[10,float]
  Foo4 = object
    v: array[10,float]
  Foo5 = object
    v: array[10,float]
  Foos = Foo1 | Foo2 | Foo3 | Foo4 | Foo5

template `[]`(x: Foos, y: int): untyped = x.v[y]
template `[]=`(x: var Foos, y: int, z: untyped) = x.v[y] = z

# optimize indexing on expressions
macro `[]`(x: Foos{call}, y: int): untyped =
  let f = ident($x[0])
  let a = x[1]
  let b = x[2]
  result = quote do:
    `f`(`a`[`y`],`b`[`y`])

template `:=`(r: var Foos; x: SomeNumber) =
  let t = (type(r[0]))(x)
  for i in 0..<r.v.len:
    r[i] = t
template `:=`(r: var Foos; x: Foos) =
  for i in 0..<r.v.len:
    r[i] = x[i]

proc `+`(x,y: Foos): Foos =
  for i in 0..<result.v.len:
    result.v[i] = x.v[i] + y.v[i]
proc sum(x: Foos): float =
  for i in 0..<x.v.len: result += x[i]

proc `=`(r: var Foo1; x: Foo1) =
  echo "proc"
  r := x
block:
  var x,y: Foo1
  x := 1
  y := 2
  let z1 = x+y+x  # proc
  var z2 = x+y+z1  # proc
  z2 = x+y+z2  # proc
  echo z2.sum

template `=`(r: var Foo2; x: Foo2) =
  echo "template"
  r := x
block:
  var x,y: Foo2
  x := 1
  y := 2
  let z1 = x+y+x  # template
  var z2 = x+y+z1  # template
  z2 = x+y+z2  # template
  echo z2.sum

macro `=`(r: var Foo3; x: Foo3): untyped =
  result = quote do:
    echo "macro"
    `r` := `x`
block:
  var x,y: Foo3
  x := 1
  y := 2
  let z1 = x+y+x  # macro
  var z2 = x+y+z1  # macro
  z2 = x+y+z2  # macro
  echo z2.sum

proc `=`(r: var Foo4; x: Foo4) =
  echo "proc"
  r := x
template optAssign{`=`(r,x)}(r: Foo4{`var`}, x: Foo4) =
  echo "template"
  r := x
block:
  var x,y: Foo4
  x := 1
  y := 2
  let z1 = x+y+x  # proc
  var z2 = x+y+z1  # template
  z2 = x+y+z2  # template
  echo z2.sum

proc `=`(r: var Foo5; x: Foo5) =
  echo "proc"
  r := x
template optAssign{`=`(r,x)}(r: Foo5, x: Foo5) =
  echo "template"
  var t = unsafeAddr(r)
  t[] := x
block:
  var x,y: Foo5
  x := 1
  y := 2
  let z1 = x+y+x  # template
  var z2 = x+y+z1  # template
  z2 = x+y+z2  # template
  echo z2.sum
