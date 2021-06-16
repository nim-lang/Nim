discard """
  matrix: "--hint:SuccessX:off --hint:Link:off --hint:Conf:off --hint:CC:off --hint:XDeclaredButNotUsed:on"
  nimout: '''
'''
nimoutFull: true
action: compile
"""

# bug #18203
import std/macros

macro foo(x: typed) = newProc ident"bar"
proc bar() {.foo.} = raise
bar()

