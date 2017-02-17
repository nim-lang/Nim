discard """
  output: '''[0.0, 0.0, 0.0]

[0.0, 0.0, 0.0, 0.0]

5050'''
"""

template mathPerComponent(op: untyped): untyped =
  proc op*[N,T](v,u: array[N,T]): array[N,T] {.inline.} =
    for i in 0 ..< len(result):
      result[i] = `*`(v[i], u[i])

mathPerComponent(`***`)
# bug #5285
when true:
  if isMainModule:
    var v1: array[3, float64]
    var v2: array[3, float64]
    echo repr(v1 *** v2)


proc foo(): void =
  var v1: array[4, float64]
  var v2: array[4, float64]
  echo repr(v1 *** v2)

foo()

# bug #5383
import sequtils

proc zipWithIndex[A](ts: seq[A]): seq[(int, A)] =
  toSeq(pairs(ts))

proc main =
  discard zipWithIndex(@["foo", "bar"])
  discard zipWithIndex(@[1, 2])
  discard zipWithIndex(@[true, false])

main()

# bug #5405

proc main2() =
  let s = toSeq(1..100).foldL(a + b)
  echo s

main2()
