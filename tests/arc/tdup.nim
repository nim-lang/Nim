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

  RefCustom = object
    id: ptr int

proc inc(x: sink Ref) =
  inc x.id

proc inc(x: sink RefCustom) =
  inc x.id[]

proc `=dup`(x: var RefCustom): RefCustom =
  result.id = x.id

proc foo =
  var x = Ref(id: 8)
  inc(x)
  doAssert x.id == 9
  inc(x)
  doAssert x.id == 10
  var id = 777
  var s = RefCustom(id: addr id)
  inc s
  doAssert s.id[] == 778
  inc s
  doAssert s.id[] == 779

foo()
