discard """
  action: "run"
"""

import jsffi

# Can catch JS exceptions
try:
  asm """throw new Error('a new error');"""
except JsError as e:
  doAssert e.message == "a new error"
except:
  doAssert false

# Can distinguish different exceptions
try:
  asm """JSON.parse(';;');"""
except JsEvalError:
  doAssert false
except JsSyntaxError as se:
  doAssert se.message == "Unexpected token ; in JSON at position 0"
except JsError as e:
  doAssert false

# Can catch parent exception
try:
  asm """throw new SyntaxError();"""
except JsError as e:
  discard
except:
  doAssert false
