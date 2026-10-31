discard """
output: '''
-128 .. 127
-32768 .. 32767
-2147483648 .. 2147483647
-9223372036854775808 .. 9223372036854775807
'''
"""

# bug #22806

proc printRange[T: Ordinal]()

proc printIntRanges() =
  printRange[int8]()
  printRange[int16]()
  printRange[int32]()
  printRange[int64]()

proc printRange[T: Ordinal]() =
  echo low(T) .. high(T)

printIntRanges()
