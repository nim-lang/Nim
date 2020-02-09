discard """
  output: '''
to be, or not to be
(v: 1)
(v: 1)
'''
  joinable: false
"""

import sequtils, sugar

let m = @[proc (s: string): string = "to " & s, proc (s: string): string = "not to " & s]
var l = m.mapIt(capture([it], proc (s: string): string = it(s)))
let r = l.mapIt(it("be"))
echo r[0] & ", or " & r[1]

type O = object
  v: int
var o = O(v: 1)
var execute: proc()
capture [o]:
  execute = proc() =
    echo o
execute()
o.v = -1
execute()
