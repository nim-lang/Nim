discard """
  output: '''3 3
4 4 4
5 5 5 5
654 654 654 654
256 256 256 256
0 543 543 543
20 20 20
0 222 222 true
true
true
456 1 2 456 456 true
true 321 321
 it's a ref! it's a ref!
@[1, 102, 3]

globals:
3 3
4 4 4
5 5 5 5
654 654 654 654
256 256 256 256
0 543 543 543
20 20 20
0 222 222 true
true
true
456 1 2 456 456 true
true 321 321
 it's a ref! it's a ref!
@[1, 102, 3]
'''
"""

template tests =
  block:
    var i = 0
    i = 2

    var y = i.addr
    y[] = 3
    echo i, " ", y[]

    let z = i.addr
    z[] = 4
    echo i, " ", y[], " ", z[]

    var hmm = (a: (b: z))
    var hmmptr = hmm.a.b.addr
    hmmptr[][] = 5

    echo i, " ", y[], " ", z[], " ", hmmptr[][]

  block:
    var someint = 500

    let p: ptr int = someint.addr
    let tup = (f: p)
    let tcopy = tup
    var vtcopy = tcopy
    p[] = 654
    echo p[], " ", tup.f[], " ", tcopy.f[], " ", vtcopy.f[]

  block:
    var someint = 500

    var p: ptr int = someint.addr
    let arr = [p]
    let arrc = arr
    p[] = 256
    echo someint, " ", p[], " ", arr[0][], " ", arrc[0][]

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

    echo someref[], " ", tup1.f[], " ", tup2.f[], " ", someref2[]

  block:
    type Whatever = object
      i: ref int

    var someref: ref int
    new(someref)
    someref[] = 10

    let w = Whatever(i: someref)
    var wcopy = w

    someref[] = 20
    echo w.i[], " ", someref[], " ", wcopy.i[]

  block:
    var oneseq: ref seq[ref int]
    new(oneseq)
    var aref: ref int
    new(aref)
    aref[] = 123
    let arefs = [aref]
    oneseq[] &= arefs[0]
    oneseq[] &= aref
    # oneseq[] &= aref
    aref[] = 222
    new(aref)
    echo aref[], " ", oneseq[0][], " ", oneseq[1][], " ", oneseq[0] == oneseq[1]


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
    echo arefs[0] == aref
    seqs[0][] &= arefs[0]
    seqs[0][] &= aref
    seqs[0][1][] = 456
    let seqs2 = seqs
    let same = seqs2[0][0] == seqs2[0][1]
    echo arefs[0] == aref
    echo aref[], " ", seqs[].len, " ", seqs[0][].len, " ", seqs[0][0][], " ", seqs[0][1][], " ", same

  block:
    type Obj = object
      x, y: int

    var objrefs: seq[ref Obj] = @[(ref Obj)(nil), nil, nil]
    objrefs[2].new
    objrefs[2][] = Obj(x: 123, y: 321)
    objrefs[1] = objrefs[2]
    echo (objrefs[0] == nil), " ", objrefs[1].y, " ", objrefs[2].y

  block:
    var refs: seq[ref string] = @[(ref string)(nil), nil, nil]
    refs[1].new
    refs[1][] = "it's a ref!"
    refs[0] = refs[1]
    refs[2] = refs[1]
    new(refs[0])
    echo refs[0][], " ", refs[1][], " ", refs[2][]

  block:
    proc retaddr(p: var int): var int =
      p

    proc tfoo(x: var int) =
      x += 10
      var y = x.addr
      y[] += 20
      retaddr(x) += 30
      let z = retaddr(x).addr
      z[] += 40

    var ints = @[1, 2, 3]
    tfoo(ints[1])
    echo ints

proc tests_in_proc =
  tests

# since pointers are handled differently in global/local contexts
# let's just run all of them twice
tests_in_proc()
echo ""
echo "globals:"
tests
