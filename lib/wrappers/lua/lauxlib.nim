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
proc getn*(L: PState, n: cint): cint
  # calls lua_objlen
proc setn*(L: PState, t, n: cint)
  # does nothing!
type 
  Treg*{.final.} = object 
    name*: cstring
    func*: CFunction

  Preg* = ptr Treg


{.push callConv: cdecl, dynlib: lua.LIB_NAME.}
{.push importc: "luaL_$1".}

proc openlib*(L: PState, libname: cstring, lr: Preg, nup: cint)
proc register*(L: PState, libname: cstring, lr: Preg)

proc getmetafield*(L: PState, obj: cint, e: cstring): cint
proc callmeta*(L: PState, obj: cint, e: cstring): cint
proc typerror*(L: PState, narg: cint, tname: cstring): cint
proc argerror*(L: PState, numarg: cint, extramsg: cstring): cint
proc checklstring*(L: PState, numArg: cint, len: ptr int): cstring
proc optlstring*(L: PState, numArg: cint, def: cstring, len: ptr cint): cstring
proc checknumber*(L: PState, numArg: cint): Number
proc optnumber*(L: PState, nArg: cint, def: Number): Number
proc checkinteger*(L: PState, numArg: cint): Integer
proc optinteger*(L: PState, nArg: cint, def: Integer): Integer
proc checkstack*(L: PState, sz: cint, msg: cstring)
proc checktype*(L: PState, narg, t: cint)

proc checkany*(L: PState, narg: cint)
proc newmetatable*(L: PState, tname: cstring): cint

proc checkudata*(L: PState, ud: cint, tname: cstring): Pointer
proc where*(L: PState, lvl: cint)
proc error*(L: PState, fmt: cstring): cint{.varargs.}
proc checkoption*(L: PState, narg: cint, def: cstring, lst: cstringArray): cint

proc unref*(L: PState, t, theref: cint)
proc loadfile*(L: PState, filename: cstring): cint
proc loadbuffer*(L: PState, buff: cstring, size: cint, name: cstring): cint
proc loadstring*(L: PState, s: cstring): cint
proc newstate*(): PState

{.pop.}
proc reference*(L: PState, t: cint): cint{.importc: "luaL_ref".}

{.pop.}

proc open*(): PState
  # compatibility; moved from unit lua to lauxlib because it needs luaL_newstate
  #
  #** ===============================================================
  #** some useful macros
  #** ===============================================================
  #
proc argcheck*(L: PState, cond: bool, numarg: cint, extramsg: cstring)
proc checkstring*(L: PState, n: cint): cstring
proc optstring*(L: PState, n: cint, d: cstring): cstring
proc checkint*(L: PState, n: cint): cint
proc checklong*(L: PState, n: cint): clong
proc optint*(L: PState, n: cint, d: float64): cint
proc optlong*(L: PState, n: cint, d: float64): clong
proc dofile*(L: PState, filename: cstring): cint
proc dostring*(L: PState, str: cstring): cint
proc getmetatable*(L: PState, tname: cstring)
  # not translated:
  # #define luaL_opt(L,f,n,d)  (lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))
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
    lvl*: cint                 # number of strings in the stack (level) 
    L*: PState
    buffer*: array[0..BUFFERSIZE - 1, Char] # warning: see note above about LUAL_BUFFERSIZE
  
  PBuffer* = ptr Buffer

proc addchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
  # compatibility only (alias for luaL_addchar) 
proc putchar*(B: PBuffer, c: Char)
  # warning: see note above about LUAL_BUFFERSIZE
proc addsize*(B: PBuffer, n: cint)

{.push callConv: cdecl, dynlib: lua.LIB_NAME, importc: "luaL_$1".}
proc buffinit*(L: PState, B: PBuffer)
proc prepbuffer*(B: PBuffer): cstring
proc addlstring*(B: PBuffer, s: cstring, L: cint)
proc addstring*(B: PBuffer, s: cstring)
proc addvalue*(B: PBuffer)
proc pushresult*(B: PBuffer)
proc gsub*(L: PState, s, p, r: cstring): cstring
proc findtable*(L: PState, idx: cint, fname: cstring, szhint: cint): cstring
  # compatibility with ref system 
  # pre-defined references 
{.pop.}

const 
  NOREF* = - 2
  REFNIL* = - 1

proc unref*(L: PState, theref: cint)
proc getref*(L: PState, theref: cint)
  #
  #** Compatibility macros and functions
  #
# implementation

proc pushstring(L: PState, s: string) = 
  pushlstring(L, cstring(s), s.len.cint)

proc getn(L: PState, n: cint): cint = 
  Result = objlen(L, n)

proc setn(L: PState, t, n: cint) = 
  # does nothing as this operation is deprecated
  nil

proc open(): PState = 
  Result = newstate()

proc dofile(L: PState, filename: cstring): cint = 
  Result = loadfile(L, filename)
  if Result == 0: Result = pcall(L, 0, MULTRET, 0)
  
proc dostring(L: PState, str: cstring): cint = 
  Result = loadstring(L, str)
  if Result == 0: Result = pcall(L, 0, MULTRET, 0)
  
proc getmetatable(L: PState, tname: cstring) = 
  getfield(L, REGISTRYINDEX, tname)

proc argcheck(L: PState, cond: bool, numarg: cint, extramsg: cstring) = 
  if not cond: 
    discard argerror(L, numarg, extramsg)

proc checkstring(L: PState, n: cint): cstring = 
  Result = checklstring(L, n, nil)

proc optstring(L: PState, n: cint, d: cstring): cstring = 
  Result = optlstring(L, n, d, nil)

proc checkint(L: PState, n: cint): cint = 
  Result = cint(checknumber(L, n))

proc checklong(L: PState, n: cint): clong = 
  Result = int32(ToInt(checknumber(L, n)))

proc optint(L: PState, n: cint, d: float64): cint = 
  Result = optnumber(L, n, d).cint

proc optlong(L: PState, n: cint, d: float64): clong = 
  Result = int32(ToInt(optnumber(L, n, d)))

proc addchar(B: PBuffer, c: Char) = 
  if cast[int](addr((B.p))) < (cast[int](addr((B.buffer[0]))) + BUFFERSIZE): 
    discard prepbuffer(B)
  B.p[1] = c
  B.p = cast[cstring](cast[int](B.p) + 1)

proc putchar(B: PBuffer, c: Char) = 
  addchar(B, c)

proc addsize(B: PBuffer, n: cint) = 
  B.p = cast[cstring](cast[int](B.p) + n)

proc unref(L: PState, theref: cint) = 
  unref(L, REGISTRYINDEX, theref)

proc getref(L: PState, theref: cint) = 
  rawgeti(L, REGISTRYINDEX, theref)
