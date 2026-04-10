# issue #25727

type ObjWithSeq = object
  x: seq[ObjWithSeq]

proc `=destroy`(a: ObjWithSeq) {.nodestroy.} =
  `=destroy`(a.x)

proc `=copy`(a: var ObjWithSeq, b: ObjWithSeq) {.nodestroy.} =
  `=copy`(a.x, b.x)
  
proc `=sink`(a: var ObjWithSeq, b: ObjWithSeq) {.nodestroy.} =
  `=sink`(a.x, b.x)

proc foo() =
  let a = ObjWithSeq(x: @[ObjWithSeq()])
  let b = a
  let c = a
  let d = b
foo()
