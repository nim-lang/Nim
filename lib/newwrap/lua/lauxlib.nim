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

import 
  lua

proc lua_pushstring*(L: Plua_State, s: string)
  # compatibilty macros
proc getn*(L: Plua_State, n: int): int
  # calls lua_objlen
proc setn*(L: Plua_State, t, n: int)
  # does nothing!
type 
  Treg*{.final.} = object 
    name*: cstring
    func*: lua_CFunction

  Preg* = ptr Treg

proc openlib*(L: Plua_State, libname: cstring, lr: Preg, nup: int){.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_openlib".}
proc register*(L: Plua_State, libname: cstring, lr: Preg){.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_register".}
proc getmetafield*(L: Plua_State, obj: int, e: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_getmetafield".}
proc callmeta*(L: Plua_State, obj: int, e: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_callmeta".}
proc typerror*(L: Plua_State, narg: int, tname: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_typerror".}
proc argerror*(L: Plua_State, numarg: int, extramsg: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_argerror".}
proc checklstring*(L: Plua_State, numArg: int, l_: Psize_t): cstring{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_checklstring".}
proc optlstring*(L: Plua_State, numArg: int, def: cstring, l_: Psize_t): cstring{.
    cdecl, dynlib: LUA_LIB_NAME, importc: "luaL_optlstring".}
proc checknumber*(L: Plua_State, numArg: int): lua_Number{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_checknumber".}
proc optnumber*(L: Plua_State, nArg: int, def: lua_Number): lua_Number{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_optnumber".}
proc checkinteger*(L: Plua_State, numArg: int): lua_Integer{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_checkinteger".}
proc optinteger*(L: Plua_State, nArg: int, def: lua_Integer): lua_Integer{.
    cdecl, dynlib: LUA_LIB_NAME, importc: "luaL_optinteger".}
proc checkstack*(L: Plua_State, sz: int, msg: cstring){.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_checkstack".}
proc checktype*(L: Plua_State, narg, t: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_checktype".}
proc checkany*(L: Plua_State, narg: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_checkany".}
proc newmetatable*(L: Plua_State, tname: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_newmetatable".}
proc checkudata*(L: Plua_State, ud: int, tname: cstring): Pointer{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_checkudata".}
proc where*(L: Plua_State, lvl: int){.cdecl, dynlib: LUA_LIB_NAME, 
                                      importc: "luaL_where".}
proc error*(L: Plua_State, fmt: cstring): int{.cdecl, varargs, 
    dynlib: LUA_LIB_NAME, importc: "luaL_error".}
proc checkoption*(L: Plua_State, narg: int, def: cstring, lst: cstringArray): int{.
    cdecl, dynlib: LUA_LIB_NAME, importc: "luaL_checkoption".}
proc ref*(L: Plua_State, t: int): int{.cdecl, dynlib: LUA_LIB_NAME, 
                                       importc: "luaL_ref".}
proc unref*(L: Plua_State, t, theref: int){.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_unref".}
proc loadfile*(L: Plua_State, filename: cstring): int{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_loadfile".}
proc loadbuffer*(L: Plua_State, buff: cstring, size: size_t, name: cstring): int{.
    cdecl, dynlib: LUA_LIB_NAME, importc: "luaL_loadbuffer".}
proc loadstring*(L: Plua_State, s: cstring): int{.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_loadstring".}
proc newstate*(): Plua_State{.cdecl, dynlib: LUA_LIB_NAME, 
                              importc: "luaL_newstate".}
proc lua_open*(): Plua_State
  # compatibility; moved from unit lua to lauxlib because it needs luaL_newstate
  #
  #** ===============================================================
  #** some useful macros
  #** ===============================================================
  #
proc argcheck*(L: Plua_State, cond: bool, numarg: int, extramsg: cstring)
proc checkstring*(L: Plua_State, n: int): cstring
proc optstring*(L: Plua_State, n: int, d: cstring): cstring
proc checkint*(L: Plua_State, n: int): int
proc checklong*(L: Plua_State, n: int): int32
proc optint*(L: Plua_State, n: int, d: float64): int
proc optlong*(L: Plua_State, n: int, d: float64): int32
proc typename*(L: Plua_State, i: int): cstring
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
  BUFFERSIZE* = 4096

type 
  Buffer*{.final.} = object 
    p*: cstring               # current position in buffer 
    lvl*: int                 # number of strings in the stack (level) 
    L*: Plua_State
    buffer*: array[0..BUFFERSIZE - 1, Char] # warning: see note above about LUAL_BUFFERSIZE
  
  PBuffer* = ptr Buffer

proc addchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
  # compatibility only (alias for luaL_addchar) 
proc putchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
proc addsize*(B: PBuffer, n: int)
proc buffinit*(L: Plua_State, B: PBuffer){.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_buffinit".}
proc prepbuffer*(B: PBuffer): cstring{.cdecl, dynlib: LUA_LIB_NAME, 
                                       importc: "luaL_prepbuffer".}
proc addlstring*(B: PBuffer, s: cstring, L: size_t){.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_addlstring".}
proc addstring*(B: PBuffer, s: cstring){.cdecl, dynlib: LUA_LIB_NAME, 
    importc: "luaL_addstring".}
proc addvalue*(B: PBuffer){.cdecl, dynlib: LUA_LIB_NAME, 
                            importc: "luaL_addvalue".}
proc pushresult*(B: PBuffer){.cdecl, dynlib: LUA_LIB_NAME, 
                              importc: "luaL_pushresult".}
proc gsub*(L: Plua_State, s, p, r: cstring): cstring{.cdecl, 
    dynlib: LUA_LIB_NAME, importc: "luaL_gsub".}
proc findtable*(L: Plua_State, idx: int, fname: cstring, szhint: int): cstring{.
    cdecl, dynlib: LUA_LIB_NAME, importc: "luaL_findtable".}
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

proc getn(L: Plua_State, n: int): int = 
  Result = lua_objlen(L, n)

proc setn(L: Plua_State, t, n: int) = 
  # does nothing as this operation is deprecated
  nil

proc lua_open(): Plua_State = 
  Result = newstate()

proc typename(L: Plua_State, i: int): cstring = 
  Result = lua_typename(L, lua_type(L, i))

proc lua_dofile(L: Plua_State, filename: cstring): int = 
  Result = loadfile(L, filename)
  if Result == 0: Result = lua_pcall(L, 0, LUA_MULTRET, 0)
  
proc lua_dostring(L: Plua_State, str: cstring): int = 
  Result = loadstring(L, str)
  if Result == 0: Result = lua_pcall(L, 0, LUA_MULTRET, 0)
  
proc lua_Lgetmetatable(L: Plua_State, tname: cstring) = 
  lua_getfield(L, LUA_REGISTRYINDEX, tname)

proc argcheck(L: Plua_State, cond: bool, numarg: int, extramsg: cstring) = 
  if not cond: 
    discard argerror(L, numarg, extramsg)

proc checkstring(L: Plua_State, n: int): cstring = 
  Result = checklstring(L, n, nil)

proc optstring(L: Plua_State, n: int, d: cstring): cstring = 
  Result = optlstring(L, n, d, nil)

proc checkint(L: Plua_State, n: int): int = 
  Result = toInt(checknumber(L, n))

proc checklong(L: Plua_State, n: int): int32 = 
  Result = int32(ToInt(checknumber(L, n)))

proc optint(L: Plua_State, n: int, d: float64): int = 
  Result = int(ToInt(optnumber(L, n, d)))

proc optlong(L: Plua_State, n: int, d: float64): int32 = 
  Result = int32(ToInt(optnumber(L, n, d)))

proc addchar(B: PBuffer, c: Char) = 
  if cast[int](addr((B.p))) < (cast[int](addr((B.buffer[0]))) + BUFFERSIZE): 
    discard prepbuffer(B)
  B.p[1] = c
  B.p = cast[cstring](cast[int](B.p) + 1)

proc putchar(B: PBuffer, c: Char) = 
  addchar(B, c)

proc addsize(B: PBuffer, n: int) = 
  B.p = cast[cstring](cast[int](B.p) + n)

proc lua_unref(L: Plua_State, theref: int) = 
  unref(L, LUA_REGISTRYINDEX, theref)

proc lua_getref(L: Plua_State, theref: int) = 
  lua_rawgeti(L, LUA_REGISTRYINDEX, theref)
