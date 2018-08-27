discard """
errormsg: "attempting to call undeclared routine: 'myiter', found 'undeclared_routime.myiter()[declared in undeclared_routime.nim(5, 9)]' of kind 'iterator'"
"""

iterator myiter():int=discard
let a = myiter()
