discard """
  nimout: '''
nimvm - when
nimvm - whenElif
nimvm - whenElse
'''
  output: '''
when
whenElif
whenElse
'''
"""

# test both when and when nimvm to ensure proper evaluation

proc compileOrRuntimeProc(s: string) =
  when nimvm:
    echo "nimvm - " & s
  else:
     echo s

template output(s: string) =
  static:
    compileOrRuntimeProc(s)
  compileOrRuntimeProc(s)

when compiles(1):
  output("when")
elif compiles(2):
  output("fail - whenElif")
else:
  output("fail - whenElse")

when compiles(nonexistent):
  output("fail - when")
elif compiles(1):
  output("whenElif")
else:
  output("fail - whenElse")

when compiles(nonexistent):
  output("fail - when")
elif compiles(nonexistent):
  output("fail - whenElif")
else:
  output("whenElse")

