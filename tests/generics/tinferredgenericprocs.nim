discard """
  output: '''123
1
2
3'''
"""

# https://github.com/Araq/Nimrod/issues/797
proc foo[T](s:T):string = $s

type IntStringProc = proc(x: int): string 

var f1 = IntStringProc(foo)
var f2: proc(x: int): string = foo
var f3: IntStringProc = foo

echo f1(1), f2(2), f3(3)

for x in map([1,2,3], foo): echo x

