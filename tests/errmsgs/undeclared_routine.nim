discard """
cmd: '''nim c --hints:off $file'''
errormsg: "attempting to call routine: 'myiter'"
nimout: '''undeclared_routine.nim(13, 15) Error: attempting to call routine: 'myiter'
  found 'undeclared_routine.myiter(a: string)[iterator declared in undeclared_routine.nim(10, 9)]'
  found 'undeclared_routine.myiter()[iterator declared in undeclared_routine.nim(11, 9)]'
'''
"""

iterator myiter(a:string): int = discard
iterator myiter(): int = discard

let a = myiter(1)
