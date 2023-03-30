discard """
  cmd: "nim c --mm:arc --expandArc:foo --hints:off $file"
  nimout: '''
--expandArc: foo

var
  x
  :tmpD
  s
  :tmpD_1
x = Ref(id: 8)
inc:
  `=dup`(:tmpD, x)
  :tmpD
inc:
  let blitTmp = x
  blitTmp
s = RefCustom(id_1: 777)
inc_1 :
  :tmpD_1 = `=dup`(s)
  :tmpD_1
inc_1 :
  let blitTmp_1 = s
  blitTmp_1
-- end of expandArc ------------------------
'''
"""

type
  Ref = ref object
    id: int

  RefCustom = ref object
    id: int

proc inc(x: sink Ref) =
  doAssert x.id == 8

proc inc(x: sink RefCustom) =
  doAssert x.id == 777

proc `=dup`(x: RefCustom): RefCustom =
  result = x

proc foo =
  var x = Ref(id: 8)
  inc(x)
  inc(x)
  var s = RefCustom(id: 777)
  inc s
  inc s

foo()