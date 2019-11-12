discard """
  output: '''Success
@["a", "b", "c"]
0'''
  cmd: '''nim c --gc:destructors $file'''
"""

import os
import math
import lists
import strutils

proc mkleak() =
  # allocate 1 MB via linked lists
  let numberOfLists = 100
  for i in countUp(1, numberOfLists):
    var leakList = initDoublyLinkedList[string]()
    let numberOfLeaks = 5000
    for j in countUp(1, numberOfLeaks):
      leakList.append(newString(200))

proc mkManyLeaks() =
  for i in 0..0:
    mkleak()
  echo "Success"

iterator foobar(c: string): seq[string] {.closure.} =
  yield @["a", "b", c]

proc tsimpleClosureIterator =
  var myc = "c"
  for it in foobar(myc):
    echo it

let startMem = getOccupiedMem()
mkManyLeaks()
tsimpleClosureIterator()
echo getOccupiedMem() - startMem
