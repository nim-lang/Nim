discard """
  nimout: '''nnkClosedSymChoice
nnkSym
'''
"""
# import sequils

import macros

# block testVarargsOverloadedSymbolResolution:
# 
#   echo @[1, 2, 3].map(len)

block testTypedVarargsOverloadedSymbolResolution:

  macro typedVarargs(x: varargs[typed]) =
    echo x[0].kind

  macro typedSingle(x: typed) =
    echo x.kind

  typedSingle(`@`)
  typedVarargs(`@`)
