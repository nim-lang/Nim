discard """
  cmd: "nim c --hints:off --undef:nimLegacyTypeMismatch $file"
  errormsg: "type mismatch"
  nimout: '''
tconcisetypemismatch.nim(23, 43) Error: type mismatch
Expression: inNanoseconds(t2 - t1) / 1000
  [1] inNanoseconds(t2 - t1): int64
  [2] 1000: int literal(1000)

Expected one of (first mismatch at position [#]):
[1] proc `/`(x, y: float): float
[1] proc `/`(x, y: float32): float32
[1] proc `/`(x, y: int): float
'''
"""

import std/monotimes
from times import inNanoseconds

let t1 = getMonotime()
let result = 1 + 2
let t2 = getMonotime()
echo "Elapsed: ", (t2 - t1).inNanoseconds / 1_000