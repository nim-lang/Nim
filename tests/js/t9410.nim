discard """
  output: '''654 654 654 654
256 256 256 256
543 543 543 543
20 20 20
'''
"""

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