discard """
  matrix: "--mm:arc -d:useMalloc; --mm:arc"
"""

block: # bug #22058
  template foo(): auto =
    {.noSideEffect.}:
      newSeq[byte](1)

  type V = object
    v: seq[byte]

  proc bar(): V =
    V(v: foo())

  doAssert bar().v == @[byte(0)]
