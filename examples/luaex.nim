# Embedds Lua into a Nimrod application

import
  lua, lualib, lauxlib

const
  code = """
print 'hi'
"""

var L = newstate()
openlibs(L)
discard loadbuffer(L, code, code.len, "line") 
discard pcall(L, 0, 0, 0)

