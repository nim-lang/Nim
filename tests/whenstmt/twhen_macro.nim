import macros

discard """
  output: '''
when - test
'''
"""

# test that when stmt works from within a macro

macro output(s: string, xs: varargs[untyped]): auto =
  result = quote do:
    when compiles(`s`):
      "when - " & `s`
    elif compiles(`s`):
      "elif - " & `s`
      # should never get here so this should not break
      broken.xs
    else:
      "else - " & `s`
      # should never get here so this should not break
      more.broken.xs

echo output("test")