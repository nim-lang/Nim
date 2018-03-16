discard """
  output: '''false
true
false
[false, false, false]
'''
"""

# bug #7332
# resetLoc generate incorrect memset code
# because of array passed as argument decaying into a pointer

import tables
const tableOfArray = {
    "one": [true, false, false],
    "two": [false, true, false],
    "three": [false, false, true]
}.toTable()
for i in 0..2:
    echo tableOfArray["two"][i]

var seqOfArray = @[
    [true, false, false],
    [false, true, false],
    [false, false, true]
]
proc crashingProc*[B](t: seq[B], index: Natural): B =
    discard
echo seqOfArray.crashingProc(0)
