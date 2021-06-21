discard """
  output: '''0
hello'''
"""

type
  CircAlloc*[Size: static[int], T] = tuple
    baseArray: array[Size,T]
    index: uint16

type
  Job = object of RootObj

var foo {.threadvar.}: CircAlloc[1, Job]

when true:
  echo foo.index


# bug #10795
import asyncdispatch
import threadpool

proc f1() =
  waitFor sleepAsync(20)
  echo "hello"

spawn f1()
sync()
