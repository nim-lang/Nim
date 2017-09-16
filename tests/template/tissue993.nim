
type PNode* = ref object of RootObj

template litNode(name, ty)  =
  type name* = ref object of PNode
    val*: ty
litNode PIntNode, int

import json

template withKey*(j: JsonNode; key: string; varname,
                  body: untyped): typed =
  if j.hasKey(key):
    let varname{.inject.}= j[key]
    block:
      body

var j = parsejson("{\"zzz\":1}")
withkey(j, "foo", x):
  echo(x)
