discard """
  matrix: "--threads:on"
"""

import std/sharedlist

block:
  var
    list: SharedList[int]
    count: int

  init(list)

  for i in 1 .. 250:
    list.add i

  for i in list:
    inc count

  doAssert count == 250

  deinitSharedList(list)


block: # bug #17696
  var keysList = SharedList[string]()
  init(keysList)

  keysList.add("a")
  keysList.add("b")
  keysList.add("c")
  keysList.add("d")
  keysList.add("e")
  keysList.add("f")


  # Remove element "b" and "d" from the list. 
  keysList.iterAndMutate(proc (key: string): bool =
    if key == "b" or key == "d": # remove only "b" and "d"
      return true
    return false
  )

  var results: seq[string]
  for key in keysList.items:
    results.add key

  doAssert results == @["a", "f", "c", "e"]
