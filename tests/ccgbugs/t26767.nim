discard """
  matrix: "--mm:refc; --mm:orc; --mm:arc"
  output: "ok"
"""

# bug #26767: a call inside a nested constructor must not be hoisted into a
# full-size stack temporary when the destination is a fresh, unobservable
# heap object; the call writes the nested field directly.

type
  Big = object
    data: array[16 * 1024 * 1024, byte]
    s: seq[int]
  Inner = object
    big: Big
    tag: int
  Outer = object
    inner: Inner
    tag: int

proc f(): Big = result.s = @[1]

proc main() =
  # the reported repro: fresh heap destination via (ref Outer)(...)
  let r = (ref Outer)(inner: Inner(big: f(), tag: 7), tag: 3)
  doAssert r.inner.big.s == @[1]
  doAssert r.inner.tag == 7
  doAssert r.tag == 3

  # a heap-allocated seq element destination is equally unobservable
  var q: seq[Inner]
  q = @[Inner(big: f(), tag: 9)]
  doAssert q[0].big.s == @[1]
  doAssert q[0].tag == 9

main()
echo "ok"
