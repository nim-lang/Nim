discard """
  errormsg: "value of type 'string' has to be discarded"
  line: 12
"""

proc valid*(): string =
  let x = 317
  "valid"

proc invalid*(): string =
  result = "foo"
  "invalid"
