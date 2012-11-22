discard """
  outputsub: "no leak: "
"""

type
  Module = object
    nodes*: seq[PNode]

  PModule = ref Module

  Node = object
    owner*: PModule
    data*: array[0..200, char] # some fat to drain memory faster

  PNode = ref Node

proc newNode(owner: PModule): PNode =
  new(result)
  result.owner = owner

proc compileModule: PModule =
  new(result)
  result.nodes = @[]
  for i in 0..100:
    result.nodes.add newNode(result)

var gModuleCache: PModule

proc loop =
  for i in 0..10000:
    gModuleCache = compileModule()
    gModuleCache = nil
    GC_fullCollect()

  if getOccupiedMem() > 300_000:
    echo "still a leak! ", getOccupiedMem()
    quit(1)
  else:
    echo "no leak: ", getOccupiedMem()

loop()

