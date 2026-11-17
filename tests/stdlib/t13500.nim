discard """
  matrix: "--warning:Deprecated:off"
  targets: "c js"
  output: '''
{1: 10, 1: 11}
{:}
'''
"""

# bug #13500: `del` of an `OrderedTable` with duplicate keys
import std/tables
var t: OrderedTable[int, int]
t.add 1, 10
t.add 1, 11
t[2] = 12
t.del(2)
echo t
t.del(1)
echo t
