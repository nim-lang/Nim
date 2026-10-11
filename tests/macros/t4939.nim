discard """
  output: '''
bar 1
bar abc
'''
"""

# bug #4939: genSym'ed generic parameter used as a parameter type
import std/macros

macro foo(procs: untyped): untyped =
  result = procs[0].copyNimTree
  let n = genSym(nskGenericParam, "X")
  result[2] = newTree(nnkGenericParams, newIdentDefs(n, newEmptyNode()))
  var ps = result.params
  ps.add(newIdentDefs(newIdentNode("x"), n))
  result.params = ps
  result.body = quote do:
    echo "bar ", x

foo:
  proc bar() = discard

bar(1)
bar("abc")
