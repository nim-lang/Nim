discard """
  output: '''
not deprecated
not deprecated
not error
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
  doAssert not (compiles do:
    proc hey(o: SomeObj) {.deprecated: "Shouldn't use this".} = echo "hey"
    proc gen2(o: auto) =
      if o.hey():
        echo "not deprecated"
    gen2(SomeObj(hey: true)))
  proc hey(o: SomeObj) {.deprecated: "Shouldn't use this".} = echo "hey"
  proc gen3(o: auto) =
    if o.hey:
      echo "not deprecated"
  gen3(SomeObj(hey: true))
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
  doAssert not (compiles do:
    proc hey(o: SomeObj) {.error: "Shouldn't use this".} = echo "hey"
    proc gen2(o: auto) =
      if o.hey():
        echo "not error"
    gen2(SomeObj(hey: true)))
  proc hey(o: SomeObj) {.error: "Shouldn't use this".} = echo "hey"
  proc gen3(o: auto) =
    if o.hey:
      echo "not error"
  gen3(SomeObj(hey: true))
