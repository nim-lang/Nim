discard """
  output: '''abcd
@["hello world"]'''
"""

# bug #12738, #12739: a `varargs` argument of a macro used in its output
import macros

macro command*(cmds: varargs[string], body: untyped): untyped =
  var usage = newSeq[string]()
  if body[0].kind == nnkAsgn:
    let text = body[0][1]
    if text.kind == nnkStrLit:
      usage.add text.strVal
  result = quote do:
    echo `cmds`
    echo `usage`

command "a", "b", "c", "d":
  usage = "hello world"
