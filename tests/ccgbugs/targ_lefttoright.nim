discard """
  nimout: '''1,2
2,3
2,2
'''
  output: '''1,2
2,3
1,2
2,2
'''
"""

template test =
  proc say(a, b: int) =
    echo a,",",b

  var a = 1
  say a, (a += 1; a)

  var b = 1
  say (b += 1; b), (b += 1; b)

  type C = object {.byRef.}
    i: int

  proc say(a, b: C) =
    echo a.i,",",b.i

  proc `+=`(x: var C, y: C) = x.i += y.i

  var c = C(i: 1)
  when nimvm: #XXX: This would output 2,2 in the VM, which is wrong
    discard
  else:
    say c, (c += C(i: 1); c)

  proc sayVar(a: var int, b: int) =
    echo a,",",b

  var d = 1
  sayVar d, (d += 1; d)

test

static:
  test
