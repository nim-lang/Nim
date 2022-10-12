discard """
  cmd: "nim c --hints:off $file"
  errormsg: "type mismatch: got <int64, int literal(1000)>"
  nimout: '''
tconcisetypemismatch.nim(21, 43) Error: type mismatch: got <int64, int literal(1000)>
Expected one of (first mismatch at position [#]):
[1] proc `/`(x, y: float): float
[1] proc `/`(x, y: float32): float32
[1] proc `/`(x, y: int): float

expression: inNanoseconds(t2 - t1) / 1000
'''
"""

import std/monotimes
from times import inNanoseconds

let t1 = getMonotime()
let result = 1 + 2
let t2 = getMonotime()
echo "Elapsed: ", (t2 - t1).inNanoseconds / 1_000