discard """
  output: "1"
"""

type
  TMyTuple = tuple[a, b: int]

proc indexOf*(t: typedesc, name: string): int =
  ## takes a tuple and looks for the field by name.
  ## returs index of that field.
  var
    d: t
    i = 0
  for n, x in fieldPairs(d):
    if n == name: return i
    i.inc
  raise newException(EInvalidValue, "No field " & name & " in type " & 
    astToStr(t))

echo TMyTuple.indexOf("b")

