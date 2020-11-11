discard """
  output: '''heavy_calc_impl is called
sub_calc1_impl is called
sub_calc2_impl is called
** no changes recompute effectively
** change one input and recompute effectively
heavy_calc_impl is called
sub_calc2_impl is called'''
"""

# sample incremental

import tables
import macros

var inputs = initTable[string, float]() 
var cache = initTable[string, float]()
var dep_tree {.compileTime.} = initTable[string, string]()

macro symHash(s: typed{nkSym}): string = 
  result = newStrLitNode(symBodyHash(s))

#######################################################################################

template graph_node(key: string) {.pragma.}

proc tag(n: NimNode): NimNode = 
  ## returns graph node unique name of a function or nil if it is not a graph node
  expectKind(n, {nnkProcDef, nnkFuncDef})
  for p in n.pragma:
    if p.len > 0 and p[0] == bindSym"graph_node":
      return p[1]
  return nil 

macro graph_node_key(n: typed{nkSym}): untyped =
  result = newStrLitNode(n.symBodyHash)

macro graph_discovery(n: typed{nkSym}): untyped =
  # discovers graph dependency tree and updated dep_tree global var
  let mytag = newStrLitNode(n.symBodyHash)
  var visited: seq[NimNode]
  proc discover(n: NimNode) = 
    case n.kind:
      of nnkNone..pred(nnkSym), succ(nnkSym)..nnkNilLit: discard
      of nnkSym:
        if n.symKind in {nskFunc, nskProc}:
          if n notin visited:
            visited.add n
            let tag = n.getImpl.tag
            if tag != nil:
              dep_tree[tag.strVal] =  mytag.strVal
            else:
              discover(n.getImpl.body)
      else:
        for child in n:
          discover(child)
  discover(n.getImpl.body)
  result = newEmptyNode()

#######################################################################################

macro incremental_input(key: static[string], n: untyped{nkFuncDef}): untyped =
  # mark leaf nodes of the graph
  template getInput(key) {.dirty.} =
    {.noSideEffect.}:
      inputs[key]
  result = n
  result.pragma = nnkPragma.newTree(nnkCall.newTree(bindSym"graph_node", newStrLitNode(key)))
  result.body = getAst(getInput(key))

macro incremental(n: untyped{nkFuncDef}): untyped =
  ## incrementalize side effect free computation
  ## wraps function into caching layer, mark caching function as a graph_node
  ## injects dependency discovery between graph nodes
  template cache_func_body(func_name, func_name_str, func_call) {.dirty.} =
    {.noSideEffect.}: 
      graph_discovery(func_name)
      let key = graph_node_key(func_name)
      if key in cache:
        result = cache[key]
      else:
        echo func_name_str & " is called"
        result = func_call
        cache[key] = result

  let func_name = n.name.strVal & "_impl"
  let func_call = nnkCall.newTree(ident func_name)
  for i in 1..<n.params.len:
    func_call.add n.params[i][0]
  let cache_func = n.copyNimTree
  cache_func.body = getAst(cache_func_body(ident func_name, func_name, func_call))
  cache_func.pragma = nnkPragma.newTree(newCall(bindSym"graph_node", 
    newCall(bindSym"symHash", ident func_name)))
  
  n.name = ident(func_name)
  result = nnkStmtList.newTree(n, cache_func)

###########################################################################
### Example
###########################################################################

func input1(): float {.incremental_input("a1").}

func input2(): float {.incremental_input("a2").}

func sub_calc1(a: float): float  {.incremental.} = 
  a + input1()

func sub_calc2(b: float): float  {.incremental.} = 
  b + input2()

func heavy_calc(a: float, b: float): float {.incremental.} = 
  sub_calc1(a) + sub_calc2(b)

###########################################################################
## graph finalize and inputs
###########################################################################

macro finalize_dep_tree(): untyped = 
  result = nnkTableConstr.newNimNode
  for key, val in dep_tree:
    result.add nnkExprColonExpr.newTree(newStrLitNode key, newStrLitNode val)
  result = nnkCall.newTree(bindSym"toTable", result)

const dep_tree_final = finalize_dep_tree()

proc set_input(key: string, val: float) = 
  ## set input value
  ## all affected nodes of graph are invalidated
  inputs[key] = val
  var k = key
  while k != "":
    k = dep_tree_final.getOrDefault(k , "")
    cache.del(k)

###########################################################################
## demo
###########################################################################

set_input("a1", 5)
set_input("a2", 2)
discard heavy_calc(5.0, 10.0)

echo "** no changes recompute effectively"
discard heavy_calc(5.0, 10.0)

echo "** change one input and recompute effectively"

set_input("a2", 10)
discard heavy_calc(5.0, 10.0)
