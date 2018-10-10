discard """
cmd: '''nim c --hints:off $file'''
errormsg: "attempting to call routine: 'myPragma'"
nimout: '''undeclared_routime2.nim(12, 26) Error: attempting to call routine: 'myPragma'
  found 'undeclared_routime2.myPragma()[declared in undeclared_routime2.nim(10, 5)]' of kind 'proc'
  found 'undeclared_routime2.myPragma()[declared in undeclared_routime2.nim(11, 9)]' of kind 'iterator'
'''
"""

proc myPragma():int=discard
iterator myPragma():int=discard
proc myfun(a:int): int {.myPragma.} = 1
let a = myfun(1)
