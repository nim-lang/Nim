

import tables

type
  MyEnum = enum
    meOne,
    meTwo,
    meThree,
    meFour,

  MyOtherEnum = enum
    moOne,
    moTwo,
    moThree,
    moFoure,
  
  MyObj = object
    a*: int
    b*: string
  
  # MyVariant = ref object
  #   id*: int
  #   case kind*: MyEnum
  #   of meOne: mInt*: int
  #   of meTwo, meThree: discard
  #   of meFour:
  #     moInt*: int
  #     babies*: seq[MyVariant]
  #   after: float

  # MyIntVariant = ref object
  #   stuff*: int
  #   case myKind*: range[0..32766]
  #   of 0: mFloat*: float
  #   of 2: mString*: string
  #   else: mBabies*: seq[MyIntVariant]

var counter = 0

proc myDebug[T](arg: T): void =
  counter += 1

proc testProc(): void =
  var myEnum = meTwo
  myDebug(myEnum) #1
  
  # create a string, but don't allocate it
  var myString: string
  myDebug(myString) #2

  # create a string object but also make the NTI for MyEnum is generated
  myString = $myEnum
  myDebug(myString) #3
  
  var mySet = {meOne,meThree}
  myDebug(mySet) #4

  # for MyOtherEnum there is no NTI. This tests the fallback for the pretty printer.
  var moEnum = moTwo
  myDebug(moEnum) #5

  var moSet = {moOne,moThree}
  myDebug(moSet) #6

  let myArray = [1,2,3,4,5]
  myDebug(myArray) #7

  # implicitly initialized seq test
  var mySeq: seq[string]
  myDebug(mySeq) #8

  # len not equal to capacity
  let myOtherSeq = newSeqOfCap[string](10)
  myDebug(myOtherSeq) #9

  let myOtherArray = ["one","two"]
  myDebug(myOtherArray) #10

  # numeric sec
  var mySeq3 = @[1,2,3]
  myDebug(mySeq3) #11

  # seq had to grow
  var mySeq4 = @["one","two","three"]
  myDebug(mySeq4) #12

  var myTable = initTable[int, string]()
  myTable[4] = "four"
  myTable[5] = "five"
  myTable[6] = "six"
  myDebug(myTable) #13

  var myOtherTable = {"one": 1, "two": 2, "three": 3}.toTable
  myDebug(myOtherTable) #14

  var obj = MyObj(a: 1, b: "some string")
  myDebug(obj) #15

  # var varObj = MyVariant(id: 13, kind: meFour, moInt: 94,
  #                        babies: @[MyVariant(id: 18, kind: meOne, mInt: 7, after: 1.0),
  #                                  MyVariant(id: 21, kind: meThree, after: 2.0)],
  #                        after: 3.0)
  # myDebug(varObj) #16

  # var varObjInt = MyIntVariant(stuff: 5, myKind: 2, mString: "this is my sweet string")
  # myDebug(varObjInt) #17

  echo(counter)


testProc()
