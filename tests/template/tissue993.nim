
type pnode* = ref object of tobject

template litNode (name, ty): stmt  =
  type name* = ref object of PNode
    val*: ty
litNode PIntNode, int

import json

template withKey*(j: PJsonNode; key: string; varname: expr;
                  body:stmt): stmt {.immediate.} =
  if j.hasKey(key):
    let varname{.inject.}= j[key]
    block:
      body

var j = parsejson("{\"zzz\":1}")
withkey(j, "foo", x):
  echo(x)

