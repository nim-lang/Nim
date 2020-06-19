discard """
   cmd: "nim c --gc:arc --stacktrace:off $file"
"""

var x = allocShared0(0)
var y = allocShared0(0)
doAssert x != y

x.deallocShared()
y.deallocShared()
