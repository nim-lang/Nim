discard """
  targets: "cpp"
  action: "compile"
"""

import sequtils, strutils


let rules = toSeq(lines("input"))
  .mapIt(it.split(" => ").mapIt(it.replace("/", "")))
  .mapIt((it[0], it[1]))


proc pp(s: string): auto =
  toSeq(lines(s)).mapIt(it.split(" => ").mapIt(it.replace("/", ""))).mapIt((it[0], it[1]))
echo pp("input")
