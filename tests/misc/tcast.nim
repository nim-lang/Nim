discard """
  output: '''
Hello World
Hello World'''
  joinable: false
"""
type MyProc = proc() {.cdecl.}
type MyProc2 = proc() {.nimcall.}
type MyProc3 = proc() #{.closure.} is implicit

proc testProc()  = echo "Hello World"

template reject(x) = doAssert(not compiles(x))

proc callPointer(p: pointer) =
  # can cast to proc(){.cdecl.}
  let ffunc0 = cast[MyProc](p)
  # can cast to proc(){.nimcall.}
  let ffunc1 = cast[MyProc2](p)
  # cannot cast to proc(){.closure.}
  reject: cast[MyProc3](p)

  ffunc0()
  ffunc1()

callPointer(cast[pointer](testProc))

reject: discard cast[enum](0)
proc a = echo "hi"

reject: discard cast[ptr](a)

# bug #15623
block:
  if false:
    echo cast[ptr int](nil)[]

block:
  if false:
    var x: ref int = nil
    echo cast[ptr int](x)[]

block:
  doAssert cast[int](cast[ptr int](nil)) == 0

block:
  var x: ref int = nil
  doAssert cast[int](cast[ptr int](x)) == 0

