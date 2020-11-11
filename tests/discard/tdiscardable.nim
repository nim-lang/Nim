discard """
output: '''
tdiscardable
1
1
something defered
something defered
'''
"""

echo "tdiscardable"

# Test the discardable pragma

proc p(x, y: int): int {.discardable.} =
  return x + y

# test that it is inherited from generic procs too:
proc q[T](x, y: T): T {.discardable.} =
  return x + y


p(8, 2)
q[float](0.8, 0.2)

# bug #942

template maybeMod(x: SomeInteger, module: Natural): untyped =
  if module > 0: x mod module
  else: x

proc foo(b: int):int =
  var x = 1
  result = x.maybeMod(b) # Works fine

proc bar(b: int):int =
  result = 1
  result = result.maybeMod(b) # Error: value returned by statement has to be discarded

echo foo(0)
echo bar(0)

# bug #9726

proc foo: (proc: int) =
  proc bar: int = 1
  return bar

discard foo()

# bug #10842

proc myDiscardable(): int {.discardable.} =
  discard

proc main1() =
  defer:
    echo "something defered"
  discard myDiscardable()

proc main2() =
  defer:
    echo "something defered"
  myDiscardable()

main1()
main2()
