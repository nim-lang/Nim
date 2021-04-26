discard """
cmd: '''nim c --hints:off $file'''
errormsg: "undeclared field: 'bar'"
nimout: '''undeclared_routime4.nim(10, 10) Error: undeclared field: 'bar'
'''
"""

type Foo = object
var a = Foo()
let a = a.bar
