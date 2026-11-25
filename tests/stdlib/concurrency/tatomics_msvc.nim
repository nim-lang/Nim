discard """
  matrix: "--cc:vcc --threads:on --mm:refc; --cc:vcc --threads:on --mm:orc"
  targets: "c"
  disabled: "linux"
  disabled: "bsd"
  disabled: "osx"
  disabled: "unix"
  disabled: "posix"
  timeout: "60"
"""

# Exercise the same API contracts through MSVC's interlocked intrinsics.
include tatomics

import std/[monotimes, os, times, typedthreads]

const
  workerCount = 4
  operationsPerWorker = 10_000

var
  counter: Atomic[int]
  completed: Atomic[int]

proc incrementCounter() {.thread.} =
  for i in 0..<operationsPerWorker:
    let previous = counter.fetchAdd(1, moRelaxed)
    doAssert previous >= 0 and previous < workerCount * operationsPerWorker
  discard completed.fetchAdd(1, moRelease)

block contendedArithmeticMakesProgress:
  var workers: array[workerCount, Thread[void]]
  for worker in workers.mitems:
    createThread(worker, incrementCounter)
  let deadline = getMonoTime() + initDuration(seconds = 30)
  while completed.load(moAcquire) != workerCount and getMonoTime() < deadline:
    sleep(1)
  doAssert completed.load(moAcquire) == workerCount
  joinThreads(workers)
  doAssert counter.load == workerCount * operationsPerWorker
