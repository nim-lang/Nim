discard """
  nimout: '''
tisolaterefc.nim(20, 20) Warning: 'string' containing garbage-collected types cannot be isolated in refc [GcIsolated]
tisolaterefc.nim(21, 25) Warning: 'ptr string' containing garbage-collected types cannot be isolated in refc [GcIsolated]
tisolaterefc.nim(22, 20) Warning: 'Foo' containing garbage-collected types cannot be isolated in refc [GcIsolated]
tisolaterefc.nim(23, 25) Warning: 'ptr Foo' containing garbage-collected types cannot be isolated in refc [GcIsolated]
'''
  matrix: "--mm:refc"
"""

import std/isolation
type
  Foo = object
    id: ptr string

proc foo() =
  var x = Foo()

  var m = "24e"
  var s1 = isolate(m)
  var s2 = isolate(addr m)
  var s3 = isolate(x)
  var s4 = isolate(addr x)
  discard s1
  discard s2
  discard s3
  discard s4

foo()
