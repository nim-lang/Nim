discard """
  action: "run"
"""

type ObjType = object
    value: int

converter toCasableVar(obj: ObjType): int =
    obj.value

var myObj = ObjType(
    value: 5
)

case myObj:
  of 5: discard
  else: doAssert false
