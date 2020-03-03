discard """
output: '''
10
1111
1222
3030303
3060606
6060606
6121212
3030903
3061206
3031503
3061806
5050505
5101010
'''
"""

import typetraits

var tls1 {.threadvar.}: int
var g0: int
var g1 {.global.}: int

proc customInc(x: var int, delta: int) =
  x += delta

customInc(tls1, 10)
echo tls1

proc nonGenericProc: int =
  var local: int
  var nonGenericTls {.threadvar.}: int
  var nonGenericGlobal {.global.}: int
  var nonGenericMixedPragmas {.global, threadvar.}: int

  customInc local, 1000
  customInc nonGenericTls, 1
  customInc nonGenericGlobal, 10
  customInc nonGenericMixedPragmas, 100

  return local + nonGenericTls + nonGenericGlobal + nonGenericMixedPragmas

proc genericProc(T: typedesc): int =
  var local: int
  var genericTls {.threadvar.}: int
  var genericGlobal {.global.}: int
  var genericMixedPragmas {.global, threadvar.}: int

  customInc local, T.name.len * 1000000
  customInc genericTls, T.name.len * 1
  customInc genericGlobal, T.name.len * 100
  customInc genericMixedPragmas, T.name.len * 10000

  return local + genericTls + genericGlobal + genericMixedPragmas

echo nonGenericProc()
echo nonGenericProc()

echo genericProc(int)
echo genericProc(int)

echo genericProc(string)
echo genericProc(string)

proc echoInThread[T]() {.thread.} =
  echo genericProc(T)
  echo genericProc(T)

proc newEchoThread(T: typedesc) =
  var t: Thread[void]
  createThread(t, echoInThread[T])
  joinThreads(t)

newEchoThread int
newEchoThread int
newEchoThread float

