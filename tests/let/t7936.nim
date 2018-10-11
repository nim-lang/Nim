discard """
  action: "run"
"""

import
  tables, deques, sequtils

const
  lookupTable = {'(': ')', '{': '}', '[': ']'}.toTable

proc isPaired*(value: string): bool =
  var stack = initDeque[char]() 

  for item in value:
    # echo "Looking at " & item
    if item in lookupTable:
      stack.addLast(item)
    if item in toSeq(lookupTable.values):
      if stack.len == 0:
        return false
      if lookupTable[stack.popLast()] != item:
        return false

  return stack.len == 0

doAssert isPaired("{[()]}") == true
doAssert isPaired("a)b(c") == false
