discard """
  output: "ok"
"""

# bug #4084: generic type constraints and instantiated signatures
type
  Image[T] = object
    data: seq[T]
  Image2[T: int32|int64] = object
    data: seq[T]

proc newImage[T: int32|int64](w, h: int): ref Image[T] =
  new(result)
  result.data = newSeq[T](w * h)

proc newImage2[T](w, h: int): ref Image2[T] =
  new(result)
  result.data = newSeq[T](w * h)

proc newImage3[T: int32|int64](w, h: int): ref Image2[T] =
  new(result)
  result.data = newSeq[T](w * h)

doAssert not compiles(newImage[string](320, 200))
doAssert not compiles(newImage2[string](320, 200))
doAssert newImage2[int64](2, 2).data.len == 4
doAssert newImage3[int32](3, 2).data.len == 6

# Constraints still apply to newly substituted parameter types, including when
# a preceding parameter disappears during void erasure.
proc consumeImage[T](x: ref Image2[T]) = discard
proc consumeAfterVoid[A, T](a: A, x: ref Image2[T]) = discard
doAssert not compiles(consumeImage[string](nil))
doAssert not compiles(consumeAfterVoid[void, string](nil))
consumeImage[int32](nil)
consumeAfterVoid[void, int64](nil)

# An unconstrained alias must not hide the underlying type's constraint.
type
  ImageAlias[T] = Image2[T]
  ImageAlias2[T] = ImageAlias[T]
  RefImageAlias[T] = ref Image2[T]
  SeqImageAlias[T] = seq[Image2[T]]
  Phantom[T: SomeInteger] = object
  PhantomAlias[T] = Phantom[T]
  UnresolvedAlias = Image2[auto]

proc newAlias[T](): ImageAlias[T] = discard
proc newAlias2[T](): ImageAlias2[T] = discard
proc newPhantom[T](): PhantomAlias[T] = discard
proc newRefAlias[T](): RefImageAlias[T] = discard
proc newSeqAlias[T](): SeqImageAlias[T] = discard
proc consumeAlias[T](x: ref ImageAlias2[T]) = discard
proc newUnresolved[T](): UnresolvedAlias = discard

doAssert not compiles(newAlias[string]())
doAssert not compiles(newAlias2[string]())
doAssert not compiles(newPhantom[string]())
doAssert not compiles(newRefAlias[string]())
doAssert not compiles(newSeqAlias[string]())
doAssert not compiles(consumeAlias[string](nil))
doAssert not compiles(newUnresolved[int]())
discard newAlias[int32]()
discard newAlias2[int64]()
discard newPhantom[int]()
discard newRefAlias[int32]()
discard newSeqAlias[int64]()
consumeAlias[int32](nil)
echo "ok"
