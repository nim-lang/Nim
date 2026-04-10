discard """
  matrix: "--mm:refc; --mm:orc; --mm:none"
"""

# issue #25727

type ObjWithSeq = object
  x: seq[ObjWithSeq]

when not defined(gcDestructors):
  proc `=destroy`(a: var ObjWithSeq) {.nodestroy.} =
    `=destroy`(a.x)
else:
  proc `=destroy`(a: ObjWithSeq) {.nodestroy.} =
    `=destroy`(a.x)

proc `=copy`(a: var ObjWithSeq, b: ObjWithSeq) {.nodestroy.} =
  `=copy`(a.x, b.x)
  
proc `=sink`(a: var ObjWithSeq, b: ObjWithSeq) {.nodestroy.} =
  `=sink`(a.x, b.x)

proc fooSeq() =
  let a = ObjWithSeq(x: @[ObjWithSeq()])
  let b = a
  let c = a
  let d = b
fooSeq()

when true:
  type ObjWithRef = object
    x: ref ObjWithRef

  when not defined(gcDestructors):
    proc `=destroy`(a: var ObjWithRef) {.nodestroy.} =
      `=destroy`(a.x)
  else:
    proc `=destroy`(a: ObjWithRef) {.nodestroy.} =
      `=destroy`(a.x)

  proc `=copy`(a: var ObjWithRef, b: ObjWithRef) {.nodestroy.} =
    `=copy`(a.x, b.x)
    
  proc `=sink`(a: var ObjWithRef, b: ObjWithRef) {.nodestroy.} =
    `=sink`(a.x, b.x)

  proc fooRef() =
    let a = ObjWithRef(x: (ref ObjWithRef)())
    let b = a
    let c = a
    let d = b
  fooRef()
