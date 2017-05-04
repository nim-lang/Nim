
# TODO test with inheritance
# TODO test with small sized kind
# TODO test padding byes in inheritance object
# TODO test packed pragma (do a test cast that automatically tests with and without packed pragma)


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

  TrivialType = object
    x,y,z: int8

  SimpleAlignment = object
    # behaves differently on 32bit Windows and 32bit Linux
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

  InheritanceA = object of RootObj
    a: char

  InheritanceB = object of InheritanceA
    b: char

  InheritanceC = object of InheritanceB
    c: char

  #Float128Test = object
  #  a: byte
  #  b: float128

  #Bazang = object of RootObj
  #  a: float128


import macros, typetraits

proc strAlign(arg: string): string =
  const minLen = 20
  result = arg
  for i in 0 ..< minLen - arg.len:
    result &= ' '

proc intAlign(arg: int): string =
  const minLen = 4
  result = ""
  for i in 0 ..< minLen - result.len:
    result &= ' '
  result &= $arg

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

proc main(): void =
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

  echo "sizes:"

  macro testSizeAlignOf(args: varargs[untyped]): untyped =
    result = newStmtList()
    for arg in args:
      result.add quote do:
        echo `arg`.type.name.strAlign, ": ", intAlign(sizeof(`arg`)), "\t", intAlign(alignof(`arg`)), "\t", intAlign(c_sizeof(`arg`))

  testSizeAlignOf(a,b,c,d,e,f,g,ro, e1, e2, e4, e8)

  echo "alignof(a.a): ", alignof(a.a)

  echo "offsets:"

  template testOffsetOf(a,b: untyped): untyped =
    echo c_offsetof(a,b), " <--> ", offsetof(a, b)

  var h: TrivialType
  testOffsetOf(TrivialType, z)

  # SimpleAlignment
  testOffsetOf(SimpleAlignment, a)
  testOffsetOf(SimpleAlignment, b)
  testOffsetOf(SimpleAlignment, c)
  testOffsetOf(AlignAtEnd, a)
  testOffsetOf(AlignAtEnd, b)
  testOffsetOf(AlignAtEnd, c)

  echo "SimpleBranch"

  echo c_offsetof(SimpleBranch, kindU), " <--> ", offsetof(SimpleBranch, a)
  echo c_offsetof(SimpleBranch, kindU), " <--> ", offsetof(SimpleBranch, b)
  echo c_offsetof(SimpleBranch, kindU), " <--> ", offsetof(SimpleBranch, c)

  echo "PaddingBeforeBranch"

  echo c_offsetof(PaddingBeforeBranchA, cause), " <--> ", offsetof(PaddingBeforeBranchA, cause)
  echo c_offsetof(PaddingBeforeBranchA, kindU), " <--> ", offsetof(PaddingBeforeBranchA, a)
  echo c_offsetof(PaddingBeforeBranchB, cause), " <--> ", offsetof(PaddingBeforeBranchB, cause)
  echo c_offsetof(PaddingBeforeBranchB, kindU), " <--> ", offsetof(PaddingBeforeBranchB, a)

  echo "PaddingAfterBranch"

  echo c_offsetof(PaddingAfterBranch, kindU), " <--> ", offsetof(PaddingAfterBranch, a)
  echo c_offsetof(PaddingAfterBranch, cause), " <--> ", offsetof(PaddingAfterBranch, cause)

  echo "Foobar"

  echo c_offsetof(Foobar, c), " <--> ", offsetof(Foobar, c)

  echo "Bazing"

  echo c_offsetof(Bazing, a), " <--> ", offsetof(Bazing, a)

  echo "Inheritance"

  echo c_offsetof(InheritanceA, a), " <--> ", offsetof(InheritanceC, a)
  echo c_offsetof(InheritanceB, b), " <--> ", offsetof(InheritanceC, b)
  echo c_offsetof(InheritanceC, c), " <--> ", offsetof(InheritanceC, c)

main()
