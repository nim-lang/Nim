discard """
  output: '''
a -> 2
a <- 2
'''
"""

import jsffi

var a = JsAssoc[cstring, int]{a: 2}

for z, b in a:
  echo z, " -> ", b

proc f =
  var a = JsAssoc[cstring, int]{a: 2}

  for z, b in a:
    echo z, " <- ", b

f()
