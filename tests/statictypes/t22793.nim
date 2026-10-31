discard """
output: '''
@["a", "b"]
@["a", "b"]
@["a", "b"]
@["a", "b"]
'''
"""

# bug #22793

const x = @["a", "b"]

proc myProc(x: seq[string]) =
  echo x
x.myProc()

proc myProc2(x: seq[string] = @[]) = # Compiler correctly infers that `@[]` is `seq[string]`
  echo x
x.myProc2()

proc myProc3(x: static seq[string]) =
  echo x
x.myProc3()

proc myProc4(x: static seq[string] = @[]) = # This proc causes a compiler error. Compiler does not infer that `@[]` is `static seq[string]`
  echo x
x.myProc4()
