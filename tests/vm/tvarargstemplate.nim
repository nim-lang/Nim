discard """
  nimout: '''
two
a
b
3
'''
"""

# iterating a `varargs` parameter of a template: `transf` turns the argument
# into an array temporary (confutils' helpOutput)

template t(args: varargs[string]) =
  for arg in args: echo arg

proc count(args: varargs[string]): int =
  for a in args: inc result

static:
  t("two")
  t("a", "b")
  echo count("x", "y", "z")
