

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


var counter = 0

proc myDebug[T](arg: T): void =
  counter += 1

proc testProc(): void =
  var myEnum = meTwo
  myDebug(myEnum)
  # create a string object but also make the NTI for MyEnum is generated
  var myString = $myEnum
  myDebug(myString)
  var mySet = {meOne,meThree}
  myDebug(mySet)

  # for MyOtherEnum there is no NTI. This tests the fallback for the pretty printer.
  var moEnum = moTwo
  myDebug(moEnum)
  var moSet = {moOne,moThree}
  myDebug(moSet)

  let myArray = [1,2,3,4,5]
  myDebug(myArray)
  let mySeq   = @["one","two","three"]
  myDebug(mySeq)

  var myTable = initTable[string, int]()
  myTable["one"] = 1
  myTable["two"] = 2
  myTable["three"] = 3
  myDebug(myTable)

  echo(counter)


testProc()
