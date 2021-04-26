discard """
cmd: '''nim c --hints:off $file'''
errormsg: "undeclared field: 'bar'"
nimout: '''undeclared_routine3.nim(13, 10) Error: undeclared field: 'bar'
  found 'undeclared_routine3.bar()[declared in undeclared_routine3.nim(12, 9)]' of kind 'iterator'
'''
"""


type Foo = object
var a = Foo()
iterator bar():int=discard
let a = a.bar
