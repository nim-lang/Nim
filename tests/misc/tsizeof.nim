discard """
  output: ""
"""

# TODO test with inheritance
# TODO test with small sized kind
# TODO test padding byes in inheritance object
# TODO test packed pragma (do a test cast that automatically tests with and without packed pragma)
# TODO automatically test with packed and unpacked

import macros, typetraits


macro testSizeAlignOf(args: varargs[untyped]): untyped =
  result = newStmtList()
  for arg in args:
    result.add(quote do:
      let
        c_size = c_sizeof(`arg`)
        nim_size = sizeof(`arg`)
      if nim_size != c_size:
        echo strAlign(`arg`.type.name & ": "), " size: ",
             intAlign(c_size),   " !=  ",
             intAlign(nim_size), " align: ",
             intAlign(alignof(`arg`))
    )

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

proc intAlign(arg: int): string =
  const minLen = 4
  result = $arg
  while result.len < minLen:
    result.insert(" ")

macro c_offsetof(a: typed, b: untyped): int32 =
  let bliteral = newLit(repr(b))
  result = quote do:
    var res: int32
    {.emit: [res, " = offsetof(", `a`, ", ", `bliteral`, ");"] .}
    res

macro c_sizeof(a: typed): int32 =
  result = quote do:
    var res: int32
    {.emit: [res, " = sizeof(", `a`, ");"] .}
    res

when false:
  {.pragma: objectconfig.}
else:
  {.pragma: objectconfig, packed.}

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

  testOffsetOf(SimpleBranch, kindU, a)
  testOffsetOf(SimpleBranch, kindU, b)
  testOffsetOf(SimpleBranch, kindU, c)

  testOffsetOf(PaddingBeforeBranchA, cause)
  testOffsetOf(PaddingBeforeBranchA, kindU, a)
  testOffsetOf(PaddingBeforeBranchB, cause)
  testOffsetOf(PaddingBeforeBranchB, kindU, a)

  testOffsetOf(PaddingAfterBranch, kindU, a)
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
  testOffsetOf(RecursiveStuff, kindU.S1.a,             a)
  testOffsetOf(RecursiveStuff, kindU.S2.b,             b)
  testOffsetOf(RecursiveStuff, kindU.S3.kind2,         kind2)
  testOffsetOf(RecursiveStuff, kindU.S3.kind2U.S1.ca1, ca1)
  testOffsetOf(RecursiveStuff, kindU.S3.kind2U.S1.ca2, ca2)
  testOffsetOf(RecursiveStuff, kindU.S3.kind2U.S2.cb,  cb)
  testOffsetOf(RecursiveStuff, kindU.S3.kind2U.S3.cc,  cc)
  testOffsetOf(RecursiveStuff, kindU.S3.d1,            d1)
  testOffsetOf(RecursiveStuff, kindU.S3.d2,            d2)


main()
