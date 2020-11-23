import deques


var deq = initDeque[int](1)
deq.addLast(4)
deq.addFirst(9)
deq.addFirst(123)
var first = deq.popFirst()
deq.addLast(56)
assert(deq.peekLast() == 56)
deq.addLast(6)
assert(deq.peekLast() == 6)
var second = deq.popFirst()
deq.addLast(789)
assert(deq.peekLast() == 789)

assert first == 123
assert second == 9
assert($deq == "[4, 56, 6, 789]")
assert deq == [4, 56, 6, 789].toDeque

assert deq[0] == deq.peekFirst and deq.peekFirst == 4
#assert deq[^1] == deq.peekLast and deq.peekLast == 789
deq[0] = 42
deq[deq.len - 1] = 7

assert 6 in deq and 789 notin deq
assert deq.find(6) >= 0
assert deq.find(789) < 0

block:
  var d = initDeque[int](1)
  d.addLast 7
  d.addLast 8
  d.addLast 10
  d.addFirst 5
  d.addFirst 2
  d.addFirst 1
  d.addLast 20
  d.shrink(fromLast = 2)
  doAssert($d == "[1, 2, 5, 7, 8]")
  d.shrink(2, 1)
  doAssert($d == "[5, 7]")
  d.shrink(2, 2)
  doAssert d.len == 0

for i in -2 .. 10:
  if i in deq:
    assert deq.contains(i) and deq.find(i) >= 0
  else:
    assert(not deq.contains(i) and deq.find(i) < 0)

when compileOption("boundChecks"):
  try:
    echo deq[99]
    assert false
  except IndexDefect:
    discard

  try:
    assert deq.len == 4
    for i in 0 ..< 5: deq.popFirst()
    assert false
  except IndexDefect:
    discard

# grabs some types of resize error.
deq = initDeque[int]()
for i in 1 .. 4: deq.addLast i
deq.popFirst()
deq.popLast()
for i in 5 .. 8: deq.addFirst i
assert $deq == "[8, 7, 6, 5, 2, 3]"

# Similar to proc from the documentation example
proc foo(a, b: Positive) = # assume random positive values for `a` and `b`.
  var deq = initDeque[int]()
  assert deq.len == 0
  for i in 1 .. a: deq.addLast i

  if b < deq.len: # checking before indexed access.
    assert deq[b] == b + 1

  # The following two lines don't need any checking on access due to the logic
  # of the program, but that would not be the case if `a` could be 0.
  assert deq.peekFirst == 1
  assert deq.peekLast == a

  while deq.len > 0: # checking if the deque is empty
    assert deq.popFirst() > 0

#foo(0,0)
foo(8, 5)
foo(10, 9)
foo(1, 1)
foo(2, 1)
foo(1, 5)
foo(3, 2)

import sets

block t13310:
  proc main() =
    var q = initDeque[HashSet[int16]](2)
    q.addFirst([1'i16].toHashSet)
    q.addFirst([2'i16].toHashSet)
    q.addFirst([3'i16].toHashSet)
    assert $q == "[{3}, {2}, {1}]"

  static:
    main()
