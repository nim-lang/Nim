discard """
action: compile
"""

type
  Bar = object
    x: int

  Foo = object
    rheap: ref Bar
    rmaybe: ref Bar
    rstack: ref Bar
    list: seq[ref Bar]
    listarr: array[0..5, ref Bar]
    nestedtup: Tup
    inner: TInner
    inref: ref TInner

  TInner = object
    inref: ref Bar

  Tup = tuple
    tupbar: ref Bar
    inner: TInner

proc acc(x: var Foo): var ref Bar =
  result = x.rheap

proc test(maybeFoo: var Foo,
          maybeSeq: var seq[ref Bar],
          bars: var openArray[ref Bar],
          maybeTup: var Tup) =
  var bb: ref Bar
  maybeFoo.rmaybe = bb
  maybeFoo.list[3] = bb
  maybeFoo.listarr[3] = bb
  acc(maybeFoo) = bb

  var localFoo: Foo
  localFoo.rstack = bb
  localFoo.list[3] = bb
  localFoo.listarr[3] = bb
  acc(localFoo) = bb

  var heapFoo: ref Foo
  heapFoo.rheap = bb
  heapFoo.list[3] = bb
  heapFoo.listarr[3] = bb
  acc(heapFoo[]) = bb

  heapFoo.nestedtup.tupbar = bb
  heapFoo.nestedtup.inner.inref = bb
  heapFoo.inner.inref = bb
  heapFoo.inref.inref = bb

  var locseq: seq[ref Bar]
  locseq[3] = bb

  var locarr: array[0..4, ref Bar]
  locarr[3] = bb

  maybeSeq[3] = bb

  bars[3] = bb

  maybeTup[0] = bb

var
  ff: ref Foo
  tt: Tup
  gseq: seq[ref Bar]

new(ff)

test(ff[], gseq, gseq, tt)
