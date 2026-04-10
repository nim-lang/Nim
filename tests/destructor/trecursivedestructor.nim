# issue #25727

type ObjWithSeq = object
  x: seq[ObjWithSeq]

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

when false:
  type ObjWithRef = object
    x: ref ObjWithRef

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
