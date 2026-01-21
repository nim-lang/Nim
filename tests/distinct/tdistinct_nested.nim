import std/typetraits

type
  MyInt = distinct int
  MyOtherInt = distinct MyInt
  MyThirdInt = distinct MyOtherInt

proc `+`(a, b: MyInt): MyInt {.borrow.}
proc `+`(a, b: MyOtherInt): MyOtherInt {.borrow.}
proc `+`(a, b: MyThirdInt): MyThirdInt {.borrow.}

let one = MyInt(1)
let two = MyInt(2)
let otherOne = MyOtherInt(one)
let otherTwo = MyOtherInt(two)
let thirdOne = MyThirdInt(otherOne)
let thirdTwo = MyThirdInt(otherTwo)

let otherSum = otherOne + otherTwo
let thirdSum = thirdOne + thirdTwo

doAssert int(MyInt(otherSum)) == 3

doAssert int(MyInt(MyOtherInt(thirdSum))) == 3

doAssert distinctBase(MyInt) is int

doAssert distinctBase(MyOtherInt) is int

doAssert distinctBase(MyOtherInt, false) is MyInt

doAssert distinctBase(MyThirdInt) is int

doAssert distinctBase(MyThirdInt, false) is MyOtherInt

doAssert distinctBase(int) is int

let explicitOther = MyOtherInt(MyInt(5))
let explicitThird = MyThirdInt(explicitOther)

doAssert int(MyInt(explicitOther)) == 5

doAssert int(MyInt(MyOtherInt(explicitThird))) == 5

static:
  doAssert not compiles((block:
    var implicitOther: MyOtherInt = MyInt(1)
    discard implicitOther
  ))

let thirdFromFloat = MyThirdInt(5.0)
let thirdFromInt = MyThirdInt(5)
let backToInt = int(MyInt(MyOtherInt(thirdFromInt)))
doAssert backToInt == 5
doAssert int(MyInt(MyOtherInt(thirdFromFloat))) == 5
doAssert MyThirdInt(1.0).MyInt.int == 1

type
  T0 = distinct float
  T1 = distinct T0
  T2 = distinct T1

proc `$`(a: T0): string {.borrow.}
proc `$`(a: T1): string {.borrow.}
proc `$`(a: T2): string {.borrow.}

doAssert $T2(3.25) == "3.25"

static:
  doAssert not compiles((block:
    type
      U0 = distinct float
      U1 = distinct U0
      U2 = distinct U1
    proc `$`(a: U0): string {.borrow.}
    proc `$`(a: U2): string {.borrow.}
    discard $U2(1.0)
  ))
