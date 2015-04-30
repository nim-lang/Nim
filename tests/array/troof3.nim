discard """
  errormsg: "invalid context for '^' as len!=high+1 for 'a'"
  line: "8"
"""

var a: array[1..3, string]

echo a[^1]
