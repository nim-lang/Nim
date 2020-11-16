discard """
  exitcode: 1
  output: '''
ok1
ok3
ok2
tdefer2.nim(21)          tdefer2
Error: unhandled exception: ok4 [ValueError]
'''
"""




# line 15

echo "ok1"
defer: echo "ok2"
echo "ok3"
if true:
  raise newException(ValueError, "ok4")
echo "ok5"
