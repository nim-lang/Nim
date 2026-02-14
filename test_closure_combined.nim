# Combined test case for closure environment handling

import std/hashes

type NoCopy = object
  v: string
proc `=copy`(a: var NoCopy, b: NoCopy) {.error.}

proc sinkMe(v: sink NoCopy) =
  echo "sinkMe: ", v.v

# Test 1: Iterator with sink param (bug.nim scenario)
proc iterWithSink(v: sink NoCopy): iterator(): int =
  iterator(): int =
    yield 1
    sinkMe(v)  # Should be able to sink v here (last use after final yield)

# Test 2: Closure sharing (thashes scenario)
proc closureSharing() =
  var a = 0
  proc inner() = a.inc
  doAssert inner is "closure"
  let inner2 = inner  # Should share environment, not consume it
  echo "  hash(inner):  ", hash(inner)
  echo "  hash(inner2): ", hash(inner2)
  doAssert hash(inner2) == hash(inner), "Hash mismatch: " & $hash(inner2) & " != " & $hash(inner)
  inner()
  inner2()
  doAssert a == 2, "Environment was corrupted - a = " & $a

# Test 3: Callback passed to function (execProcesses scenario)
type Callback = proc(idx: int)

proc storeAndCallCallback(cb: Callback) =
  # Simulates storing callback and calling it later
  cb(0)
  cb(1)  # Call twice to ensure env isn't consumed

proc callbackScenario() =
  var count = 0
  let callback = proc(idx: int) =
    count.inc
    echo "Callback ", idx, ", count=", count
  storeAndCallCallback(callback)
  doAssert count == 2, "Callback env corrupted - count = " & $count

# Test 4: Iterator with sink + callback (combined scenario)
proc combinedTest() =
  var state = 0
  proc makeIter(): iterator(): int =
    iterator(): int =
      state.inc
      yield state
      state.inc
      yield state
  
  let it1 = makeIter()
  let it2 = makeIter()  # Share the closure
  
  discard it1()
  discard it2()
  doAssert state == 2, "Combined: state corrupted - state = " & $state

proc main() =
  echo "Test 1: Iterator with sink param"
  let vvv = iterWithSink(NoCopy(v: "test"))
  for i in vvv():
    echo "  yielded: ", i
  
  echo "\nTest 2: Closure sharing (thashes scenario)"
  closureSharing()
  
  echo "\nTest 3: Callback scenario"
  callbackScenario()
  
  echo "\nTest 4: Combined scenario"
  combinedTest()
  
  echo "\nAll tests passed!"

main()
