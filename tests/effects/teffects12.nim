discard """
action: compile
"""

import std/locks

type
  Test2Effect* = object
  Test2* = object
    value2*: int
  Test1Effect* = object
  Test1* = object
    value1*: int
  Main* = object
    test1Lock: Lock
    test1: Test1
    test2Lock: Lock
    test2: Test2

proc `=copy`(obj1: var Test2, obj2: Test2) {.error.}
proc `=copy`(obj1: var Test1, obj2: Test1) {.error.}
proc `=copy`(obj1: var Main, obj2: Main) {.error.}

proc withTest1(main: var Main,
               fn: proc(test1: var Test1) {.gcsafe, forbids: [Test1Effect].}) {.gcsafe, tags: [Test1Effect, RootEffect].} =
  withLock(main.test1Lock):
    fn(main.test1)

proc withTest2(main: var Main,
               fn: proc(test1: var Test2) {.gcsafe, forbids: [Test2Effect].}) {.gcsafe, tags: [Test2Effect, RootEffect].} =
  withLock(main.test2Lock):
    fn(main.test2)

proc newMain(): Main =
  var test1lock: Lock
  initLock(test1Lock)
  var test2lock: Lock
  initLock(test2Lock)
  var main = Main(test1Lock: move(test1Lock), test1: Test1(value1: 1),
                  test2Lock: move(test2Lock), test2: Test2(value2: 2))
  main.withTest1(proc(test1: var Test1) = test1.value1 += 1)
  main.withTest2(proc(test2: var Test2) = test2.value2 += 1)
  move main

var main = newMain()
main.withTest1(proc(test1: var Test1) =
  test1.value1 += 1
  main.withTest2(proc(test2: var Test2) = test2.value2 += 1)
)

main.withTest1(proc(test1: var Test1) {.tags: [].} = echo $test1.value1)
main.withTest2(proc(test2: var Test2) {.tags: [].} = echo $test2.value2)
