discard """
  output: "0false"
"""

# Test multiple generic instantiation of generic proc vars:

proc threadProcWrapper[TMsg]() =
  var x: TMsg
  stdout.write($x)

#var x = threadProcWrapper[int]
#x()

#var y = threadProcWrapper[bool]
#y()

threadProcWrapper[int]()
threadProcWrapper[bool]()

