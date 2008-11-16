#*****************************************************************************
# *                                                                            *
# *  File:        lualib.pas                                                   *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Standard Lua libraries                                       *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lualib.h,v 1.28 2003/03/18 12:24:26 roberto Exp $
#** Lua standard libraries
#** See Copyright Notice in lua.h
#
#
#** Translated to pascal by Lavergne Thomas
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#

import "lib/base/lua/lua"

const 
  LUA_COLIBNAME* = "coroutine"
  LUA_TABLIBNAME* = "table"
  LUA_IOLIBNAME* = "io"
  LUA_OSLIBNAME* = "os"
  LUA_STRLINAME* = "string"
  LUA_MATHLIBNAME* = "math"
  LUA_DBLIBNAME* = "debug"
  LUA_LOADLIBNAME* = "package"

proc luaopen_base*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaopen_table*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaopen_io*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaopen_string*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaopen_math*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaopen_debug*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaopen_package*(L: Plua_State): cint{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_openlibs*(L: Plua_State){.cdecl, dynlib: LUA_LIB_NAME, importc.}
  # compatibility code 
proc lua_baselibopen*(L: Plua_State): Bool
proc lua_tablibopen*(L: Plua_State): Bool
proc lua_iolibopen*(L: Plua_State): Bool
proc lua_strlibopen*(L: Plua_State): Bool
proc lua_mathlibopen*(L: Plua_State): Bool
proc lua_dblibopen*(L: Plua_State): Bool
# implementation

proc lua_baselibopen(L: Plua_State): Bool = 
  Result = luaopen_base(L) != 0'i32

proc lua_tablibopen(L: Plua_State): Bool = 
  Result = luaopen_table(L) != 0'i32

proc lua_iolibopen(L: Plua_State): Bool = 
  Result = luaopen_io(L) != 0'i32

proc lua_strlibopen(L: Plua_State): Bool = 
  Result = luaopen_string(L) != 0'i32

proc lua_mathlibopen(L: Plua_State): Bool = 
  Result = luaopen_math(L) != 0'i32

proc lua_dblibopen(L: Plua_State): Bool = 
  Result = luaopen_debug(L) != 0'i32
