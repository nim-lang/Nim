discard """
  cmd:      "nim c -r --debugger:native --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""

for i in 1 || 200:
  discard i
