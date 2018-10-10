discard """
cmd: '''nim c --hints:off $file'''
errormsg: "attempting to call routine: 'myiter'"
nimout: '''undeclared_routime.nim(13, 15) Error: attempting to call routine: 'myiter'
  found 'undeclared_routime.myiter(a: string)[declared in undeclared_routime.nim(10, 9)]' of kind 'iterator'
  found 'undeclared_routime.myiter()[declared in undeclared_routime.nim(11, 9)]' of kind 'iterator'
'''
"""

iterator myiter(a:string): int = discard
iterator myiter(): int = discard

let a = myiter(1)
