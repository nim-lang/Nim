

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

  var tup = ("hello", 42)
  myDebug(tup) # 16

  assert counter == 16


testProc()
