import tables

type MyTab[A,B] = distinct TableRef[A,B]

proc `$`[A,B](t: MyTab[A,B]): string =
  "My special table " & $TableRef[A,B](t)

proc create[A,B](): MyTab[A,B] = MyTab(newTable[A,B]())

var a = create[int,int]()
doAssert $a == "My special table {:}"
