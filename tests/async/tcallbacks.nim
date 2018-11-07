discard """
  exitcode: 0
  output: '''
1
2
3
5
'''
"""
import asyncfutures

let f1: Future[int] = newFuture[int]()
f1.addCallback(proc() = echo 1)
f1.addCallback(proc() = echo 2)
f1.addCallback(proc() = echo 3)
f1.complete(10)

let f2: Future[int] = newFuture[int]()
f2.addCallback(proc() = echo 4)
f2.callback = proc() = echo 5
f2.complete(10)
