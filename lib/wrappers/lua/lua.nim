#*****************************************************************************
# *                                                                            *
# *  File:        lua.pas                                                      *
# *  Authors:     TeCGraf           (C headers + actual Lua libraries)         *
# *               Lavergne Thomas   (original translation to Pascal)           *
# *               Bram Kuijvenhoven (update to Lua 5.1.1 for FreePascal)       *
# *  Description: Basic Lua library                                            *
# *                                                                            *
# *****************************************************************************
#
#** $Id: lua.h,v 1.175 2003/03/18 12:31:39 roberto Exp $
#** Lua - An Extensible Extension Language
#** TeCGraf: Computer Graphics Technology Group, PUC-Rio, Brazil
#** http://www.lua.org   mailto:info@lua.org
#** See Copyright Notice at the end of this file
#
#
#** Updated to Lua 5.1.1 by Bram Kuijvenhoven (bram at kuijvenhoven dot net),
#**   Hexis BV (http://www.hexis.nl), the Netherlands
#** Notes:
#**    - Only tested with FPC (FreePascal Compiler)
#**    - Using LuaBinaries styled DLL/SO names, which include version names
#**    - LUA_YIELD was suffixed by '_' for avoiding name collision
#
#
#** Translated to pascal by Lavergne Thomas
#** Notes :
#**    - Pointers type was prefixed with 'P'
#**    - lua_upvalueindex constant was transformed to function
#**    - Some compatibility function was isolated because with it you must have
#**      lualib.
#**    - LUA_VERSION was suffixed by '_' for avoiding name collision.
#** Bug reports :
#**    - thomas.lavergne@laposte.net
#**   In french or in english
#

when defined(useLuajit):
  when defined(MACOSX):
    const
      NAME* = "libluajit.dylib"
      LIB_NAME* = "libluajit.dylib"
  elif defined(UNIX):
    const
      NAME* = "libluajit.so(|.0)"
      LIB_NAME* = "libluajit.so(|.0)"
  else:
    const
      NAME* = "luajit.dll"
      LIB_NAME* = "luajit.dll"
else:
  when defined(MACOSX):
    const
      NAME* = "liblua(|5.2|5.1|5.0).dylib"
      LIB_NAME* = "liblua(|5.2|5.1|5.0).dylib"
  elif defined(UNIX):
    const
      NAME* = "liblua(|5.2|5.1|5.0).so(|.0)"
      LIB_NAME* = "liblua(|5.2|5.1|5.0).so(|.0)"
  else:
    const 
      NAME* = "lua(|5.2|5.1|5.0).dll"
      LIB_NAME* = "lua(|5.2|5.1|5.0).dll"

const 
  VERSION* = "Lua 5.1"
  RELEASE* = "Lua 5.1.1"
  VERSION_NUM* = 501
  COPYRIGHT* = "Copyright (C) 1994-2006 Lua.org, PUC-Rio"
  AUTHORS* = "R. Ierusalimschy, L. H. de Figueiredo & W. Celes"
  # option for multiple returns in `lua_pcall' and `lua_call' 
  MULTRET* = - 1              #
                              #** pseudo-indices
                              #
  REGISTRYINDEX* = - 10000
  ENVIRONINDEX* = - 10001
  GLOBALSINDEX* = - 10002

proc upvalueindex*(I: int): int
const                         # thread status; 0 is OK 
  constYIELD* = 1
  ERRRUN* = 2
  ERRSYNTAX* = 3
  ERRMEM* = 4
  ERRERR* = 5

type 
  PState* = Pointer
  CFunction* = proc (L: PState): int{.cdecl.}

#
#** functions that read/write blocks when loading/dumping Lua chunks
#

type 
  Reader* = proc (L: PState, ud: Pointer, sz: ptr int): cstring{.cdecl.}
  Writer* = proc (L: PState, p: Pointer, sz: int, ud: Pointer): int{.cdecl.}
  Alloc* = proc (ud, theptr: Pointer, osize, nsize: int){.cdecl.}

const 
  TNONE* = - 1
  TNIL* = 0
  TBOOLEAN* = 1
  TLIGHTUSERDATA* = 2
  TNUMBER* = 3
  TSTRING* = 4
  TTABLE* = 5
  TFUNCTION* = 6
  TUSERDATA* = 7
  TTHREAD* = 8                # minimum Lua stack available to a C function 
  MINSTACK* = 20

type                          # Type of Numbers in Lua 
  Number* = float
  Integer* = int

proc newstate*(f: Alloc, ud: Pointer): PState{.cdecl, dynlib: NAME, 
    importc: "lua_newstate".}
proc close*(L: PState){.cdecl, dynlib: NAME, importc: "lua_close".}
proc newthread*(L: PState): PState{.cdecl, dynlib: NAME, 
                                    importc: "lua_newthread".}
proc atpanic*(L: PState, panicf: CFunction): CFunction{.cdecl, dynlib: NAME, 
    importc: "lua_atpanic".}
proc gettop*(L: PState): int{.cdecl, dynlib: NAME, importc: "lua_gettop".}
proc settop*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_settop".}
proc pushvalue*(L: PState, Idx: int){.cdecl, dynlib: NAME, 
                                      importc: "lua_pushvalue".}
proc remove*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_remove".}
proc insert*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_insert".}
proc replace*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_replace".}
proc checkstack*(L: PState, sz: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_checkstack".}
proc xmove*(`from`, `to`: PState, n: int){.cdecl, dynlib: NAME, 
    importc: "lua_xmove".}
proc isnumber*(L: PState, idx: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_isnumber".}
proc isstring*(L: PState, idx: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_isstring".}
proc iscfunction*(L: PState, idx: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_iscfunction".}
proc isuserdata*(L: PState, idx: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_isuserdata".}
proc luatype*(L: PState, idx: int): int{.cdecl, dynlib: NAME, importc: "lua_type".}
proc typename*(L: PState, tp: int): cstring{.cdecl, dynlib: NAME, 
    importc: "lua_typename".}
proc equal*(L: PState, idx1, idx2: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_equal".}
proc rawequal*(L: PState, idx1, idx2: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_rawequal".}
proc lessthan*(L: PState, idx1, idx2: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_lessthan".}
proc tonumber*(L: PState, idx: int): Number{.cdecl, dynlib: NAME, 
    importc: "lua_tonumber".}
proc tointeger*(L: PState, idx: int): Integer{.cdecl, dynlib: NAME, 
    importc: "lua_tointeger".}
proc toboolean*(L: PState, idx: int): cint{.cdecl, dynlib: NAME, 
    importc: "lua_toboolean".}
proc tolstring*(L: PState, idx: int, length: ptr int): cstring{.cdecl, 
    dynlib: NAME, importc: "lua_tolstring".}
proc objlen*(L: PState, idx: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_objlen".}
proc tocfunction*(L: PState, idx: int): CFunction{.cdecl, dynlib: NAME, 
    importc: "lua_tocfunction".}
proc touserdata*(L: PState, idx: int): Pointer{.cdecl, dynlib: NAME, 
    importc: "lua_touserdata".}
proc tothread*(L: PState, idx: int): PState{.cdecl, dynlib: NAME, 
    importc: "lua_tothread".}
proc topointer*(L: PState, idx: int): Pointer{.cdecl, dynlib: NAME, 
    importc: "lua_topointer".}
proc pushnil*(L: PState){.cdecl, dynlib: NAME, importc: "lua_pushnil".}
proc pushnumber*(L: PState, n: Number){.cdecl, dynlib: NAME, 
                                        importc: "lua_pushnumber".}
proc pushinteger*(L: PState, n: Integer){.cdecl, dynlib: NAME, 
    importc: "lua_pushinteger".}
proc pushlstring*(L: PState, s: cstring, len: int){.cdecl, dynlib: NAME, 
    importc: "lua_pushlstring".}
proc pushstring*(L: PState, s: cstring){.cdecl, dynlib: NAME, 
    importc: "lua_pushstring".}
proc pushvfstring*(L: PState, fmt: cstring, argp: Pointer): cstring{.cdecl, 
    dynlib: NAME, importc: "lua_pushvfstring".}
proc pushfstring*(L: PState, fmt: cstring): cstring{.cdecl, varargs, 
    dynlib: NAME, importc: "lua_pushfstring".}
proc pushcclosure*(L: PState, fn: CFunction, n: int){.cdecl, dynlib: NAME, 
    importc: "lua_pushcclosure".}
proc pushboolean*(L: PState, b: cint){.cdecl, dynlib: NAME, 
                                       importc: "lua_pushboolean".}
proc pushlightuserdata*(L: PState, p: Pointer){.cdecl, dynlib: NAME, 
    importc: "lua_pushlightuserdata".}
proc pushthread*(L: PState){.cdecl, dynlib: NAME, importc: "lua_pushthread".}
proc gettable*(L: PState, idx: int){.cdecl, dynlib: NAME, 
                                     importc: "lua_gettable".}
proc getfield*(L: Pstate, idx: int, k: cstring){.cdecl, dynlib: NAME, 
    importc: "lua_getfield".}
proc rawget*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_rawget".}
proc rawgeti*(L: PState, idx, n: int){.cdecl, dynlib: NAME, 
                                       importc: "lua_rawgeti".}
proc createtable*(L: PState, narr, nrec: int){.cdecl, dynlib: NAME, 
    importc: "lua_createtable".}
proc newuserdata*(L: PState, sz: int): Pointer{.cdecl, dynlib: NAME, 
    importc: "lua_newuserdata".}
proc getmetatable*(L: PState, objindex: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_getmetatable".}
proc getfenv*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_getfenv".}
proc settable*(L: PState, idx: int){.cdecl, dynlib: NAME, 
                                     importc: "lua_settable".}
proc setfield*(L: PState, idx: int, k: cstring){.cdecl, dynlib: NAME, 
    importc: "lua_setfield".}
proc rawset*(L: PState, idx: int){.cdecl, dynlib: NAME, importc: "lua_rawset".}
proc rawseti*(L: PState, idx, n: int){.cdecl, dynlib: NAME, 
                                       importc: "lua_rawseti".}
proc setmetatable*(L: PState, objindex: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_setmetatable".}
proc setfenv*(L: PState, idx: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_setfenv".}
proc call*(L: PState, nargs, nresults: int){.cdecl, dynlib: NAME, 
    importc: "lua_call".}
proc pcall*(L: PState, nargs, nresults, errf: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_pcall".}
proc cpcall*(L: PState, func: CFunction, ud: Pointer): int{.cdecl, dynlib: NAME, 
    importc: "lua_cpcall".}
proc load*(L: PState, reader: Reader, dt: Pointer, chunkname: cstring): int{.
    cdecl, dynlib: NAME, importc: "lua_load".}
proc dump*(L: PState, writer: Writer, data: Pointer): int{.cdecl, dynlib: NAME, 
    importc: "lua_dump".}
proc luayield*(L: PState, nresults: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_yield".}
proc resume*(L: PState, narg: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_resume".}
proc status*(L: PState): int{.cdecl, dynlib: NAME, importc: "lua_status".}
proc gc*(L: PState, what, data: int): int{.cdecl, dynlib: NAME, 
    importc: "lua_gc".}
proc error*(L: PState): int{.cdecl, dynlib: NAME, importc: "lua_error".}
proc next*(L: PState, idx: int): int{.cdecl, dynlib: NAME, importc: "lua_next".}
proc concat*(L: PState, n: int){.cdecl, dynlib: NAME, importc: "lua_concat".}
proc getallocf*(L: PState, ud: ptr Pointer): Alloc{.cdecl, dynlib: NAME, 
    importc: "lua_getallocf".}
proc setallocf*(L: PState, f: Alloc, ud: Pointer){.cdecl, dynlib: NAME, 
    importc: "lua_setallocf".}
#
#** Garbage-collection functions and options
#

const 
  GCSTOP* = 0
  GCRESTART* = 1
  GCCOLLECT* = 2
  GCCOUNT* = 3
  GCCOUNTB* = 4
  GCSTEP* = 5
  GCSETPAUSE* = 6
  GCSETSTEPMUL* = 7

#
#** ===============================================================
#** some useful macros
#** ===============================================================
#

proc pop*(L: PState, n: int)
proc newtable*(L: Pstate)
proc register*(L: PState, n: cstring, f: CFunction)
proc pushcfunction*(L: PState, f: CFunction)
proc strlen*(L: Pstate, i: int): int
proc isfunction*(L: PState, n: int): bool
proc istable*(L: PState, n: int): bool
proc islightuserdata*(L: PState, n: int): bool
proc isnil*(L: PState, n: int): bool
proc isboolean*(L: PState, n: int): bool
proc isthread*(L: PState, n: int): bool
proc isnone*(L: PState, n: int): bool
proc isnoneornil*(L: PState, n: int): bool
proc pushliteral*(L: PState, s: cstring)
proc setglobal*(L: PState, s: cstring)
proc getglobal*(L: PState, s: cstring)
proc tostring*(L: PState, i: int): cstring
#
#** compatibility macros and functions
#

proc getregistry*(L: PState)
proc getgccount*(L: PState): int
type 
  Chunkreader* = Reader
  Chunkwriter* = Writer

#
#** ======================================================================
#** Debug API
#** ======================================================================
#

const 
  HOOKCALL* = 0
  HOOKRET* = 1
  HOOKLINE* = 2
  HOOKCOUNT* = 3
  HOOKTAILRET* = 4

const 
  MASKCALL* = 1 shl Ord(HOOKCALL)
  MASKRET* = 1 shl Ord(HOOKRET)
  MASKLINE* = 1 shl Ord(HOOKLINE)
  MASKCOUNT* = 1 shl Ord(HOOKCOUNT)

const 
  IDSIZE* = 60

type 
  TDebug*{.final.} = object    # activation record 
    event*: int
    name*: cstring            # (n) 
    namewhat*: cstring        # (n) `global', `local', `field', `method' 
    what*: cstring            # (S) `Lua', `C', `main', `tail'
    source*: cstring          # (S) 
    currentline*: int         # (l) 
    nups*: int                # (u) number of upvalues 
    linedefined*: int         # (S) 
    lastlinedefined*: int     # (S) 
    short_src*: array[0..IDSIZE - 1, Char] # (S) 
                                           # private part 
    i_ci*: int                # active function 
  
  PDebug* = ptr TDebug
  Hook* = proc (L: PState, ar: PDebug){.cdecl.}

#
#** ======================================================================
#** Debug API
#** ======================================================================
#

proc getstack*(L: PState, level: int, ar: PDebug): int{.cdecl, dynlib: NAME, 
    importc: "lua_getstack".}
proc getinfo*(L: PState, what: cstring, ar: PDebug): int{.cdecl, dynlib: NAME, 
    importc: "lua_getinfo".}
proc getlocal*(L: PState, ar: PDebug, n: int): cstring{.cdecl, dynlib: NAME, 
    importc: "lua_getlocal".}
proc setlocal*(L: PState, ar: PDebug, n: int): cstring{.cdecl, dynlib: NAME, 
    importc: "lua_setlocal".}
proc getupvalue*(L: PState, funcindex: int, n: int): cstring{.cdecl, 
    dynlib: NAME, importc: "lua_getupvalue".}
proc setupvalue*(L: PState, funcindex: int, n: int): cstring{.cdecl, 
    dynlib: NAME, importc: "lua_setupvalue".}
proc sethook*(L: PState, func: Hook, mask: int, count: int): int{.cdecl, 
    dynlib: NAME, importc: "lua_sethook".}
proc gethook*(L: PState): Hook{.cdecl, dynlib: NAME, importc: "lua_gethook".}
proc gethookmask*(L: PState): int{.cdecl, dynlib: NAME, 
                                   importc: "lua_gethookmask".}
proc gethookcount*(L: PState): int{.cdecl, dynlib: NAME, 
                                    importc: "lua_gethookcount".}
# implementation

proc upvalueindex(I: int): int = 
  Result = GLOBALSINDEX - i

proc pop(L: PState, n: int) = 
  settop(L, - n - 1)

proc newtable(L: PState) = 
  createtable(L, 0, 0)

proc register(L: PState, n: cstring, f: CFunction) = 
  pushcfunction(L, f)
  setglobal(L, n)

proc pushcfunction(L: PState, f: CFunction) = 
  pushcclosure(L, f, 0)

proc strlen(L: PState, i: int): int = 
  Result = objlen(L, i)

proc isfunction(L: PState, n: int): bool = 
  Result = luatype(L, n) == TFUNCTION

proc istable(L: PState, n: int): bool = 
  Result = luatype(L, n) == TTABLE

proc islightuserdata(L: PState, n: int): bool = 
  Result = luatype(L, n) == TLIGHTUSERDATA

proc isnil(L: PState, n: int): bool = 
  Result = luatype(L, n) == TNIL

proc isboolean(L: PState, n: int): bool = 
  Result = luatype(L, n) == TBOOLEAN

proc isthread(L: PState, n: int): bool = 
  Result = luatype(L, n) == TTHREAD

proc isnone(L: PState, n: int): bool = 
  Result = luatype(L, n) == TNONE

proc isnoneornil(L: PState, n: int): bool = 
  Result = luatype(L, n) <= 0

proc pushliteral(L: PState, s: cstring) = 
  pushlstring(L, s, len(s))

proc setglobal(L: PState, s: cstring) = 
  setfield(L, GLOBALSINDEX, s)

proc getglobal(L: PState, s: cstring) = 
  getfield(L, GLOBALSINDEX, s)

proc tostring(L: PState, i: int): cstring = 
  Result = tolstring(L, i, nil)

proc getregistry(L: PState) = 
  pushvalue(L, REGISTRYINDEX)

proc getgccount(L: PState): int = 
  Result = gc(L, GCCOUNT, 0)
