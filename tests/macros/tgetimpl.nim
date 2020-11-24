discard """
  nimout: '''"muhaha"
proc poo(x, y: int) =
  let y = x
  echo ["poo"]'''
"""

import macros

const
  foo = "muhaha"

proc poo(x, y: int) =
  let y = x
  echo "poo"

macro m(x: typed): untyped =
  echo repr x.getImpl

m(foo)
m(poo)

#------------

macro checkOwner(x: typed, check_id: static[int]): untyped =
  let sym = case check_id:
    of 0: x
    of 1: x.getImpl.body[0][0][0]
    of 2: x.getImpl.body[0][0][^1]
    of 3: x.getImpl.body[1][0]
    else: x
  result = newStrLitNode($sym.owner.symKind)

macro isSameOwner(x, y: typed): untyped =
  result =
    if x.owner == y.owner: bindSym"true"
    else: bindSym"false"


static:
  doAssert checkOwner(foo, 0) == "nskModule"
  doAssert checkOwner(poo, 0) == "nskModule"
  doAssert checkOwner(poo, 1) == "nskProc"
  doAssert checkOwner(poo, 2) == "nskProc"
  doAssert checkOwner(poo, 3) == "nskModule"
  doAssert isSameOwner(foo, poo)
  doAssert isSameOwner(foo, echo) == false
  doAssert isSameOwner(poo, len) == false

#---------------------------------------------------------------

macro check_gen_proc(ex: typed): (bool, bool) =
  let lenChoice = bindsym"len"
  var is_equal = false 
  var is_instance_of = false 
  for child in lenChoice:
    if not is_equal:
      is_equal = ex[0] == child
    if not is_instance_of:
      is_instance_of = isInstantiationOf(ex[0], child)
         
  result = nnkTupleConstr.newTree(newLit(is_equal), newLit(is_instance_of))

# check that len(seq[int]) is not equal to bindSym"len", but is instance of it
let a = @[1,2,3]
assert: check_gen_proc(len(a)) == (false, true)

