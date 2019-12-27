discard """
cmd: '''nim c --hints:off $file'''
errormsg: "invalid pragma: myPragma"
"""

proc myPragma():int=discard
iterator myPragma():int=discard
proc myfun(a:int): int {.myPragma.} = 1
let a = myfun(1)
