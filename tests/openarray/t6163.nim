discard """
  exitcode: 0
  targets: "c cpp js"
  output: '''19316
'''
"""

from sugar import `->`, `=>`
from math import `^`, sum
from sequtils import filter, map, toSeq

proc f: int =
  toSeq(10..<10_000).filter(a => a == ($a).map(d => (d.ord-'0'.ord).int^4).sum).sum

var a = f()

echo a
