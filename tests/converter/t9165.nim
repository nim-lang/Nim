type ustring = distinct string

converter toUString(s: string): ustring = ustring(s)
converter toString(s: ustring): string = string(s)

proc `[]=`*(s: var ustring, slice: Slice[int], replacement: ustring) {.inline.} =
  s = replacement

var s = ustring("123")
s[1..2] = "3"
doAssert s == "3"