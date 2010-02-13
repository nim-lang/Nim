# Embedds Lua into a Nimrod application

import
  lua, lualib, lauxlib

const
  code = """
print 'hi'
"""

var L = luaL_newstate()
luaL_openlibs(L)
discard luaL_loadbuffer(L, code, code.len, "line") 
discard lua_pcall(L, 0, 0, 0)

