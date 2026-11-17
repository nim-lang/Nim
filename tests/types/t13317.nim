discard """
  targets: "c js"
  output: '''
string
int
1 float a
'''
"""

# bug #13317: a `varargs[typedesc]` parameter makes a proc generic and does
# not reach the backend
proc p(args: varargs[typedesc]) = echo typeof(args[0])
p(string)
p(int, int)
proc q(x: int, args: varargs[typedesc], y: string) =
  echo x, " ", typeof(args[0]), " ", y
q(1, float, "a")
