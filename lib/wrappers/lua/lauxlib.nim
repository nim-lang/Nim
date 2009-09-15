#*****************************************************************************
# *                                                                            *
# *  File:        lauxlib.pas                                                  *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Lua auxiliary library                                        *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lauxlib.h,v 1.59 2003/03/18 12:25:32 roberto Exp $
#** Auxiliary functions for building Lua libraries
#** See Copyright Notice in lua.h
#
#
#** Translated to pascal by Lavergne Thomas
#** Notes :
#**    - Pointers type was prefixed with 'P'
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#

import lua

proc lua_pushstring*(L: Plua_State, s: string)
  # compatibilty macros
proc luaL_getn*(L: Plua_State, n: int): int
  # calls lua_objlen
proc luaL_setn*(L: Plua_State, t, n: int)
  # does nothing!
type 
  TLuaL_reg*{.final.} = object 
    name*: cstring
    func*: lua_CFunction

  PluaL_reg* = ptr TLuaL_reg

proc luaL_openlib*(L: Plua_State, libname: cstring, lr: PluaL_reg, nup: int){.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_register*(L: Plua_State, libname: cstring, lr: PluaL_reg){.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_getmetafield*(L: Plua_State, obj: int, e: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_callmeta*(L: Plua_State, obj: int, e: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_typerror*(L: Plua_State, narg: int, tname: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_argerror*(L: Plua_State, numarg: int, extramsg: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_checklstring*(L: Plua_State, numArg: int, l_: Psize_t): cstring{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_optlstring*(L: Plua_State, numArg: int, def: cstring, l_: Psize_t): cstring{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_checknumber*(L: Plua_State, numArg: int): lua_Number{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_optnumber*(L: Plua_State, nArg: int, def: lua_Number): lua_Number{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_checkinteger*(L: Plua_State, numArg: int): lua_Integer{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_optinteger*(L: Plua_State, nArg: int, def: lua_Integer): lua_Integer{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_checkstack*(L: Plua_State, sz: int, msg: cstring){.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_checktype*(L: Plua_State, narg, t: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_checkany*(L: Plua_State, narg: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_newmetatable*(L: Plua_State, tname: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_checkudata*(L: Plua_State, ud: int, tname: cstring): Pointer{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_where*(L: Plua_State, lvl: int){.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_error*(L: Plua_State, fmt: cstring): int{.cdecl, varargs, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_checkoption*(L: Plua_State, narg: int, def: cstring, lst: cstringArray): int{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_ref*(L: Plua_State, t: int): int{.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_unref*(L: Plua_State, t, theref: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_loadfile*(L: Plua_State, filename: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_loadbuffer*(L: Plua_State, buff: cstring, size: size_t, name: cstring): int{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_loadstring*(L: Plua_State, s: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_newstate*(): Plua_State{.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc lua_open*(): Plua_State
  # compatibility; moved from unit lua to lauxlib because it needs luaL_newstate
  #
  #** ===============================================================
  #** some useful macros
  #** ===============================================================
  #
proc luaL_argcheck*(L: Plua_State, cond: bool, numarg: int, extramsg: cstring)
proc luaL_checkstring*(L: Plua_State, n: int): cstring
proc luaL_optstring*(L: Plua_State, n: int, d: cstring): cstring
proc luaL_checkint*(L: Plua_State, n: int): int
proc luaL_checklong*(L: Plua_State, n: int): int32
proc luaL_optint*(L: Plua_State, n: int, d: float64): int
proc luaL_optlong*(L: Plua_State, n: int, d: float64): int32
proc luaL_typename*(L: Plua_State, i: int): cstring
proc lua_dofile*(L: Plua_State, filename: cstring): int
proc lua_dostring*(L: Plua_State, str: cstring): int
proc lua_Lgetmetatable*(L: Plua_State, tname: cstring)
  # not translated:
  # #define luaL_opt(L,f,n,d)	(lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))
  #
  #** =======================================================
  #** Generic Buffer manipulation
  #** =======================================================
  #
const                         # note: this is just arbitrary, as it related to the BUFSIZ defined in stdio.h ...
  LUAL_BUFFERSIZE* = 4096

type 
  luaL_Buffer*{.final.} = object 
    p*: cstring               # current position in buffer 
    lvl*: int                 # number of strings in the stack (level) 
    L*: Plua_State
    buffer*: array[0..LUAL_BUFFERSIZE - 1, Char] # warning: see note above about LUAL_BUFFERSIZE
  
  PluaL_Buffer* = ptr luaL_Buffer

proc luaL_addchar*(B: PluaL_Buffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
  # compatibility only (alias for luaL_addchar) 
proc luaL_putchar*(B: PluaL_Buffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
proc luaL_addsize*(B: PluaL_Buffer, n: int)
proc luaL_buffinit*(L: Plua_State, B: PluaL_Buffer){.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_prepbuffer*(B: PluaL_Buffer): cstring{.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_addlstring*(B: PluaL_Buffer, s: cstring, L: size_t){.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_addstring*(B: PluaL_Buffer, s: cstring){.cdecl, dynlib: LUA_LIB_NAME, 
    importc.}
proc luaL_addvalue*(B: PluaL_Buffer){.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_pushresult*(B: PluaL_Buffer){.cdecl, dynlib: LUA_LIB_NAME, importc.}
proc luaL_gsub*(L: Plua_State, s, p, r: cstring): cstring{.cdecl, 
    dynlib: LUA_LIB_NAME, importc.}
proc luaL_findtable*(L: Plua_State, idx: int, fname: cstring, szhint: int): cstring{.
    cdecl, dynlib: LUA_LIB_NAME, importc.}
  # compatibility with ref system 
  # pre-defined references 
const 
  LUA_NOREF* = - 2
  LUA_REFNIL* = - 1

proc lua_unref*(L: Plua_State, theref: int)
proc lua_getref*(L: Plua_State, theref: int)
  #
  #** Compatibility macros and functions
  #

# implementation

proc lua_pushstring(L: Plua_State, s: string) = 
  lua_pushlstring(L, cstring(s), len(s))

proc luaL_getn(L: Plua_State, n: int): int = 
  Result = lua_objlen(L, n)

proc luaL_setn(L: Plua_State, t, n: int) = 
  # does nothing as this operation is deprecated
  nil
  
proc lua_open(): Plua_State = 
  Result = luaL_newstate()

proc luaL_typename(L: Plua_State, i: int): cstring = 
  Result = lua_typename(L, lua_type(L, i))

proc lua_dofile(L: Plua_State, filename: cstring): int = 
  Result = luaL_loadfile(L, filename)
  if Result == 0: Result = lua_pcall(L, 0, LUA_MULTRET, 0)
  
proc lua_dostring(L: Plua_State, str: cstring): int = 
  Result = luaL_loadstring(L, str)
  if Result == 0: Result = lua_pcall(L, 0, LUA_MULTRET, 0)
  
proc lua_Lgetmetatable(L: Plua_State, tname: cstring) = 
  lua_getfield(L, LUA_REGISTRYINDEX, tname)

proc luaL_argcheck(L: Plua_State, cond: bool, numarg: int, extramsg: cstring) = 
  if not cond:
    discard luaL_argerror(L, numarg, extramsg)
  
proc luaL_checkstring(L: Plua_State, n: int): cstring = 
  Result = luaL_checklstring(L, n, nil)

proc luaL_optstring(L: Plua_State, n: int, d: cstring): cstring = 
  Result = luaL_optlstring(L, n, d, nil)

proc luaL_checkint(L: Plua_State, n: int): int = 
  Result = toInt(luaL_checknumber(L, n))

proc luaL_checklong(L: Plua_State, n: int): int32 = 
  Result = int32(ToInt(luaL_checknumber(L, n)))

proc luaL_optint(L: Plua_State, n: int, d: float64): int = 
  Result = int(ToInt(luaL_optnumber(L, n, d)))

proc luaL_optlong(L: Plua_State, n: int, d: float64): int32 = 
  Result = int32(ToInt(luaL_optnumber(L, n, d)))

proc luaL_addchar(B: PluaL_Buffer, c: Char) = 
  if cast[int](addr((B.p))) < (cast[int](addr((B.buffer[0]))) + LUAL_BUFFERSIZE): 
    discard luaL_prepbuffer(B)
  B.p[1] = c
  B.p = cast[cstring](cast[int](B.p) + 1)

proc luaL_putchar(B: PluaL_Buffer, c: Char) = 
  luaL_addchar(B, c)

proc luaL_addsize(B: PluaL_Buffer, n: int) = 
  B.p = cast[cstring](cast[int](B.p) + n)

proc lua_unref(L: Plua_State, theref: int) = 
  luaL_unref(L, LUA_REGISTRYINDEX, theref)

proc lua_getref(L: Plua_State, theref: int) = 
  lua_rawgeti(L, LUA_REGISTRYINDEX, theref)
