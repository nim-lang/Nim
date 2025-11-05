discard """
  nimout: '''1
2
3: Protocol[system.int, system.int]
4'''
"""
import std/typetraits

type
  AsCompleteFullWriter*[T] = distinct T
  Protocol*[R; W] = object

template write*[T](
    writer: AsCompleteFullWriter[T]; data: pointer; length: int
): int =
  static:
    echo "3: ", $T
  fwrite(distinctBase writer, data, length)

proc write(w: var auto, c: char): int =
  static:
    echo "2"
  var a = default(array[1, byte])
  write(w, addr a[0], 1)

proc fwrite*[R;I; T](writer: var Protocol[R,I]; v: T): int {.discardable.} =
  static:
    echo "1"
  write(AsCompleteFullWriter[Protocol[R,I]](writer), v)

proc fwrite*[R;W](tp: var Protocol[R,W]; p: pointer; length: int): int =
  static:
    echo "4"
  result = 0

proc main(arg: var Protocol[int, int]) =
  discard arg.fwrite('c')

var p = Protocol[int, int]()
main p