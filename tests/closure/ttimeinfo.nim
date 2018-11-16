# bug #2073

import sequtils
import times

# 1
proc f(n: int): DateTime =
  DateTime(year: n, month: mJan, monthday: 1)

echo toSeq(2000 || 2015).map(f)

# 2
echo toSeq(2000 || 2015).map(proc (n: int): DateTime =
  DateTime(year: n, month: mJan, monthday: 1)
)
