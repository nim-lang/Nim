# Test: DivByZeroDefect
# WHY IT MATTERS: Division by zero is a classic error that needs clear diagnosis
# Developers need to see:
# - What the dividend and divisor values were
# - Where the zero divisor came from
# - How to add proper validation

proc calculateAverage(total: int, count: int): float =
  result = total.float / count.float  # Will crash if count is 0

proc processScores(scores: seq[int]): float =
  var total = 0
  for score in scores:
    total += score
  return calculateAverage(total, scores.len)

# Edge case: empty list
let emptyScores: seq[int] = @[]
echo "Calculating average of empty list..."
echo processScores(emptyScores)  # CRASH: division by zero

# CURRENT ERROR OUTPUT:
# ===================
# Traceback (most recent call last)
# test_div_zero.nim(17) test_div_zero
# test_div_zero.nim(11) processScores
# test_div_zero.nim(5) calculateAverage
# Error: unhandled exception: over- or underflow [OverflowDefect]

# IMPROVED ERROR OUTPUT (Proposed):
# ===================
# Runtime Error: Division by Zero [DivByZeroDefect]
#  --> test_div_zero.nim(5, 28)
#     |
#   5 |   result = total.float / count.float
#     |            ^^^^^^^^^^^ ----------^^^ divisor is zero
#     |            |           |
#     |            38.0        0.0
#     |
# note: division by zero is undefined
#
# Stack Trace:
#   1. calculateAverage(total: int, count: int) at test_div_zero.nim:5
#      Variables: total = 38, count = 0, result = 0.0
#
#   2. processScores(scores: seq[int]) at test_div_zero.nim:11
#      Variables: scores = [], total = 0
#
#   3. main program at test_div_zero.nim:17
#      Variables: emptyScores = []
#
# pattern detected: dividing by collection length without checking if empty
#
# help: check divisor before dividing
#     | proc calculateAverage(total: int, count: int): float =
#     |   if count == 0:
#     |     return 0.0  # or raise an error
#     |   result = total.float / count.float
#
# help: validate input in processScores
#     | proc processScores(scores: seq[int]): float =
#     |   if scores.len == 0:
#     |     return 0.0  # or NaN, or raise error
#     |   var total = 0
#     |   for score in scores:
#     |     total += score
#     |   return calculateAverage(total, scores.len)
#
# help: use checked division (returns Option)
#     | import std/options
#     | proc checkedDiv(a, b: float): Option[float] =
#     |   if b == 0.0: none(float)
#     |   else: some(a / b)
