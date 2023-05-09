discard """
  nimout: '''1,2
2,3
2,2
1,2
1,2
2,2
1,2
'''
  output: '''1,2
2,3
1,2
2,2
1,2
1,2
2,2
1,2
'''
  cmd: "nim c --gc:orc $file"
"""

template test =
  proc say(a, b: int) =
    echo a,",",b

  var a = 1
  say a, (a += 1; a) #1,2

  var b = 1
  say (b += 1; b), (b += 1; b) #2,3

  type C {.byRef.} = object
    i: int

  proc say(a, b: C) =
    echo a.i,",",b.i

  proc `+=`(x: var C, y: C) = x.i += y.i

  var c = C(i: 1)
  when nimvm: #XXX: This would output 2,2 in the VM, which is wrong
    discard
  else:
    say c, (c += C(i: 1); c) #1,2

  proc sayVar(a: var int, b: int) =
    echo a,",",b

  var d = 1
  sayVar d, (d += 1; d) #2,2

  var e = 1
  say (addr e)[], (e += 1; e) #1,2

  var f = 1
  say f, if false: f
         else: f += 1; f #1,2

  var g = 1
  say g + 1, if false: g
             else: g += 1; g #2,2

  proc `+=+`(x: var int, y: int): int = (inc(x, y); x)

  var h = 1
  say h, h +=+ 1 # 1,2

test

static:
  test
