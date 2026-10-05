discard """
  description: '''IC: a routine of a `localPassC: "-mavx"` module emitted into another module's TU is compiled for the owner's target'''
"""

when defined(amd64) and (defined(gcc) or defined(clang)):
  import mlocalpasstarget

  var a: array[8, int32]
  if cpuHasAvx():
    fillAvx(a, 7'i32)
    doAssert a == [7'i32, 7, 7, 7, 7, 7, 7, 7]
