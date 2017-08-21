discard """
  output: '''
Hello World
Hello World'''
"""
type MyProc = proc() {.cdecl.}
type MyProc2 = proc() {.nimcall.}
type MyProc3 = proc() #{.closure.} is implicit

proc testProc() {.exportc:"foo".} = echo "Hello World"

proc callPointer(p: pointer) =
  # can cast to proc(){.cdecl.}
  let ffunc0 = cast[MyProc](p)
  # can cast to proc(){.nimcall.}
  let ffunc1 = cast[MyProc2](p)
  # cannot cast to proc(){.closure.}
  doAssert(not compiles(cast[MyProc3](p)))

  ffunc0()
  ffunc1()

  # test bug 5901
  proc foo() {.importc.}
  (cast[proc(a: int) {.cdecl.}](foo))(5)

callPointer(cast[pointer](testProc))
