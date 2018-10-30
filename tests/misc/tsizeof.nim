discard """
  output: "OK"
"""

type
  TMyEnum = enum
    tmOne, tmTwo, tmThree, tmFour

  TMyArray1 = array[3, uint8]
  TMyArray2 = array[1..3, int32]
  TMyArray3 = array[TMyEnum, float64]

const
  mysize1 = sizeof(TMyArray1)
  mysize2 = sizeof(TMyArray2)
  mysize3 = sizeof(TMyArray3)

assert mysize1 == 3
assert mysize2 == 12
assert mysize3 == 32

import macros, typetraits

macro testSizeAlignOf(args: varargs[untyped]): untyped =
  result = newStmtList()
  for arg in args:
    result.add quote do:
      let
        c_size = c_sizeof(`arg`)
        nim_size = sizeof(`arg`)
        c_align = c_alignof(type(`arg`))
        nim_align = alignof(`arg`)

      if nim_size != c_size or nim_align != c_align:
        var msg = strAlign(`arg`.type.name & ": ")
        if nim_size != c_size:
          msg.add  " size(got, expected):  " & $nim_size  & " != " & $c_size
        if nim_align != c_align:
          msg.add  " align(get, expected): " & $nim_align & " != " & $c_align
        echo msg


macro testOffsetOf(a,b1,b2: untyped): untyped =
  let typeName = newLit(a.repr)
  let member   = newLit(b2.repr)
  result = quote do:
    let
      c_offset   = c_offsetof(`a`,`b1`)
      nim_offset = offsetof(`a`,`b2`)
    if c_offset != nim_offset:
      echo `typeName`, ".", `member`, " offset: ", c_offset, " != ", nim_offset

template testOffsetOf(a,b: untyped): untyped =
  testOffsetOf(a,b,b)

proc strAlign(arg: string): string =
  const minLen = 22
  result = arg
  for i in 0 ..< minLen - arg.len:
    result &= ' '

macro c_offsetof(a: typed, b: untyped): int32 =
  ## Buffet proof implementation that works on actual offsetof operator
  ## in the c backend. Assuming of course this implementation is
  ## correct.
  let bliteral =
    if b.kind == nnkStrLit:
      b
    else:
      newLit(repr(b))
  result = quote do:
    var res: int32
    {.emit: [res, " = offsetof(", `a`, ", ", `bliteral`, ");"] .}
    res

macro c_sizeof(a: typed): int32 =
  ## Buffet proof implementation that works using the sizeof operator
  ## in the c backend. Assuming of course this implementation is
  ## correct.
  result = quote do:
    var res: int32
    {.emit: [res, " = sizeof(", `a`, ");"] .}
    res

macro c_alignof(arg: untyped): untyped =
  ## Buffet proof implementation that works on actual alignment
  ## behavior measured at runtime.
  let typeSym = genSym(nskType, "AlignTestType"&arg.repr)
  result = quote do:
    type
      `typeSym` = object
        causeAlign: byte
        member: `arg`
    c_offsetof(`typeSym`, member)

macro testAlign(arg:untyped):untyped =
  let prefix = newLit(arg.lineinfo & "  alignof " & arg.repr & " ")
  result = quote do:
    let cAlign = c_alignof(`arg`)
    let nimAlign = alignof(`arg`)
    if cAlign != nimAlign:
      echo `prefix`, cAlign, " != ", nimAlign

testAlign(pointer)
testAlign(int)
testAlign(uint)
testAlign(int8)
testAlign(int16)
testAlign(int32)
testAlign(int64)
testAlign(uint8)
testAlign(uint16)
testAlign(uint32)
testAlign(uint64)
testAlign(float)
testAlign(float32)
testAlign(float64)

type
  MyEnum {.pure.} = enum
    ValueA
    ValueB
    ValueC

  OtherEnum {.pure, size: 8.} = enum
    ValueA
    ValueB

  Enum1 {.pure, size: 1.} = enum
    ValueA
    ValueB

  Enum2 {.pure, size: 2.} = enum
    ValueA
    ValueB

  Enum4 {.pure, size: 4.} = enum
    ValueA
    ValueB

  Enum8 {.pure, size: 8.} = enum
    ValueA
    ValueB

testAlign(MyEnum)
testAlign(OtherEnum)
testAlign(Enum1)
testAlign(Enum2)
testAlign(Enum4)
testAlign(Enum8)


template testinstance(body: untyped): untyped =
  block:
    {.pragma: objectconfig.}
    body

  block:
    {.pragma: objectconfig, packed.}
    body

testinstance:
  type

    EnumObjectA  {.objectconfig.} = object
      a : Enum1
      b : Enum2
      c : Enum4
      d : Enum8

    EnumObjectB  {.objectconfig.} = object
      a : Enum8
      b : Enum4
      c : Enum2
      d : Enum1

    TrivialType  {.objectconfig.} = object
      x,y,z: int8

    SimpleAlignment {.objectconfig.} = object
      # behaves differently on 32bit Windows and 32bit Linux
      a,b: int8
      c: int64

    AlignAtEnd {.objectconfig.} = object
      a: int64
      b,c: int8

    SimpleBranch {.objectconfig.} = object
      case kind: MyEnum
      of MyEnum.ValueA:
        a: int16
      of MyEnum.ValueB:
        b: int32
      of MyEnum.ValueC:
        c: int64

    PaddingBeforeBranchA {.objectconfig.} = object
      cause: int8
      case kind: MyEnum
      of MyEnum.ValueA:
        a: int16
      of MyEnum.ValueB:
        b: int32
      of MyEnum.ValueC:
        c: int64

    PaddingBeforeBranchB {.objectconfig.} = object
      cause: int8
      case kind: MyEnum
      of MyEnum.ValueA:
        a: int8
      of MyEnum.ValueB:
        b: int16
      of MyEnum.ValueC:
        c: int32

    PaddingAfterBranch {.objectconfig.} = object
      case kind: MyEnum
      of MyEnum.ValueA:
        a: int8
      of MyEnum.ValueB:
        b: int16
      of MyEnum.ValueC:
        c: int32
      cause: int64

    RecursiveStuff {.objectconfig.} = object
      case kind: MyEnum    # packedOffset:    0
      of MyEnum.ValueA:    # packedOffset:
        a: int16           # packedOffset:    1
      of MyEnum.ValueB:    # packedOffset:
        b: int32           # packedOffset:    1
      of MyEnum.ValueC:    # packedOffset:
        case kind2: MyEnum # packedOffset:    1
        of MyEnum.ValueA:  # packedOffset:
          ca1: int8
          ca2: int32
        of MyEnum.ValueB:  # packedOffset:
          cb: int32        # packedOffset:    2
        of MyEnum.ValueC:  # packedOffset:
          cc: int64        # packedOffset:    2
        d1: int8
        d2: int64

    Foobar {.objectconfig.} = object
      case kind: OtherEnum
      of OtherEnum.ValueA:
        a: uint8
      of OtherEnum.ValueB:
        b: int8
      c: int8

    Bazing {.objectconfig.} = object of RootObj
      a: int64
      # TODO test on 32 bit system
      # only there the object header is smaller than the first member

    InheritanceA {.objectconfig.} = object of RootObj
      a: char

    InheritanceB {.objectconfig.} = object of InheritanceA
      b: char

    InheritanceC {.objectconfig.} = object of InheritanceB
      c: char

    #Float128Test = object
    #  a: byte
    #  b: float128

    #Bazang = object of RootObj
    #  a: float128

  const trivialSize = sizeof(TrivialType) # needs to be able to evaluate at compile time

  testAlign(SimpleAlignment)

  proc main(): void =
    var t : TrivialType
    var a : SimpleAlignment
    var b : AlignAtEnd
    var c : SimpleBranch
    var d : PaddingBeforeBranchA
    var e : PaddingBeforeBranchB
    var f : PaddingAfterBranch
    var g : RecursiveStuff
    var ro : RootObj
    var
      e1: Enum1
      e2: Enum2
      e4: Enum4
      e8: Enum8
    var
      eoa: EnumObjectA
      eob: EnumObjectB

    testSizeAlignOf(t,a,b,c,d,e,f,g,ro, e1, e2, e4, e8, eoa, eob)

    testOffsetOf(TrivialType, x)
    testOffsetOf(TrivialType, y)
    testOffsetOf(TrivialType, z)

    testOffsetOf(SimpleAlignment, a)
    testOffsetOf(SimpleAlignment, b)
    testOffsetOf(SimpleAlignment, c)
    testOffsetOf(AlignAtEnd, a)
    testOffsetOf(AlignAtEnd, b)
    testOffsetOf(AlignAtEnd, c)

    testOffsetOf(SimpleBranch, "_Ukind", a)
    testOffsetOf(SimpleBranch, "_Ukind", b)
    testOffsetOf(SimpleBranch, "_Ukind", c)

    testOffsetOf(PaddingBeforeBranchA, cause)
    testOffsetOf(PaddingBeforeBranchA, "_Ukind", a)
    testOffsetOf(PaddingBeforeBranchB, cause)
    testOffsetOf(PaddingBeforeBranchB, "_Ukind", a)

    testOffsetOf(PaddingAfterBranch, "_Ukind", a)
    testOffsetOf(PaddingAfterBranch, cause)

    testOffsetOf(Foobar, c)

    testOffsetOf(Bazing, a)

    testOffsetOf(InheritanceA, a)
    testOffsetOf(InheritanceB, b)
    testOffsetOf(InheritanceC, c)

    testOffsetOf(EnumObjectA, a)
    testOffsetOf(EnumObjectA, b)
    testOffsetOf(EnumObjectA, c)
    testOffsetOf(EnumObjectA, d)
    testOffsetOf(EnumObjectB, a)
    testOffsetOf(EnumObjectB, b)
    testOffsetOf(EnumObjectB, c)
    testOffsetOf(EnumObjectB, d)

    testOffsetOf(RecursiveStuff, kind)
    testOffsetOf(RecursiveStuff, "_Ukind.S1.a",              a)
    testOffsetOf(RecursiveStuff, "_Ukind.S2.b",              b)
    testOffsetOf(RecursiveStuff, "_Ukind.S3.kind2",          kind2)
    testOffsetOf(RecursiveStuff, "_Ukind.S3._Ukind2.S1.ca1", ca1)
    testOffsetOf(RecursiveStuff, "_Ukind.S3._Ukind2.S1.ca2", ca2)
    testOffsetOf(RecursiveStuff, "_Ukind.S3._Ukind2.S2.cb",  cb)
    testOffsetOf(RecursiveStuff, "_Ukind.S3._Ukind2.S3.cc",  cc)
    testOffsetOf(RecursiveStuff, "_Ukind.S3.d1",             d1)
    testOffsetOf(RecursiveStuff, "_Ukind.S3.d2",             d2)

  main()

{.emit: """/*TYPESECTION*/
typedef struct{
  float a; float b;
} Foo;
""".}

type
  Foo {.importc.} = object

  Bar = object
    b: byte
    foo: Foo

assert sizeof(Bar) == 12

echo "OK"
