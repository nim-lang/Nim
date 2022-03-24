template tests =
  block:
    var i = 0
    i = 2

    var y: ptr int
    doAssert y == nil
    doAssert isNil(y)
    y = i.addr
    y[] = 3
    doAssert i == 3
    doAssert i == y[]

    let z = i.addr
    z[] = 4
    doAssert i == 4
    doAssert i == y[] and y[] == z[]

    var hmm = (a: (b: z))
    var hmmptr = hmm.a.b.addr
    hmmptr[][] = 5

    doAssert i == 5
    doAssert y == z
    doAssert z == hmmptr[]
    doAssert 5 == y[] and 5 == z[] and 5 == hmmptr[][]

  block:
    var someint = 500

    let p: ptr int = someint.addr
    let tup = (f: p)
    let tcopy = tup
    var vtcopy = tcopy
    p[] = 654
    doAssert p[] == 654
    doAssert tup.f[] == 654
    doAssert tcopy.f[] == 654
    doAssert vtcopy.f[] == 654

  block:
    var someint = 500

    var p: ptr int = someint.addr
    let arr = [p]
    let arrc = arr
    p[] = 256
    doAssert someint == 256
    doAssert p[] == 256
    doAssert arr[0][] == 256
    doAssert arrc[0][] == 256

  block:
    var someref: ref int
    new(someref)
    var someref2 = someref

    var tup1 = (f: someref)
    tup1.f = someref
    let tup2 = tup1

    someref[] = 543

    proc passref(r: var ref int): var ref int = r
    new(passref(someref))

    doAssert someref[] == 0
    doAssert tup1.f[] == 543
    doAssert tup2.f[] == 543
    doAssert someref2[] == 543

  block:
    type Whatever = object
      i: ref int

    var someref: ref int
    new(someref)
    someref[] = 10

    let w = Whatever(i: someref)
    var wcopy = w

    someref[] = 20

    doAssert w.i[] == 20
    doAssert someref[] == 20
    doAssert wcopy.i[] == 20
    doAssert w.i == wcopy.i
    #echo w.i[], " ", someref[], " ", wcopy.i[]

  block:
    var oneseq: ref seq[ref int]
    new(oneseq)
    var aref: ref int
    new(aref)
    aref[] = 123
    let arefs = [aref]
    oneseq[] &= arefs[0]
    oneseq[] &= aref
    aref[] = 222
    new(aref)
    doAssert oneseq[0] == oneseq[1]
    doAssert oneseq[0][] == 222
    doAssert oneseq[1][] == 222
    doAssert aref[] == 0

  block:
    var seqs: ref seq[ref seq[ref int]]
    new(seqs)
    seqs[] = newSeq[ref seq[ref int]](1)
    new(seqs[0])
    seqs[0][] = newSeq[ref int](0)

    var aref: ref int
    new aref
    aref[] = 654

    let arefs = [aref]
    doAssert arefs[0] == aref
    seqs[0][] &= arefs[0]
    seqs[0][] &= aref
    seqs[0][1][] = 456
    let seqs2 = seqs
    let same = seqs2[0][0] == seqs2[0][1]
    doAssert arefs[0] == aref
    doAssert aref[] == 456
    doAssert seqs[].len == 1
    doAssert seqs[0][].len == 2
    doAssert seqs[0][0][] == 456
    doAssert seqs[0][1][] == 456
    doAssert same

  block:
    type Obj = object
      x, y: int

    var objrefs: seq[ref Obj] = @[(ref Obj)(nil), nil, nil]
    objrefs[2].new
    objrefs[2][] = Obj(x: 123, y: 321)
    objrefs[1] = objrefs[2]
    doAssert objrefs[0] == nil
    doAssert objrefs[1].y == 321
    doAssert objrefs[2].y == 321
    doAssert objrefs[1] == objrefs[2]

  block:
    var refs: seq[ref string] = @[(ref string)(nil), nil, nil]
    refs[1].new
    refs[1][] = "it's a ref!"
    refs[0] = refs[1]
    refs[2] = refs[1]
    new(refs[0])
    doAssert refs[0][] == ""
    doAssert refs[1][] == "it's a ref!"
    doAssert refs[2][] == "it's a ref!"
    doAssert refs[1] == refs[2]

  block:
    var retaddr_calls = 0
    proc retaddr(p: var int): var int =
      retaddr_calls += 1
      p

    var tfoo_calls = 0
    proc tfoo(x: var int) =
      tfoo_calls += 1
      x += 10
      var y = x.addr
      y[] += 20
      retaddr(x) += 30
      let z = retaddr(x).addr
      z[] += 40

    var ints = @[1, 2, 3]
    tfoo(ints[1])
    doAssert retaddr_calls == 2
    doAssert tfoo_calls == 1
    doAssert ints[1] == 102

    var tbar_calls = 0
    proc tbar(x: var int): var int =
      tbar_calls += 1
      x

    tbar(ints[2]) += 10
    tbar(ints[2]) *= 2
    doAssert tbar_calls == 2

    var tqux_calls = 0
    proc tqux(x: var int): ptr int =
      tqux_calls += 1
      x.addr

    discard tqux(ints[2]) == tqux(ints[2])
    doAssert tqux_calls == 2
    doAssert isNil(tqux(ints[2])) == false
    doAssert tqux_calls == 3

    var tseq_calls = 0
    proc tseq(x: var seq[int]): var seq[int] =
      tseq_calls += 1
      x

    tseq(ints) &= 999
    doAssert tseq_calls == 1
    doAssert ints == @[1, 102, 26, 999]

    var rawints = @[555]
    rawints &= 666
    doAssert rawints == @[555, 666]

    var resetints_calls = 0
    proc resetInts(): int =
      resetints_calls += 1
      ints = @[0, 0, 0]
      1

    proc incr(x: var int; b: int): var int =
      x = x + b
      x

    var q = 0
    var qp = q.addr
    qp[] += 123
    doAssert q == 123
    # check order of evaluation
    doAssert (resetInts() + incr(q, tqux(ints[2])[])) == 124

  block: # reset
    var calls = 0
    proc passsomething(x: var int): var int =
      calls += 1
      x

    var
      a = 123
      b = 500
      c = a.addr
    reset(passsomething(a))
    doAssert calls == 1
    reset(b)
    doAssert a == b
    reset(c)
    doAssert c == nil

  block: # strings
    var calls = 0
    proc stringtest(s: var string): var string =
      calls += 1
      s

    var somestr: string

    stringtest(somestr) &= 'a'
    stringtest(somestr) &= 'b'
    doAssert calls == 2
    doAssert somestr == "ab"
    stringtest(somestr) &= "woot!"
    doAssert somestr == "abwoot!"
    doAssert calls == 3

    doAssert stringtest(somestr).len == 7
    doAssert calls == 4
    doAssert high(stringtest(somestr)) == 6
    doAssert calls == 5

    var somestr2: string
    stringtest(somestr2).setLen(stringtest(somestr).len)
    doAssert calls == 7
    doAssert somestr2.len == somestr.len

    var somestr3: string
    doAssert (somestr3 & "foo") == "foo"

    block:
      var a, b, c, d: string
      d = a & b & c
      doAssert d == ""
      d = stringtest(a) & stringtest(b) & stringtest(c)
      doAssert calls == 10
      doAssert d == ""

  block: # seqs
    var calls = 0
    proc seqtest(s: var seq[int]): var seq[int] =
      calls += 1
      s

    var someseq: seq[int]

    seqtest(someseq) &= 1
    seqtest(someseq) &= 2
    doAssert calls == 2
    doAssert someseq == @[1, 2]
    seqtest(someseq) &= @[3, 4, 5]
    doAssert someseq == @[1, 2, 3, 4, 5]
    doAssert calls == 3

    doAssert seqtest(someseq).len == 5
    doAssert calls == 4
    doAssert high(seqtest(someseq)) == 4
    doAssert calls == 5

    # genArrayAddr
    doAssert seqtest(someseq)[2] == 3
    doAssert calls == 6

    seqtest(someseq).setLen(seqtest(someseq).len)
    doAssert calls == 8

    var somenilseq: seq[int]
    seqtest(somenilseq).setLen(3)
    doAssert calls == 9
    doAssert somenilseq[1] == 0

    someseq = @[1, 2, 3]
    doAssert (seqtest(someseq) & seqtest(someseq)) == @[1, 2, 3, 1, 2, 3]


  block: # mInc, mDec
    var calls = 0
    proc someint(x: var int): var int =
      calls += 1
      x

    var x = 10

    inc(someint(x))
    doAssert x == 11
    doAssert calls == 1

    dec(someint(x))
    doAssert x == 10
    doAssert calls == 2

  block: # uints
    var calls = 0
    proc passuint(x: var uint32): var uint32 =
      calls += 1
      x

    var u: uint32 = 5
    passuint(u) += 1
    doAssert u == 6
    doAssert calls == 1

    passuint(u) -= 1
    doAssert u == 5
    doAssert calls == 2

    passuint(u) *= 2
    doAssert u == 10
    doAssert calls == 3

  block: # objs
    type Thing = ref object
      x, y: int

    var a, b: Thing
    a = Thing()
    b = a

    doAssert a == b

    var calls = 0
    proc passobj(o: var Thing): var Thing =
      calls += 1
      o

    passobj(b) = Thing(x: 123)
    doAssert calls == 1
    doAssert a != b
    doAssert b.x == 123

    var passobjptr_calls = 0
    proc passobjptr(o: var Thing): ptr Thing =
      passobjptr_calls += 1
      o.addr

    passobjptr(b)[] = Thing(x: 234)
    doAssert passobjptr_calls == 1
    doAssert a != b
    doAssert b.x == 234
    passobjptr(b)[].x = 500
    doAssert b.x == 500

    var pptr = passobjptr(b)
    pptr.x += 100
    doAssert b.x == 600

    proc getuninitptr(): ptr int =
      return

    doAssert getuninitptr() == nil

  block: # pointer casting
    var obj = (x: 321, y: 543)
    var x = 500

    var objptr = obj.addr
    var xptr = x.addr

    var p1, p2: pointer
    p1 = cast[pointer](objptr)
    p2 = cast[pointer](xptr)
    doAssert p1 != p2

    p1 = cast[pointer](objptr)
    p2 = cast[pointer](objptr)
    doAssert p1 == p2

    let objptr2 = cast[type(objptr)](p2)
    doAssert objptr == objptr2

    p1 = cast[pointer](xptr)
    p2 = cast[pointer](xptr)
    doAssert p1 == p2

    let xptr2 = cast[type(xptr)](p2)
    doAssert xptr == xptr2
  
  block: # var types
    block t10202:
      type Point = object
        x: float
        y: float

      var points: seq[Point]

      points.add(Point(x:1, y:2))

      for i, p in points.mpairs:
        p.x += 1

      doAssert points[0].x == 2
    
    block:
      var ints = @[1, 2, 3]
      for i, val in mpairs ints:
        val *= 10
      doAssert ints == @[10, 20, 30]
    
    block:
      var seqOfSeqs = @[@[1, 2], @[3, 4]]
      for i, val in mpairs seqOfSeqs:
        val[0] *= 10
      doAssert seqOfSeqs == @[@[10, 2], @[30, 4]]

  when false:
    block: # openArray
          # Error: internal error: genAddr: nkStmtListExpr
      var calls = 0
      proc getvarint(x: var openArray[int]): var int =
        calls += 1
        if true:
          x[1]
        else:
          x[0]

      var arr = [1, 2, 3]
      getvarint(arr) += 5
      doAssert calls == 1
      doAssert arr[1] == 7

proc tests_in_proc =
  tests

# since pointers are handled differently in global/local contexts
# let's just run all of them twice
tests_in_proc()
tests
