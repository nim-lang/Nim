discard """
targets: "c cpp js"
output: '''
ok4
ok3
ok2
ok1
'''
"""

proc fun1() {.noconv.} = echo "ok1"
proc fun2() = echo "ok2"
proc fun3() {.noconv.} = echo "ok3"
proc fun4() = echo "ok4"

addQuitProc(fun1)
addQuitProc(fun2)
addQuitProc(fun3)
addQuitProc(fun4)
