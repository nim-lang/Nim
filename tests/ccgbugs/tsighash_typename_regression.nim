discard """
output: '''
123
baz
'''
"""

# bug #5147

proc foo[T](t: T) =
  type Wrapper = object
    get: T
  let w = Wrapper(get: t)
  echo w.get

foo(123)
foo("baz")

# Empty type in template is correctly disambiguated
block:
  template foo() =
    type M = object
      discard
    var y = M()

  foo()

  type M = object
    x: int

  var x = M(x: 1)
  doAssert(x.x == 1)

block: # bug #25931
  type
    N {.importc: "const void *".} = pointer
    S = object
        f: proc (_: N) {.cdecl.}
    #var _: proc (_: pointer) {.cdecl.}
  proc d(_: proc (_: pointer) {.cdecl.}) = discard
  discard S()
  d(proc (_: pointer) {.cdecl.} = discard)

block: # bug #26311
  when (defined(gcc) or defined(clang)) and not defined(cpp):
    {.passC: "-Werror=incompatible-pointer-types".}

  type
    ConstVoidPtr {.importc: "const void *", nodecl.} = pointer
    ConstCharPtr {.importc: "const char *", nodecl.} = pointer

  proc address[T](x: var T): ptr T = addr x

  var a: ConstVoidPtr
  var b: ConstCharPtr
  doAssert address(a) == addr a
  doAssert address(b) == addr b

block: # imported cstring aliases in callback signatures
  type ConstCstring {.importc: "const char *".} = cstring
  proc setCb(cb: proc (message: ConstCstring) {.cdecl.}) = discard
  proc oldCb(message: cstring) {.cdecl.} = discard
  proc constCb(message: ConstCstring) {.cdecl.} = discard

  static:
    doAssert not compiles(setCb(oldCb))
  setCb(constCb)
