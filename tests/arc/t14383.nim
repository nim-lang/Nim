discard """
  cmd: "nim c --gc:arc $file"
  output: '''
hello
hello
@[4, 3, 2, 1]
'''
"""

import dmodule

var val = parseMinValue()
if val.kind == minDictionary:
  echo val


#------------------------------------------------------------------------------
# Issue #15035
#------------------------------------------------------------------------------

proc countRun(lst: sink openArray[int]): int =
  discard

proc timSort(lst: var openArray[int]) = 
  let run = countRun(lst)

var a = @[4, 3, 2, 1]
timSort(a)
echo a