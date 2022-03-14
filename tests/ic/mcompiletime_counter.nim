
import std/macros
import std/macrocache
import std/assertions
const myCounter = CacheCounter"myCounter"

proc getUniqueId*(): int {.compileTime.} =
  inc myCounter
  result = myCounter.value

static:
  myCounter.inc(3)
  assert myCounter.value == 3


