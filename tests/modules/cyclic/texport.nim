discard """
  joinable: false
  output: '''
1 3 4 5 6
'''
"""

# A leading `export` of a module of the cycle group runs after the leading
# declarations of every module of the group, so it exports what they declare.
import exports/mexport_a

echo fa(), " ", fb(2), " ", fc(), " ", C(x: 5).x, " ", fd()
doAssert not compiles(hidden())
