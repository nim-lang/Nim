discard """
  output: '''success'''
"""

# bug #3804

#import sequtils

type AnObj = ref object
  field: string

#proc aBug(objs: seq[AnObj]) {.compileTime.} =
#  discard objs.mapIt(it.field & " bug")

proc sameBug(objs: seq[AnObj]) {.compileTime.} =
  var strSeq = newSeq[string](objs.len)
  strSeq[0] = objs[0].field & " bug"

static:
  var objs: seq[AnObj] = @[]
  objs.add(AnObj(field: "hello"))

  sameBug(objs)
  # sameBug(objs)
  echo objs[0].field
  doAssert(objs[0].field == "hello") # fails, because (objs[0].field == "hello bug") - mutated!

echo "success"
