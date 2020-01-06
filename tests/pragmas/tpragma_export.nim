discard """
  output: '''
ok1
ok2
in fun4
in fun5
in fun6
'''
"""

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

when false:
  # BUG: enable this and it'll hijack `myfoo7` and fail in `fun7()`;
  # ideally, the pragma template would to locally defined symbols, instead
  # of to identifiers.
  template myfooHijacked* = {. .}

proc funHijackExample(): int {.myfoo7.} =
  126

## example showing a template pragma can use a local {.pragma.} pragma.
## Using an imported {.pragma.} pragma would require https://github.com/nim-lang/Nim/pull/13030
{.pragma: myfooLocal, discardable.}
template myfoo8* = {.myfooLocal.}
proc fun8(): int {.myfoo8.} =
  126

fun1()
fun2()
fun3()
doAssert fun3()  == 123
fun4()
doAssert fun5() == 125
fun6()
funHijackExample()
fun8()
