
type
  MyEnum {.pure.} = enum
    ValueA
    ValueB
    ValueC

  OtherEnum {.pure, size: 8.} = enum
    ValueA
    ValueB

  SimpleAlignment = object
    a,b: int8
    c: int64

  AlignAtEnd = object
    a: int64
    b,c: int8

  SimpleBranch = object
    case kind: MyEnum
    of MyEnum.ValueA:
      a: int16
    of MyEnum.ValueB:
      b: int32
    of MyEnum.ValueC:
      c: int64

  PaddingBeforeBranchA = object
    cause: int8
    case kind: MyEnum
    of MyEnum.ValueA:
      a: int16
    of MyEnum.ValueB:
      b: int32
    of MyEnum.ValueC:
      c: int64

  PaddingBeforeBranchB = object
    cause: int8
    case kind: MyEnum
    of MyEnum.ValueA:
      a: int8
    of MyEnum.ValueB:
      b: int16
    of MyEnum.ValueC:
      c: int32


  PaddingAfterBranch = object
    case kind: MyEnum
    of MyEnum.ValueA:
      a: int8
    of MyEnum.ValueB:
      b: int16
    of MyEnum.ValueC:
      c: int32
    cause: int64

  RecursiveStuff = object
    case kind: MyEnum
    of MyEnum.ValueA:
      a: int16
    of MyEnum.ValueB:
      b: int32
    of MyEnum.ValueC:
      case kind2: MyEnum
      of MyEnum.ValueA:
        ca1, ca2: int16
      of MyEnum.ValueB:
        cb: int32
      of MyEnum.ValueC:
        cc: int64


  Foobar = object
    case kind: OtherEnum
    of OtherEnum.ValueA:
      a: uint8
    of OtherEnum.ValueB:
      b: int8
    c: int8


  Bazing = object of RootObj
    a: int64
    # TODO test on 32 bit system
    # only there the object header is smaller than the first member


import macros, typetraits

macro c_offsetof(a: typed, b: untyped): int32 =
  let bliteral = newLit(repr(b))
  result = quote do:
    var res: int32
    {.emit: [res, " = offsetof(", `a`, ", ", `bliteral`, ");"] .}
    res

proc main(): void =
  var a : SimpleAlignment
  var b : AlignAtEnd
  var c : SimpleBranch
  var d : PaddingBeforeBranchA
  var e : PaddingBeforeBranchB
  var f : PaddingAfterBranch
  var g : RecursiveStuff

  echo "sizes:"

  echo a.type.name, ":\t", sizeof(a)
  echo b.type.name, ":\t", sizeof(b)
  echo c.type.name, ":\t", sizeof(c)
  echo d.type.name, ":\t", sizeof(d)
  echo e.type.name, ":\t", sizeof(e)
  echo f.type.name, ":\t", sizeof(f)
  echo g.type.name, ":\t", sizeof(g)

  echo "offsets:"

  echo c_offsetof(SimpleAlignment, a)
  echo c_offsetof(SimpleAlignment, b)
  echo c_offsetof(SimpleAlignment, c)
  echo c_offsetof(AlignAtEnd, a)
  echo c_offsetof(AlignAtEnd, b)
  echo c_offsetof(AlignAtEnd, c)

  echo "SimpleBranch"

  echo c_offsetof(SimpleBranch, kindU)

  echo "PaddingBeforeBranch"

  echo c_offsetof(PaddingBeforeBranchA, cause)
  echo c_offsetof(PaddingBeforeBranchA, kindU)
  echo c_offsetof(PaddingBeforeBranchB, cause)
  echo c_offsetof(PaddingBeforeBranchB, kindU)

  echo "PaddingAfterBranch"

  echo c_offsetof(PaddingAfterBranch, kindU)
  echo c_offsetof(PaddingAfterBranch, cause)

  echo "Foobar"

  echo c_offsetof(Foobar, c)

  echo "Bazing"

  echo c_offsetof(Bazing, a)

main()
