# Test: IndexDefect - Most Common Runtime Error
# WHY IT MATTERS: Index errors are the #1 source of crashes in Nim programs
# Developers need to IMMEDIATELY see:
# - What index was accessed
# - What the valid range is
# - Where the array was created
# - How to fix it

proc getElement(arr: seq[int], idx: int): int =
  result = arr[idx]  # Will crash here

let data = @[1, 2, 3, 4, 5]
echo "Getting element at index 10..."
echo getElement(data, 10)  # CRASH: index 10 not in 0..4

# CURRENT ERROR OUTPUT:
# ===================
# Traceback (most recent call last)
# test_index_defect.nim(15) test_index_defect
# test_index_defect.nim(8) getElement
# Error: unhandled exception: index 10 not in 0 .. 4 [IndexDefect]

# IMPROVED ERROR OUTPUT (Proposed):
# ===================
# Runtime Error: Index Out of Bounds [IndexDefect]
#  --> test_index_defect.nim(8, 12)
#     |
#   8 |   result = arr[idx]
#     |                ^^^ index 10 out of bounds
#     |
# note: array 'arr' has length 5 (valid indices: 0..4)
#       attempted index: 10
#       excess: +5 beyond last valid index
#
# Stack Trace:
#   1. getElement(arr: seq[int], idx: int) at test_index_defect.nim:8
#      Variables: arr = [1, 2, 3, 4, 5], idx = 10, result = 0
#
#   2. main program at test_index_defect.nim:15
#      Variables: data = [1, 2, 3, 4, 5]
#
# help: add bounds checking
#     | proc getElement(arr: seq[int], idx: int): int =
#     |   if idx >= 0 and idx < arr.len:
#     |     return arr[idx]
#     |   raise newException(ValueError, "Index out of bounds")
#
# help: use safe accessor (returns Option)
#     | echo data.get(10)  # returns none()
#
# help: use safe accessor with default
#     | echo data.get(10, default = 0)
