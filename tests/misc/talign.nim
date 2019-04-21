
discard """
  targets: "c cpp"
  output: ""
"""

type
  MyImportedAlignedType {.importc: "__m128d", header: "<intrin.h>", align: 16, size: 16.} = object

  MyAlignedType {.align: 64.} = object
    x: float

  MySmallAlignmentType {.align: 2.} = object
    c: char
    x: float

  MyAlignedGenericType[T] {.align: 32.} = object
    x: T

  MyWrapper = object
    x: char
    f1: MyAlignedType
    f_imp:  MyImportedAlignedType 
    case kind: bool
     of false: f2:MyAlignedType
     of true: f3: array[3, MyAlignedType]

  MyGenWrapper[T] = object
    s: string
    f1: T
    case kind: bool
     of false: f2: T
     of true: f3: array[3, T]

static:
  echo alignof(MyAlignedGenericType)


proc sizeof_lowlevel(t: typedesc): int = 
  var a: t
  {.emit: "`result` = sizeof(`a`);".}

{.emit: """/*INCLUDESECTION*/
  #include <stdalign.h>
  """.}

proc alignof_lowlevel(t: typedesc): int = 
  var a: t
  {.emit: "`result` = alignof(`a`);".}

proc test_type(t: typedesc) = 
  const 
    s1 = sizeof(t)
    a1 = alignof(t)

  proc test_val(a: t): t = 
    result = a
    
  discard test_val(t())
  #echo s1, " ", a1, " --- ", sizeof_lowlevel(t), " ",  alignof_lowlevel(t)
  doAssert: s1 == sizeof_lowlevel(t)
  doAssert: a1 == alignof_lowlevel(t)


test_type(MyImportedAlignedType)
test_type(MyAlignedType)
test_type(MySmallAlignmentType)

test_type(MyWrapper)
test_type(MyAlignedGenericType[int32])
test_type(MyAlignedGenericType[float])
test_type(MyAlignedGenericType[MyImportedAlignedType])
test_type(MyAlignedGenericType[MyAlignedType])
test_type(MyGenWrapper[MyAlignedGenericType[float]])
test_type(MyGenWrapper[MyAlignedType])
test_type(MyGenWrapper[MyAlignedGenericType[MyAlignedType]])