discard """
  matrix: "--hint:all:off"
  nimoutfull: true
  nimout: '''
twarnsideeffects.nim(28, 6) Warning: 'fn2' can have side effects
> twarnsideeffects.nim(29, 3) Hint: 'fn2' accesses global state 'z'
>> twarnsideeffects.nim(27, 5) Hint: 'z' accessed by 'fn2'
 [SideEffects]
'''
"""




# line 15
template bar =
  func fn()=
    echo 1

doAssert compiles(bar())

{.push warningAsError[SideEffects]:on.}
doAssert not compiles(bar())
{.pop.}
doAssert compiles(bar())

var z = 0
func fn2()=
  z.inc
