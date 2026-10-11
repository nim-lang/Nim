discard """
  output: "ok"
"""

# bug #8435: bare `seq` constraints are independent type classes
proc fun1[T1: seq, T2: seq](a1: T1, a2: T2): string =
  $typeof(a1) & " " & $typeof(a2)

doAssert fun1(@[1], @[1.0]) == "seq[int] seq[float64]"
doAssert fun1(@["a"], @[1]) == "seq[string] seq[int]"

proc fun2[T1: set, T2: set](a1: T1, a2: T2) = discard
fun2({'a'}, {1'u8})
echo "ok"
