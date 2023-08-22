discard """
  output: '''Success'''
"""

const romanNumbers1 =
    [
    ("M", 1000), ("D", 500), ("C", 100),
    ("L", 50), ("X", 10), ("V", 5), ("I", 1) ]

const romanNumbers2 =
    [
    ("M", 1000), ("D", 500), ("C", 100),
    ("L", 50), ("X", 10), ("V", 5), ("I", 1)
    ]

const romanNumbers3 =
  [
    ("M", 1000), ("D", 500), ("C", 100),
    ("L", 50), ("X", 10), ("V", 5), ("I", 1)
  ]

const romanNumbers4 = [
    ("M", 1000), ("D", 500), ("C", 100),
    ("L", 50), ("X", 10), ("V", 5), ("I", 1)
    ]


proc main =
  var j = 0
  while j < 10:
    inc(j);

  if j == 5: doAssert false

var j = 0
while j < 10:
  inc(j);

if j == 5: doAssert false

main()
echo "Success"
