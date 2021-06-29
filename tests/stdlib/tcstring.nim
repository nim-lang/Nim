discard """
  targets: "c cpp js"
  matrix: "--gc:refc; --gc:arc"
"""

from std/sugar import collect
from stdtest/testutils import whenRuntimeJs, whenVMorJs

template testMitems() =
  block:
    var a = "abc"
    var b = a.cstring
    let s = collect:
      for bi in mitems(b):
        if bi == 'b': bi = 'B'
        bi
    whenRuntimeJs:
      discard # xxx mitems should give CT error instead of @['\x00', '\x00', '\x00']
    do:
      doAssert s == @['a', 'B', 'c']

  block:
    var a = "abc\0def"
    var b = a.cstring
    let s = collect:
      for bi in mitems(b):
        if bi == 'b': bi = 'B'
        bi
    whenRuntimeJs:
      discard # ditto
    do:
      doAssert s == @['a', 'B', 'c']

proc mainProc() =
  testMitems()

template main() =
  block: # bug #13859
    let str = "abc".cstring
    doAssert len(str).int8 == 3
    doAssert len(str).int16 == 3
    doAssert len(str).int32 == 3
    var str2 = "cde".cstring
    doAssert len(str2).int8 == 3
    doAssert len(str2).int16 == 3
    doAssert len(str2).int32 == 3

    const str3 = "abc".cstring
    doAssert len(str3).int32 == 3
    doAssert len("abc".cstring).int16 == 3
    doAssert len("abc".cstring).float32 == 3.0

  block: # bug #17159
    block:
      var a = "abc"
      var b = a.cstring
      doAssert $(b, ) == """("abc",)"""
      let s = collect:
        for bi in b: bi
      doAssert s == @['a', 'b', 'c']

    block:
      var a = "abc\0def"
      var b = a.cstring
      let s = collect:
        for bi in b: bi
      whenRuntimeJs:
        doAssert $(b, ) == """("abc\x00def",)"""
        doAssert s == @['a', 'b', 'c', '\x00', 'd', 'e', 'f']
      do:
        doAssert $(b, ) == """("abc",)"""
        doAssert s == @['a', 'b', 'c']

  block:
    when defined(gcArc): # xxx SIGBUS
      discard
    else:
      mainProc()
    when false: # xxx bug vm: Error: unhandled exception: 'node' is not accessible using discriminant 'kind' of type 'TFullReg' [FieldDefect]
      testMitems()

  block: # bug #13321: [codegen] --gc:arc does not properly emit cstring, results in SIGSEGV
    let a = "hello".cstring
    doAssert $a == "hello"
    doAssert $a[0] == "h"
    doAssert $a[4] == "o"
    whenVMorJs: discard # xxx this should work in vm, refs https://github.com/timotheecour/Nim/issues/619
    do:
      doAssert a[a.len] == '\0'

static: main()
main()
