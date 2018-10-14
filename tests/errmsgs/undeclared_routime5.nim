discard """
cmd: '''nim c --hints:off $file'''
errormsg: "undeclared identifier: 'myfun'"
nimout: '''undeclared_routime5.nim(9, 9) Error: undeclared identifier: 'myfun'
'''
"""


let a = myfun(1)
