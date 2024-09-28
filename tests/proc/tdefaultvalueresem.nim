discard """
  output: '''
seq[string]
@[]
seq[string]
@[]
seq[string]
@[]
seq[string]
@[]
seq[string]
@[]
seq[string]
@[]
'''
"""

# regression from #24184, see #24191

const a: seq[string] = @[]

proc foo(x = a) =
  echo typeof(x)
  echo x

proc bar(x: static seq[string] = a) =
  echo typeof(x)
  echo x

# issue #22793
proc baz(x: static seq[string] = @[]) =
  echo typeof(x)
  echo x

import macros

macro resem(x: typed) =
  expectKind x, nnkSym
  result = getImpl(x)

foo()
bar()
baz()
block:
  resem(foo) # Error: cannot infer the type of parameter 'x'
  resem(bar)
  resem(baz)
  foo()
  bar()
  baz()
