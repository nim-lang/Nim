discard """
  output: '''1
0
0
0'''
"""

proc `1/1`() = echo(1 div 1)
template `1/2`() = echo(1 div 2)
var `1/3` = 1 div 4
`1/3` = 1 div 3 # oops, 1/3!=1/4
let `1/4` = 1 div 4

`1/1`()
`1/2`()
echo `1/3`
echo `1/4`
