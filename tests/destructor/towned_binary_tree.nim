discard """
  cmd: '''nim c -d:nimAllocStats --gc:arc $file'''
  output: '''31665
(allocCount: 33334, deallocCount: 33334)'''
"""

#  bug #11053

import random

type Node = ref object
  x, y: int32
  left, right: owned Node

proc newNode(x: int32): owned Node =
  result = Node(x: x, y: rand(high int32).int32)

proc merge(lower, greater: owned Node): owned Node =
  if lower.isNil:
    result = greater
  elif greater.isNil:
    result = lower
  elif lower.y < greater.y:
    lower.right = merge(lower.right, greater)
    result = lower
  else:
    greater.left = merge(lower, greater.left)
    result = greater

proc splitBinary(orig: owned Node, value: int32): (owned Node, owned Node) =
  if orig.isNil:
    result = (nil, nil)
  elif orig.x < value:
    let splitPair = splitBinary(orig.right, value)
    orig.right = splitPair[0]
    result = (orig, splitPair[1])
  else:
    let splitPair = splitBinary(orig.left, value)
    orig.left = splitPair[1]
    result = (splitPair[0], orig)

proc merge3(lower, equal, greater: owned Node): owned Node =
  merge(merge(lower, equal), greater)

proc split(orig: owned Node, value: int32): tuple[lower, equal, greater: owned Node] =
  let
    (lower, equalGreater) = splitBinary(orig, value)
    (equal, greater) = splitBinary(equalGreater, value + 1)
  result = (lower, equal, greater)

type Tree = object
  root: owned Node

proc hasValue(self: var Tree, x: int32): bool =
  let splited = split(move self.root, x)
  result = not splited.equal.isNil
  self.root = merge3(splited.lower, splited.equal, splited.greater)

proc insert(self: var Tree, x: int32) =
  var splited = split(move self.root, x)
  if splited.equal.isNil:
    splited.equal = newNode(x)
  self.root = merge3(splited.lower, splited.equal, splited.greater)

proc erase(self: var Tree, x: int32) =
  let splited = split(move self.root, x)
  self.root = merge(splited.lower, splited.greater)

proc main() =
  var
    tree = Tree()
    cur = 5'i32
    res = 0

  for i in 1 ..< 100000:
    let a = i mod 3
    cur = (cur * 57 + 43) mod 10007
    case a:
    of 0:
      tree.insert(cur)
    of 1:
      tree.erase(cur)
    of 2:
      if tree.hasValue(cur):
        res += 1
    else:
      discard
  echo res

dumpAllocStats:
  main()
