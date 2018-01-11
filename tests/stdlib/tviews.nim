discard """
  exitcode: 0
"""
import views, unittest

let v = newView("hello world")

let intView = newView(@[1, 2, 3])

assert v.len == 11
assert v.copyAsString == "hello world"

assert newView("").copyAsString == ""
assert newView("\0").copyAsString == "\0"

assert v[0] == byte('h')

assert(initEmptyView(byte).copyAsString == "")
assert(initEmptyView(char).copyAsString == "")

assert(not compiles(initEmptyView(int).copyAsString))

assert(intView[2] == 3)

v.copyFrom(newView("xx"))
assert(v.copyAsString == "xxllo world")

v.slice(3, 3).copyFrom(newView("xx"))
assert(v.copyAsString == "xxlxx world")

expect(AssertionError):
  discard v.slice(30)

expect(AssertionError):
  discard v.slice(0, v.len + 1)

expect(AssertionError):
  discard v.slice(1, v.len)

expect(AssertionError):
  discard v.slice(0, 100)

expect(AssertionError): # not OverflowError!
  discard v.slice(2, high(int) - 1)

expect(AssertionError):
  discard v[v.len]

expect(AssertionError):
  discard v[-1]

expect(AssertionError):
  discard v.slice(-1, 2)

expect(AssertionError):
  let view1 = newView(byte, 10)
  view1.copyFrom(v)

assert newView(int, 1024).len == 1024
assert newView(byte, 0).len == 0

var index = 1
for i in intView:
  assert i == index
  index += 1

var gcTestViews: seq[View[int]] = @[]

for i in 0..100:
  gcTestViews.add newView(@[i, i, i, i, i, i, i, i, i])
  GC_fullCollect()

for i, view in gcTestViews:
  assert view.len == 9
  for item in view:
    assert item == i
