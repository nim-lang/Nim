discard """
  cmd: "nim c --hints:off --skipParentCfg $file"
  errormsg: "type mismatch"
  nimout: '''
tconcisetypemismatch.nim(23, 49) Error: type mismatch
Expression: int64(inNanoseconds(t2 - t1)) / 100.5
  [1] int64(inNanoseconds(t2 - t1)): int64
  [2] 100.5: float64

Expected one of (first mismatch at position [#]):
[1] proc `/`(x, y: float): float
[1] proc `/`(x, y: float32): float32
[2] proc `/`(x, y: int): float
'''
"""

import std/monotimes
from times import inNanoseconds

let t1 = getMonotime()
let result = 1 + 2
let t2 = getMonotime()
echo "Elapsed: ", (t2 - t1).inNanoseconds.int64 / 100.5