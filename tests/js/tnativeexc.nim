type
  JsError {.importc: "Error".} = object of JsRoot
  JsSyntaxError {.importc: "SyntaxError".} = object of JsError

try:
  asm """throw new Error('a new error');"""
except JsSyntaxError as se: doAssert false
except JsError as e:        doAssert true

try:
  asm """JSON.parse(';;');"""
except JsSyntaxError as se: doAssert true
except JsError as e:        doAssert false
