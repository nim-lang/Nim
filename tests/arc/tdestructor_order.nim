discard """
  output: '''
destroying d
destroying c
destroying a 2
destroying d
destroying c
destroying a 1
'''
joinable: false
"""

type
  Aaaa {.inheritable.} = object
    vvvv: int
  Bbbb = object of Aaaa
    c: Cccc
    d: Dddd
  Cccc = object
  Dddd = object

  Holder = object
    member: ref Aaaa

proc `=destroy`(v: Cccc) =
  echo "destroying c"

proc `=destroy`(v: Dddd) =
  echo "destroying d"

proc `=destroy`(v: Aaaa) =
  echo "destroying a ", v.vvvv

func makeHolder(vvvv: int): ref Holder =
  (ref Holder)(member: (ref Bbbb)(vvvv: vvvv))

block:
  var v = makeHolder(1)
  var v2 = makeHolder(2)