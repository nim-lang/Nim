discard """
  cmd: "nim c --gc:arc $file"
"""

type MyObj = ref object

var o = MyObj()
proc x: var MyObj = o

var o2 = x()
