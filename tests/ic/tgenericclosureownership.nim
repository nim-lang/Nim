discard """
  description: "IC injects ownership hooks into nested bodies cached during generic codegen"
"""

#? metamorphic

#!FILE factory.nim
proc factory*[T](data: seq[T]): proc(): seq[T] =
  result = proc(): seq[T] =
    data

#!FILE main.nim
import factory

proc main() =
  let f = factory(@[11, 22, 33])
  for i in 0 .. 3:
    var first = f()
    first[0] = 99
    doAssert f() == @[11, 22, 33]
    echo first

main()
#!FLAGS --mm:arc
#!STEP
#!STEP

# Exercise another ownership mode and a nested named routine.
#!FILE factory.nim
proc factory*[T](data: seq[T]): proc(): seq[T] =
  proc getData(): seq[T] =
    data

  result = proc(): seq[T] =
    getData()

#!FLAGS --mm:orc
#!STEP
