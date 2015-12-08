discard """
  file: "tsets3.nim"
"""
include sets

let
  s1: TSet[int] = toSet([1, 2, 4, 8, 16])
  s2: TSet[int] = toSet([1, 2, 3, 5, 8])
  s3: TSet[int] = toSet([3, 5, 7])

block union:
  let
    s1_s2 = union(s1, s2)
    s1_s3 = s1 + s3
    s2_s3 = s2 + s3

  doAssert s1_s2.len == 7
  doAssert s1_s3.len == 8
  doAssert s2_s3.len == 6

  for i in s1:
    doAssert i in s1_s2
    doAssert i in s1_s3
  for i in s2:
    doAssert i in s1_s2
    doAssert i in s2_s3
  for i in s3:
    doAssert i in s1_s3
    doAssert i in s2_s3

  doAssert((s1 + s1) == s1)
  doAssert((s2 + s1) == s1_s2)

block intersection:
  let
    s1_s2 = intersection(s1, s2)
    s1_s3 = intersection(s1, s3)
    s2_s3 = s2 * s3

  doAssert s1_s2.len == 3
  doAssert s1_s3.len == 0
  doAssert s2_s3.len == 2

  for i in s1_s2:
    doAssert i in s1
    doAssert i in s2
  for i in s1_s3:
    doAssert i in s1
    doAssert i in s3
  for i in s2_s3:
    doAssert i in s2
    doAssert i in s3

  doAssert((s2 * s2) == s2)
  doAssert((s3 * s2) == s2_s3)

block symmetricDifference:
  let
    s1_s2 = symmetricDifference(s1, s2)
    s1_s3 = s1 -+- s3
    s2_s3 = s2 -+- s3

  doAssert s1_s2.len == 4
  doAssert s1_s3.len == 8
  doAssert s2_s3.len == 4

  for i in s1:
    doAssert i in s1_s2 xor i in s2
    doAssert i in s1_s3 xor i in s3
  for i in s2:
    doAssert i in s1_s2 xor i in s1
    doAssert i in s2_s3 xor i in s3
  for i in s3:
    doAssert i in s1_s3 xor i in s1
    doAssert i in s2_s3 xor i in s2

  doAssert((s3 -+- s3) == initSet[int]())
  doAssert((s3 -+- s1) == s1_s3)

block difference:
  let
    s1_s2 = difference(s1, s2)
    s1_s3 = difference(s1, s3)
    s2_s3 = s2 - s3

  doAssert s1_s2.len == 2
  doAssert s1_s3.len == 5
  doAssert s2_s3.len == 3

  for i in s1:
    doAssert i in s1_s2 xor i in s2
    doAssert i in s1_s3 xor i in s3
  for i in s2:
    doAssert i in s2_s3 xor i in s3

  doAssert((s2 - s2) == initSet[int]())
  doAssert((s1 - s3 - s1) == s1 -+- s3)

block disjoint:
  doAssert(not disjoint(s1, s2))
  doAssert disjoint(s1, s3)
  doAssert(not disjoint(s2, s3))
  doAssert(not disjoint(s2, s2))
