discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""
import tables

type MyTab[A,B] = distinct TableRef[A,B]

proc `$`[A,B](t: MyTab[A,B]): string =
  "My special table " & $TableRef[A,B](t)

proc create[A,B](): MyTab[A,B] = MyTab(newTable[A,B]())

var a = create[int,int]()
doAssert $a == "My special table {:}"
