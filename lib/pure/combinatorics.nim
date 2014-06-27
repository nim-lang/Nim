#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Reimer Behrends
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The combinatorics module contains routines to enumerate permutations,
## choices, or combinations of a sequence or array. These routines are
## implemented as iterators that yield sequences. ``sequtils.toSeq``
## can be used to gather all results in a single sequence.
##
## The implementations assume that the input does not contain duplicates;
## if it contains duplicate entries, these will be treated as distinct
## items.

import sequtils

iterator permutations*[T](s: openarray[T]): seq[T] =
  ## Enumerates all possible permutations of `s`.
  let n = len(s)
  if n == 0:
    yield @[]
  else:
    var pos = toSeq(0..n-1)
    var current = newSeq[T](n)
    while true:
      for i in 0..n-1:
        current[i] = current[pos[i]]
        current[pos[i]] = s[i]
      yield current
      var i = 1
      while i < n:
        pos[i] -= 1
        if pos[i] < 0:
          pos[i] = i
          i += 1
        else:
          break
      if i == n:
        break

iterator choices*[T](s: openarray[T], k: int): seq[T] =
  ## Enumerates all possible choices of `k` distinct elements
  ## out of `s`.
  let n = len(s)
  assert k >= 0 and k <= n
  # Optimizing the following special cases confuses the code
  # generator, so we leave them out for now:
  # 
  # case k
  # of 0:
  #   discard
  # of 1:
  #   var current = newSeq[T](1)
  #   for i in 0..n-1:
  #     current[0] = s[i]
  #     yield current
  # of 2:
  #   var current = newSeq[T](2)
  #   for i in 0..n-2:
  #     for j in i+1..n-1:
  #       current[0] = s[i]
  #       current[1] = s[j]
  #       yield current
  # else:
  if k == 0:
    yield @[]
  else:
    var pos = toSeq(countdown(k-1, 0))
    var current = newSeq[T](k)
    var done = false
    while not done:
      for i in 0..k-1:
        current[i] = s[pos[k-i-1]]
      yield current
      for i in 0..k-1:
        pos[i] += 1
        if pos[i] < n-i:
          for j in 0..i-1:
            pos[j] = pos[i] + i - j
          break
        if i == k-1:
          done = true

iterator combinations*[T](s: openarray[T], n: int): seq[T] =
  ## Enumerates all possible sequences of length `n` that contain
  ## elements of `s`. Essentially, this enumerates the elements of
  ## the Cartesian product ``s^n``.
  if n >= 0 and len(s) > 0:
    var pos = newSeq[int](n)
    var current = newSeq[T](n)
    while true:
      for i in 0..n-1:
        current[i] = s[pos[i]]
      yield current
      var i = 0
      while i < n:
        pos[i] += 1
        if pos[i] >= len(s):
          pos[i] = 0
          i += 1
        else:
          break
      if i == n:
        break

when isMainModule:
  import sets
  template count(s: expr): int =
    len(toSet(toSeq(s)))
  doAssert count(permutations([1,2,3,4,5])) == 120
  doAssert count(permutations(["a", "b", "c"])) == 6
  doAssert count(choices([1,2,3,4], 1)) == 4
  doAssert count(choices([1,2,3,4], 2)) == 6
  doAssert count(choices([1,2,3,4], 3)) == 4
  doAssert count(choices(["a", "b", "c", "d", "e"], 3)) == 10
  doAssert count(combinations([1,2,3,4], 3)) == 4*4*4
  doAssert count(combinations([1,2], 10)) == 1024
