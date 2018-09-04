
# bug #7854

type
  Stream* = ref StreamObj
  StreamObj* = object of RootObj

  InhStream* = ref InhStreamObj
  InhStreamObj* = object of Stream
    f: string

proc newInhStream*(f: string): InhStream =
  new(result)
  result.f = f

var val: int
let str = newInhStream("input_file.json")

block:
  # works:
  proc load[T](data: var T, s: Stream) =
    discard
  load(val, str)

block:
  # works
  proc load[T](s: Stream, data: T) =
    discard
  load(str, val)

block:
  # broken
  proc load[T](s: Stream, data: var T) =
    discard
  load(str, val)

