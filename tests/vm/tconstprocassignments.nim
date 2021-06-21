discard """
  output: '''
100
100
'''
"""

proc f():int {.compileTime.} = 100

const F = f
echo F()

const G = proc ():int =
  let x = f
  let y = x
  y()

echo G()
