macro exportedMacro*(x: untyped): untyped = x
macro exportedMacroWithBlock*(x: untyped): untyped =
  block:
    let y = x
    y
