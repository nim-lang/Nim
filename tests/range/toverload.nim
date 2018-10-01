discard """
  output: 
'''
cool
uncool
'''
"""

type
  Cool = range[5..6]
  Uncool = range[4..5]

template x(_: Cool) = echo "cool"
template x(_: Uncool) = echo "uncool"

x(6)
x(4)
# Ambiguous call since 5 is included by both the ranges
doAssert(not compiles(x(5)))
