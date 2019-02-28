discard """
  output: '''
B
B
ABCDC
foo
first0second32third64
my value A1my value Bconc2valueCabc4abc
my value A0my value Bconc1valueCabc3valueC
'''
"""


import macros

block tenum1:
  type E = enum a, b, c, x, y, z
  var en: E
  en = a

  # Bug #4066
  macro genEnum(): untyped = newNimNode(nnkEnumTy).add(newEmptyNode(), newIdentNode("geItem1"))
  type GeneratedEnum = genEnum()
  doAssert(type(geItem1) is GeneratedEnum)



block tenum2:
  type
    TEnumHole = enum
      eA = 0,
      eB = 4,
      eC = 5

  var
    e: TEnumHole = eB

  case e
  of eA: echo "A"
  of eB: echo "B"
  of eC: echo "C"



block tenum3:
  type
    TEnumHole {.size: sizeof(int).} = enum
      eA = 0,
      eB = 4,
      eC = 5

  var
    e: TEnumHole = eB

  case e
  of eA: echo "A"
  of eB: echo "B"
  of eC: echo "C"



block tbasic:
  type
    MyEnum = enum
      A,B,C,D
  # trick the optimizer with an seq:
  var x = @[A,B,C,D]
  echo x[0],x[1],x[2],x[3],MyEnum(2)



block talias:
  # bug #5148
  type
    A = enum foo, bar
    B = A

  echo B.foo



block thole:
  type Holed = enum
    hFirst = (0,"first")
    hSecond = (32,"second")
    hThird = (64,"third")
    
  var x = @[0,32,64] # This is just to avoid the compiler inlining the value of the enum

  echo Holed(x[0]),ord Holed(x[0]),Holed(x[1]),ord Holed(x[1]),Holed(x[2]),ord Holed(x[2])



block toffset:
  const
    strValB = "my value B"

  type
    TMyEnum = enum
      valueA = (1, "my value A"),
      valueB = strValB & "conc",
      valueC,
      valueD = (4, "abc")

  proc getValue(i:int): TMyEnum = TMyEnum(i)

  # trick the optimizer with a variable:
  var x = getValue(4)
  echo getValue(1), ord(valueA), getValue(2), ord(valueB), getValue(3), getValue(4), ord(valueD), x



block tnamedfields:
  const strValB = "my value B"

  type
    TMyEnum = enum
      valueA = (0, "my value A"),
      valueB = strValB & "conc",
      valueC,
      valueD = (3, "abc"),
      valueE = 4

  # trick the optimizer with a variable:
  var x = valueD
  echo valueA, ord(valueA), valueB, ord(valueB), valueC, valueD, ord(valueD), x



block toptions:
  type
    # please make sure we have under 32 options (improves code efficiency!)
    TOption = enum
      optNone, optForceFullMake, optBoehmGC, optRefcGC, optRangeCheck,
      optBoundsCheck, optOverflowCheck, optNilCheck, optAssert, optLineDir,
      optWarns, optHints, optListCmd, optCompileOnly,
      optSafeCode,             # only allow safe code
      optStyleCheck, optOptimizeSpeed, optOptimizeSize, optGenDynLib,
      optGenGuiApp, optStackTrace

    TOptionset = set[TOption]

  var
    gOptions: TOptionset = {optRefcGC, optRangeCheck, optBoundsCheck,
      optOverflowCheck, optAssert, optWarns, optHints, optLineDir, optStackTrace}
    compilerArgs: int
    gExitcode: int8



block nonzero: # bug #6959
  type SomeEnum = enum
    A = 10
    B
    C
  let slice = SomeEnum.low..SomeEnum.high
