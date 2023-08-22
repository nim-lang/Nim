discard """
errormsg: "invalid type: 'SomeNumber' in this context: 'seq[SomeNumber]' for var"
line: 6
"""

var seqwat: seq[SomeNumber] = @[]

proc foo(x: SomeNumber) =
  seqwat.add(x)