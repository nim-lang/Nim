discard """
  target: "c"
  output: '''
2302
'''
joinable: false
"""

import sequtils

type
  ft = proc (x: int): int {.noSideEffect.}

proc foo() =
  let m = @[func (x: int): int = x + 100, func (x: int): int = x + 200]
  var l: seq[ft] = @[]
  for it in m:
    l.add(func (x: int): int = it(x) + 1000)
  let r = l.map(func (f: ft): int = f(1))  
  echo r[0] + r[1]

if isMainModule:
  foo()

