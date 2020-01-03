import ./mpragma_export

{.pragma: myfoo, exportc.}

proc fun1() {.myfoo.} = echo "ok1"
proc fun2() {.myfoo2.} = echo "ok2"
proc fun3(): int {.myfoo3.} = 123
proc fun4(): int {.myfoo4.} =
  echo "in fun4"
  124
proc fun5(): int {.myfoo5.} =
  echo "in fun5"
  125
proc fun6(): int {.myfoo6.} =
  echo "in fun6"
  125

fun1()
fun2()
fun3()
doAssert fun3()  == 123
fun4()
doAssert fun5() == 125
fun6()
