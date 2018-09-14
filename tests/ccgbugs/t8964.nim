discard """
  targets: "c cpp"
"""

from json import JsonParsingError
import marshal

const nothing = ""
doAssertRaises(JsonParsingError):
  var bar = marshal.to[int](nothing)
