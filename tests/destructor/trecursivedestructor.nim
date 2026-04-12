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

proc `=dup`(a: ObjWithSeq): ObjWithSeq {.nodestroy.} =
  ObjWithSeq(x: a.x)

proc `=trace`(a: var ObjWithSeq, env: pointer) {.nodestroy.} =
  `=trace`(a.x, env)

proc fooSeq() =
  let a = ObjWithSeq(x: @[ObjWithSeq()])
  let b = a
  let c = a
  let d = b
fooSeq()

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

proc `=dup`(a: ObjWithRef): ObjWithRef {.nodestroy.} =
  ObjWithRef(x: a.x)

proc `=trace`(a: var ObjWithRef, env: pointer) {.nodestroy.} =
  `=trace`(a.x, env)

proc fooRef() =
  let a = ObjWithRef(x: (ref ObjWithRef)())
  let b = a
  let c = a
  let d = b
fooRef()
