discard """
  outputsub: "unhandled exception: index 10000 not in 0 .. 0 [IndexDefect]"
  exitcode: 1
  joinable: false
"""

var s = ['a']
let z = s[10000] == 'a'
echo z