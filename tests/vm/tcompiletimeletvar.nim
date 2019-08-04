# discard """
#   nimout:'''
# 5
# Hello
# Hello
# 5
# 10
# '''
#   output: '''
# 10
# 12
# 5
# 10
# 10
# '''
# """

proc f():int {.compileTime.} = 10
block:
  template t(f:untyped): untyped =
    let y = f()
  doassert (not compiles(t(f())))
  const Y = f()
  echo Y

block:
  var x {.compileTime.} = f()
  doassert (not compiles(inc f()))
  static:
    inc x
  const X = x
  var y = X
  inc y
  echo y

block:
  var v {.compileTime.}: string
  template t(f: untyped): untyped=
    echo f.len
  static:
    v = "Hello"
  doassert (not compiles(t(v)))
  const V = v
  t(V)

block:
  const F = f
  echo F()

block:
  # No need for 'static' or 'const' in macros since
  # they are expanded in the vm and
  # have access to compile time bindings
  var v {.compileTime.}: string
  macro m1:untyped =
    v = "Hello"
    echo v.len
  m1
  static:
    echo v

block:
  var v {.compileTime.}: string
  static:
    v = "Hello"
  let x {.compileTime.} = v
  let y {.compileTime.} = x
  static:
    echo y

block:
  var v {.compileTime.}: string
  proc f():auto {.compileTime.} =
    v = "Hello"
    echo v.len
  static:
    f()

import macros
# compile time static parameter
block:
  proc compileTimeF():int {.compileTime.} = 10
  macro m(f:untyped):untyped =
    let x = f()
    quote:
      const Y = `x`
      Y
  proc g(i:int) =
    echo i
  g(m(compileTimeF))
