discard """
  cmd: '''nim c --gc:arc --expandArc:traverse --hint:Performance:off $file'''
  nimout: '''
--expandArc: traverse

var
  it
  jt_cursor
try:
  `=copy`(it, root)
  block :tmp:
    while (
      not (it == nil)):
      if true:
        echo [it.s]
        `=copy`(it, it.ri)
  jt_cursor = root
  if (
    not (jt_cursor == nil)):
    echo [jt_cursor.s]
    jt_cursor = jt_cursor.ri
finally:
  `=destroy`(it)
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
    if true:
      echo it.s
      it = it.ri

  var jt = root
  if jt != nil:
    echo jt.s
    jt = jt.ri

traverse(nil)
