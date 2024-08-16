discard """
  output: ''''''
  cmd: '''nim c --gc:arc --expandArc:traverse --hint:Performance:off $file'''
  nimout: '''
--expandArc: traverse

var
  it_cursor
  jt
try:
  it_cursor = root
  block :tmp:
    while (
      not (it_cursor == nil)):
      echo [it_cursor.s]
      it_cursor = it_cursor.ri
  `=copy`(jt, root)
  block :tmp_1:
    while (
      not (jt == nil)):
      var ri_1
      try:
        `=copy`(ri_1, jt.ri)
        echo [jt.s]
        `=sink`(jt, ri_1)
        `=wasMoved`(ri_1)
      finally:
        `=destroy`(ri_1)
finally:
  `=destroy`(jt)
-- end of expandArc ------------------------
'''
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

# XXX: This optimization is not sound
