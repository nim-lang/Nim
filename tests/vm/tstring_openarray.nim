
# tests various bug when passing string to openArray argument in VM.
# bug #6086
proc map*[T, S](data: openArray[T], op: proc (x: T): S {.closure.}):
                                                            seq[S]{.inline.} =
# map inlined from sequtils
  newSeq(result, data.len)
  for i in 0..data.len-1: result[i] = op(data[i])


proc set_all[T](s: var openArray[T]; val: T) =
  for i in 0..<s.len:
    s[i] = val

proc main() =
  var a0 = "hello_world"
  var a1 = [1,2,3,4,5,6,7,8,9]
  var a2 = @[1,2,3,4,5,6,7,8,9]
  a0.set_all('i')
  a1.set_all(4)
  a2.set_all(4)
  doAssert a0 == "iiiiiiiiiii"
  doAssert a1 == [4,4,4,4,4,4,4,4,4]
  doAssert a2 == @[4,4,4,4,4,4,4,4,4]

const constval0 = "hello".map(proc(x: char): char = x)
const constval1 = [1,2,3,4].map(proc(x: int): int = x)

doAssert("hello".map(proc(x: char): char = x) == constval0)
doAssert([1,2,3,4].map(proc(x: int): int = x) == constval1)

static: main()
main()
