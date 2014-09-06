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

  assert s1_s2.len == 7
  assert s1_s3.len == 8
  assert s2_s3.len == 6

  for i in s1:
    assert i in s1_s2
    assert i in s1_s3
  for i in s2:
    assert i in s1_s2
    assert i in s2_s3
  for i in s3:
    assert i in s1_s3
    assert i in s2_s3

  assert((s1 + s1) == s1)
  assert((s2 + s1) == s1_s2)

block intersection:
  let
    s1_s2 = intersection(s1, s2)
    s1_s3 = intersection(s1, s3)
    s2_s3 = s2 * s3

  assert s1_s2.len == 3
  assert s1_s3.len == 0
  assert s2_s3.len == 2

  for i in s1_s2:
    assert i in s1
    assert i in s2
  for i in s1_s3:
    assert i in s1
    assert i in s3
  for i in s2_s3:
    assert i in s2
    assert i in s3

  assert((s2 * s2) == s2)
  assert((s3 * s2) == s2_s3)

block symmetricDifference:
  let
    s1_s2 = symmetricDifference(s1, s2)
    s1_s3 = s1 -+- s3
    s2_s3 = s2 -+- s3

  assert s1_s2.len == 4
  assert s1_s3.len == 8
  assert s2_s3.len == 4

  for i in s1:
    assert i in s1_s2 xor i in s2
    assert i in s1_s3 xor i in s3
  for i in s2:
    assert i in s1_s2 xor i in s1
    assert i in s2_s3 xor i in s3
  for i in s3:
    assert i in s1_s3 xor i in s1
    assert i in s2_s3 xor i in s2

  assert((s3 -+- s3) == initSet[int]())
  assert((s3 -+- s1) == s1_s3)

block difference:
  let
    s1_s2 = difference(s1, s2)
    s1_s3 = difference(s1, s3)
    s2_s3 = s2 - s3

  assert s1_s2.len == 2
  assert s1_s3.len == 5
  assert s2_s3.len == 3

  for i in s1:
    assert i in s1_s2 xor i in s2
    assert i in s1_s3 xor i in s3
  for i in s2:
    assert i in s2_s3 xor i in s3

  assert((s2 - s2) == initSet[int]())
  assert((s1 - s3 - s1) == s1 -+- s3)

block disjoint:
  assert(not disjoint(s1, s2))
  assert disjoint(s1, s3)
  assert(not disjoint(s2, s3))
  assert(not disjoint(s2, s2))
