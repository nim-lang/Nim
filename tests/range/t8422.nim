discard """
  targets: "c js"
  output: '''
3
1
3
c
caught
caught
'''
"""

# bug #8422: `succ` and `pred` check the range of a subrange type
type BelowFive = range[0 .. 4]
var health: BelowFive = 0
health = health.succ(3)
echo health
health = health.pred(2)
echo health
const c = BelowFive(1).succ(2)
echo c
var r: range['a'..'f'] = 'b'
echo r.succ
try:
  health = health.succ(100)
  echo health
except RangeDefect:
  echo "caught"
try:
  health = health.pred(5)
  echo health
except RangeDefect:
  echo "caught"

