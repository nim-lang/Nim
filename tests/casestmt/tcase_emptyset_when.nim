discard """
  file: "tcaseofwhen.nim"
  outputsub: "compiles for 1\ni am always two\ndefault for 3\nset is 4 not 5\narray is 6 not 7\ndefault for 8"
  exitcode: "0"
"""

proc whenCase(a: int) =
  case a
  of (when compiles(whenCase(1)): 1 else: {}): echo "compiles for 1"
  of {}: echo "me not fail"
  of 2: echo "i am always two"
  of []: echo "me neither"
  of {4,5}: echo "set is 4 not 5"
  of [6,7]: echo "array is 6 not 7"
  of (when compiles(neverCompilesIBet()): 3 else: {}): echo "compiles for 3"
  #of {},[]: echo "me neither"
  else: echo "default for ", a

whenCase(1)
whenCase(2)
whenCase(3)
whenCase(4)
whenCase(6)
whenCase(8)
