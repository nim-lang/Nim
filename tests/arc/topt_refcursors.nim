discard """
  output: ''''''
  cmd: '''nim c --gc:arc --expandArc:traverse --hint:Performance:off $file'''
  nimout: '''--expandArc: traverse

var it = root
block :tmp:
  while (
    not (it == nil)):
    echo [it.s]
    it = it.ri
var jt = root
block :tmp_1:
  while (
    not (jt == nil)):
    let ri_1 = jt.ri
    echo [jt.s]
    jt = ri_1
-- end of expandArc ------------------------'''
"""

type
  Node = ref object
    le, ri: Node
    s: string

proc traverse(root: Node) =
  var it = root
  while it != nil:
    echo it.s
    it = it.ri

  var jt = root
  while jt != nil:
    let ri = jt.ri
    echo jt.s
    jt = ri

traverse(nil)
