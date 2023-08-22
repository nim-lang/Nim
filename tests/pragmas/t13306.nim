discard """
  errormsg: "'testEpo' can have side effects"
  line: 8
"""

import times

func testEpo(x: float): float = epochTime() + x

echo testEpo(1.0)
