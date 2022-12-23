discard """
  nimout: '''
--expandArc: main

if false:
  var :tmpD
  :tmpD = newNode()
  :tmpD
  `=destroy`(:tmpD)
-- end of expandArc ------------------------
'''
  cmd: '''nim c --mm:arc --expandArc:main --expandArc:main --hints:off $file'''
"""

type Node = ref object

proc newNode(): Node {.discardable.} =
  new(result)

proc main() =
  if false:
    newNode()

main()
