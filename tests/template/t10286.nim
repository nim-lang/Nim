discard """
  output: '''
1
1
'''
"""

# bug #10286: a proc conversion returned from a template
type
  Func = proc (x: int)

proc makeFuncProc(f: Func): Func =
  Func(f)

template makeFuncTemplate(f: Func): Func =
  Func(f)

proc test(arg: openArray[Func]) =
  echo arg.len

test([makeFuncProc(proc (x: int) = echo x)])
test([makeFuncTemplate(proc (x: int) = echo x)])
