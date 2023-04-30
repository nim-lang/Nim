discard """
  output: '''
not deprecated
not error
'''
"""

# issue #21724

block: # deprecated
  {.push warningAsError[Deprecated]: on.}
  type
    SomeObj = object
      hey: bool
  proc hey() {.deprecated: "Shouldn't use this".} = echo "hey"
  proc gen(o: auto) =
    doAssert not compiles(o.hey())
    if o.hey:
      echo "not deprecated"
  gen(SomeObj(hey: true))
  {.pop.}
block: # error
  type
    SomeObj = object
      hey: bool
  proc hey() {.error: "Shouldn't use this".} = echo "hey"
  proc gen(o: auto) =
    doAssert not compiles(o.hey())
    if o.hey:
      echo "not error"
  gen(SomeObj(hey: true))
