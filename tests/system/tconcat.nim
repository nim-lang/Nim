discard """
  targets: "c cpp js"
  output: '''
DabcD
(8192, 8, 1024)
'''
"""

import std/assertions

block:
  const
    x = "abc"

  var v = "D" & x & "D"

  doAssert v == "DabcD"
  echo v

block: # test large additions
  var a = "abcdefgh"
  let initialLen = a.len
  let times = 10
  for i in 1..times:
    let start = a.len
    a.add(a)
    doAssert a.len == 2 * start
  let multiplier = 1 shl times
  doAssert a.len == initialLen * multiplier
  echo (a.len, initialLen, multiplier)
  for i in 1 ..< multiplier:
    for j in 0 ..< initialLen:
      doAssert a[j] == a[i * initialLen + j]
