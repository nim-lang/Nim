discard """
  output: '''654 654
256 256 256
543 543 543 543
20 20
'''
"""

block:
    var someint = 500

    let p: ptr int = someint.addr
    let tup = (f: p)
    p[] = 654
    echo p[], " ", tup.f[]

block:
    var someint = 500

    let p: ptr int = someint.addr
    let arr = [p]
    p[] = 256
    echo someint, " ", p[], " ", arr[0][]

block:
    var someref: ref int
    new(someref)
    var someref2 = someref

    let tup1 = (f: someref)
    var tup2 = (f: someref)
    tup2.f = someref

    someref[] = 543

    echo someref[], " ", tup1.f[], " ", tup2.f[], " ", someref2[]

block:
    type Whatever = object
      i: ref int

    var someref: ref int
    new(someref)
    someref[] = 10

    let w = Whatever(i: someref)

    someref[] = 20
    echo w.i[], " ", someref[]