discard """
  matrix: "--mm:refc; --mm:orc"
  output: "ok"
"""

# bug #26440: `setLenUninit` must keep the spare capacity of a grown string,
# otherwise growing it step by step reallocates every time (quadratic).

var s: string
var reallocs = 0
var last = s.capacity
while s.len < 1_000_000:
  s.setLenUninit(s.len + 1000)
  if s.capacity != last:
    inc reallocs
    last = s.capacity
doAssert s.capacity > s.len
doAssert reallocs < 50, $reallocs

s.setLenUninit(10)
doAssert s.len == 10
s.setLenUninit(0)
doAssert s.len == 0
echo "ok"
