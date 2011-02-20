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

proc pushstring*(L: PState, s: string)
  # compatibilty macros
proc getn*(L: PState, n: int): int
  # calls lua_objlen
proc setn*(L: PState, t, n: int)
  # does nothing!
type 
  Treg*{.final.} = object 
    name*: cstring
    func*: CFunction

  Preg* = ptr Treg

proc openlib*(L: PState, libname: cstring, lr: Preg, nup: int){.cdecl, 
    dynlib: lua.LIB_NAME, importc: "luaL_openlib".}
proc register*(L: PState, libname: cstring, lr: Preg){.cdecl, 
    dynlib: lua.LIB_NAME, importc: "luaL_register".}
proc getmetafield*(L: PState, obj: int, e: cstring): int{.cdecl, 
    dynlib: lua.LIB_NAME, importc: "luaL_getmetafield".}
proc callmeta*(L: PState, obj: int, e: cstring): int{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_callmeta".}
proc typerror*(L: PState, narg: int, tname: cstring): int{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_typerror".}
proc argerror*(L: PState, numarg: int, extramsg: cstring): int{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_argerror".}
proc checklstring*(L: PState, numArg: int, len: ptr int): cstring{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_checklstring".}
proc optlstring*(L: PState, numArg: int, def: cstring, len: ptr int): cstring{.
    cdecl, dynlib: LIB_NAME, importc: "luaL_optlstring".}
proc checknumber*(L: PState, numArg: int): Number{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_checknumber".}
proc optnumber*(L: PState, nArg: int, def: Number): Number{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_optnumber".}
proc checkinteger*(L: PState, numArg: int): Integer{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_checkinteger".}
proc optinteger*(L: PState, nArg: int, def: Integer): Integer{.
    cdecl, dynlib: LIB_NAME, importc: "luaL_optinteger".}
proc checkstack*(L: PState, sz: int, msg: cstring){.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_checkstack".}
proc checktype*(L: PState, narg, t: int){.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_checktype".}
proc checkany*(L: PState, narg: int){.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_checkany".}
proc newmetatable*(L: PState, tname: cstring): int{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_newmetatable".}
proc checkudata*(L: PState, ud: int, tname: cstring): Pointer{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_checkudata".}
proc where*(L: PState, lvl: int){.cdecl, dynlib: LIB_NAME, 
                                      importc: "luaL_where".}
proc error*(L: PState, fmt: cstring): int{.cdecl, varargs, 
    dynlib: LIB_NAME, importc: "luaL_error".}
proc checkoption*(L: PState, narg: int, def: cstring, lst: cstringArray): int{.
    cdecl, dynlib: LIB_NAME, importc: "luaL_checkoption".}
proc reference*(L: PState, t: int): int{.cdecl, dynlib: LIB_NAME, 
                                       importc: "luaL_ref".}
proc unref*(L: PState, t, theref: int){.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_unref".}
proc loadfile*(L: PState, filename: cstring): int{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_loadfile".}
proc loadbuffer*(L: PState, buff: cstring, size: int, name: cstring): int{.
    cdecl, dynlib: LIB_NAME, importc: "luaL_loadbuffer".}
proc loadstring*(L: PState, s: cstring): int{.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_loadstring".}
proc newstate*(): PState{.cdecl, dynlib: LIB_NAME, 
                              importc: "luaL_newstate".}
proc open*(): PState
  # compatibility; moved from unit lua to lauxlib because it needs luaL_newstate
  #
  #** ===============================================================
  #** some useful macros
  #** ===============================================================
  #
proc argcheck*(L: PState, cond: bool, numarg: int, extramsg: cstring)
proc checkstring*(L: PState, n: int): cstring
proc optstring*(L: PState, n: int, d: cstring): cstring
proc checkint*(L: PState, n: int): int
proc checklong*(L: PState, n: int): int32
proc optint*(L: PState, n: int, d: float64): int
proc optlong*(L: PState, n: int, d: float64): int32
proc dofile*(L: PState, filename: cstring): int
proc dostring*(L: PState, str: cstring): int
proc getmetatable*(L: PState, tname: cstring)
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
    L*: PState
    buffer*: array[0..BUFFERSIZE - 1, Char] # warning: see note above about LUAL_BUFFERSIZE
  
  PBuffer* = ptr Buffer

proc addchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
  # compatibility only (alias for luaL_addchar) 
proc putchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
proc addsize*(B: PBuffer, n: int)
proc buffinit*(L: PState, B: PBuffer){.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_buffinit".}
proc prepbuffer*(B: PBuffer): cstring{.cdecl, dynlib: LIB_NAME, 
                                       importc: "luaL_prepbuffer".}
proc addlstring*(B: PBuffer, s: cstring, L: int){.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_addlstring".}
proc addstring*(B: PBuffer, s: cstring){.cdecl, dynlib: LIB_NAME, 
    importc: "luaL_addstring".}
proc addvalue*(B: PBuffer){.cdecl, dynlib: LIB_NAME, 
                            importc: "luaL_addvalue".}
proc pushresult*(B: PBuffer){.cdecl, dynlib: LIB_NAME, 
                              importc: "luaL_pushresult".}
proc gsub*(L: PState, s, p, r: cstring): cstring{.cdecl, 
    dynlib: LIB_NAME, importc: "luaL_gsub".}
proc findtable*(L: PState, idx: int, fname: cstring, szhint: int): cstring{.
    cdecl, dynlib: LIB_NAME, importc: "luaL_findtable".}
  # compatibility with ref system 
  # pre-defined references 
const 
  NOREF* = - 2
  REFNIL* = - 1

proc unref*(L: PState, theref: int)
proc getref*(L: PState, theref: int)
  #
  #** Compatibility macros and functions
  #
# implementation

proc pushstring(L: PState, s: string) = 
  pushlstring(L, cstring(s), len(s))

proc getn(L: PState, n: int): int = 
  Result = objlen(L, n)

proc setn(L: PState, t, n: int) = 
  # does nothing as this operation is deprecated
  nil

proc open(): PState = 
  Result = newstate()

proc dofile(L: PState, filename: cstring): int = 
  Result = loadfile(L, filename)
  if Result == 0: Result = pcall(L, 0, MULTRET, 0)
  
proc dostring(L: PState, str: cstring): int = 
  Result = loadstring(L, str)
  if Result == 0: Result = pcall(L, 0, MULTRET, 0)
  
proc getmetatable(L: PState, tname: cstring) = 
  getfield(L, REGISTRYINDEX, tname)

proc argcheck(L: PState, cond: bool, numarg: int, extramsg: cstring) = 
  if not cond: 
    discard argerror(L, numarg, extramsg)

proc checkstring(L: PState, n: int): cstring = 
  Result = checklstring(L, n, nil)

proc optstring(L: PState, n: int, d: cstring): cstring = 
  Result = optlstring(L, n, d, nil)

proc checkint(L: PState, n: int): int = 
  Result = toInt(checknumber(L, n))

proc checklong(L: PState, n: int): int32 = 
  Result = int32(ToInt(checknumber(L, n)))

proc optint(L: PState, n: int, d: float64): int = 
  Result = int(ToInt(optnumber(L, n, d)))

proc optlong(L: PState, n: int, d: float64): int32 = 
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

proc unref(L: PState, theref: int) = 
  unref(L, REGISTRYINDEX, theref)

proc getref(L: PState, theref: int) = 
  rawgeti(L, REGISTRYINDEX, theref)
