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

when defined(MACOSX): 
  const 
    LUA_NAME* = "liblua(|5.2|5.1|5.0).dylib"
    LUA_LIB_NAME* = "liblua(|5.2|5.1|5.0).dylib"
elif defined(UNIX): 
  const 
    LUA_NAME* = "liblua(|5.2|5.1|5.0).so.(|0)"
    LUA_LIB_NAME* = "liblua(|5.2|5.1|5.0).so.(|0)"
else: 
  const 
    LUA_NAME* = "lua(|5.2|5.1|5.0).dll"
    LUA_LIB_NAME* = "lua(|5.2|5.1|5.0).dll"
type 
  size_t* = int
  Psize_t* = ptr size_t

const 
  LUA_VERSION* = "Lua 5.1"
  LUA_RELEASE* = "Lua 5.1.1"
  LUA_VERSION_NUM* = 501
  LUA_COPYRIGHT* = "Copyright (C) 1994-2006 Lua.org, PUC-Rio"
  LUA_AUTHORS* = "R. Ierusalimschy, L. H. de Figueiredo & W. Celes"
  # option for multiple returns in `lua_pcall' and `lua_call' 
  LUA_MULTRET* = - 1          #
                              #** pseudo-indices
                              #
  LUA_REGISTRYINDEX* = - 10000
  LUA_ENVIRONINDEX* = - 10001
  LUA_GLOBALSINDEX* = - 10002

proc lua_upvalueindex*(I: int): int
const                         # thread status; 0 is OK 
  LUA_YIELD_* = 1
  LUA_ERRRUN* = 2
  LUA_ERRSYNTAX* = 3
  LUA_ERRMEM* = 4
  LUA_ERRERR* = 5

type 
  Plua_State* = Pointer
  lua_CFunction* = proc (L: Plua_State): int{.cdecl.}
  
#
#** functions that read/write blocks when loading/dumping Lua chunks
#
type 
  lua_Reader* = proc (L: Plua_State, ud: Pointer, sz: Psize_t): cstring{.cdecl.}
  lua_Writer* = proc (L: Plua_State, p: Pointer, sz: size_t, ud: Pointer): int{.
      cdecl.}
  lua_Alloc* = proc (ud, theptr: Pointer, osize, nsize: size_t){.cdecl.}

const
  LUA_TNONE* = - 1
  LUA_TNIL* = 0
  LUA_TBOOLEAN* = 1
  LUA_TLIGHTUSERDATA* = 2
  LUA_TNUMBER* = 3
  LUA_TSTRING* = 4
  LUA_TTABLE* = 5
  LUA_TFUNCTION* = 6
  LUA_TUSERDATA* = 7
  LUA_TTHREAD* = 8            # minimum Lua stack available to a C function 
  LUA_MINSTACK* = 20

type                          # Type of Numbers in Lua 
  lua_Number* = float
  lua_Integer* = int

proc lua_newstate*(f: lua_Alloc, ud: Pointer): Plua_State{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_close*(L: Plua_State){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_newthread*(L: Plua_State): Plua_State{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_atpanic*(L: Plua_State, panicf: lua_CFunction): lua_CFunction{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_gettop*(L: Plua_State): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_settop*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_pushvalue*(L: Plua_State, Idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_remove*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_insert*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_replace*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_checkstack*(L: Plua_State, sz: int): cint{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_xmove*(`from`, `to`: Plua_State, n: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_isnumber*(L: Plua_State, idx: int): cint{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_isstring*(L: Plua_State, idx: int): cint{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_iscfunction*(L: Plua_State, idx: int): cint{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_isuserdata*(L: Plua_State, idx: int): cint{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_type*(L: Plua_State, idx: int): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_typename*(L: Plua_State, tp: int): cstring{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_equal*(L: Plua_State, idx1, idx2: int): cint{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_rawequal*(L: Plua_State, idx1, idx2: int): cint{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_lessthan*(L: Plua_State, idx1, idx2: int): cint{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_tonumber*(L: Plua_State, idx: int): lua_Number{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_tointeger*(L: Plua_State, idx: int): lua_Integer{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_toboolean*(L: Plua_State, idx: int): cint{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_tolstring*(L: Plua_State, idx: int, length: Psize_t): cstring{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_objlen*(L: Plua_State, idx: int): size_t{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_tocfunction*(L: Plua_State, idx: int): lua_CFunction{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_touserdata*(L: Plua_State, idx: int): Pointer{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_tothread*(L: Plua_State, idx: int): Plua_State{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_topointer*(L: Plua_State, idx: int): Pointer{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushnil*(L: Plua_State){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_pushnumber*(L: Plua_State, n: lua_Number){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushinteger*(L: Plua_State, n: lua_Integer){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushlstring*(L: Plua_State, s: cstring, l_: size_t){.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_pushstring*(L: Plua_State, s: cstring){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushvfstring*(L: Plua_State, fmt: cstring, argp: Pointer): cstring{.
    cdecl, dynlib: LUA_NAME, importc.}
proc lua_pushfstring*(L: Plua_State, fmt: cstring): cstring{.cdecl, varargs, 
    dynlib: LUA_NAME, importc.}
proc lua_pushcclosure*(L: Plua_State, fn: lua_CFunction, n: int){.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_pushboolean*(L: Plua_State, b: cint){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushlightuserdata*(L: Plua_State, p: Pointer){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pushthread*(L: Plua_State){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_gettable*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_getfield*(L: Plua_state, idx: int, k: cstring){.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_rawget*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_rawgeti*(L: Plua_State, idx, n: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_createtable*(L: Plua_State, narr, nrec: int){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_newuserdata*(L: Plua_State, sz: size_t): Pointer{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_getmetatable*(L: Plua_State, objindex: int): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_getfenv*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_settable*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_setfield*(L: Plua_State, idx: int, k: cstring){.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_rawset*(L: Plua_State, idx: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_rawseti*(L: Plua_State, idx, n: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_setmetatable*(L: Plua_State, objindex: int): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_setfenv*(L: Plua_State, idx: int): int{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_call*(L: Plua_State, nargs, nresults: int){.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_pcall*(L: Plua_State, nargs, nresults, errf: int): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_cpcall*(L: Plua_State, func: lua_CFunction, ud: Pointer): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_load*(L: Plua_State, reader: lua_Reader, dt: Pointer, 
               chunkname: cstring): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_dump*(L: Plua_State, writer: lua_Writer, data: Pointer): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_yield*(L: Plua_State, nresults: int): int{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_resume*(L: Plua_State, narg: int): int{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_status*(L: Plua_State): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_gc*(L: Plua_State, what, data: int): int{.cdecl, dynlib: LUA_NAME, 
    importc.}
proc lua_error*(L: Plua_State): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_next*(L: Plua_State, idx: int): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_concat*(L: Plua_State, n: int){.cdecl, dynlib: LUA_NAME, importc.}
proc lua_getallocf*(L: Plua_State, ud: ptr Pointer): lua_Alloc{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_setallocf*(L: Plua_State, f: lua_Alloc, ud: Pointer){.cdecl, 
    dynlib: LUA_NAME, importc.}

#
#** Garbage-collection functions and options
#
const 
  LUA_GCSTOP* = 0
  LUA_GCRESTART* = 1
  LUA_GCCOLLECT* = 2
  LUA_GCCOUNT* = 3
  LUA_GCCOUNTB* = 4
  LUA_GCSTEP* = 5
  LUA_GCSETPAUSE* = 6
  LUA_GCSETSTEPMUL* = 7

#
#** ===============================================================
#** some useful macros
#** ===============================================================
#

proc lua_pop*(L: Plua_State, n: int)
proc lua_newtable*(L: Plua_state)
proc lua_register*(L: Plua_State, n: cstring, f: lua_CFunction)
proc lua_pushcfunction*(L: Plua_State, f: lua_CFunction)
proc lua_strlen*(L: Plua_state, i: int): size_t
proc lua_isfunction*(L: Plua_State, n: int): bool
proc lua_istable*(L: Plua_State, n: int): bool
proc lua_islightuserdata*(L: Plua_State, n: int): bool
proc lua_isnil*(L: Plua_State, n: int): bool
proc lua_isboolean*(L: Plua_State, n: int): bool
proc lua_isthread*(L: Plua_State, n: int): bool
proc lua_isnone*(L: Plua_State, n: int): bool
proc lua_isnoneornil*(L: Plua_State, n: int): bool
proc lua_pushliteral*(L: Plua_State, s: cstring)
proc lua_setglobal*(L: Plua_State, s: cstring)
proc lua_getglobal*(L: Plua_State, s: cstring)
proc lua_tostring*(L: Plua_State, i: int): cstring
#
#** compatibility macros and functions
#
proc lua_getregistry*(L: Plua_State)
proc lua_getgccount*(L: Plua_State): int
type 
  lua_Chunkreader* = lua_Reader
  lua_Chunkwriter* = lua_Writer
  
#
#** {======================================================================
#** Debug API
#** =======================================================================
#

const 
  LUA_HOOKCALL* = 0
  LUA_HOOKRET* = 1
  LUA_HOOKLINE* = 2
  LUA_HOOKCOUNT* = 3
  LUA_HOOKTAILRET* = 4

const 
  LUA_MASKCALL* = 1 shl Ord(LUA_HOOKCALL)
  LUA_MASKRET* = 1 shl Ord(LUA_HOOKRET)
  LUA_MASKLINE* = 1 shl Ord(LUA_HOOKLINE)
  LUA_MASKCOUNT* = 1 shl Ord(LUA_HOOKCOUNT)

const 
  LUA_IDSIZE* = 60

type 
  lua_Debug*{.final.} = object  # activation record 
    event*: int
    name*: cstring            # (n) 
    namewhat*: cstring        # (n) `global', `local', `field', `method' 
    what*: cstring            # (S) `Lua', `C', `main', `tail'
    source*: cstring          # (S) 
    currentline*: int         # (l) 
    nups*: int                # (u) number of upvalues 
    linedefined*: int         # (S) 
    lastlinedefined*: int     # (S) 
    short_src*: array[0..LUA_IDSIZE - 1, Char] # (S) 
                                               # private part 
    i_ci*: int                # active function 
  
  Plua_Debug* = ptr lua_Debug
  lua_Hook* = proc (L: Plua_State, ar: Plua_Debug){.cdecl.}
  
#
#** {======================================================================
#** Debug API
#** =======================================================================
#

proc lua_getstack*(L: Plua_State, level: int, ar: Plua_Debug): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_getinfo*(L: Plua_State, what: cstring, ar: Plua_Debug): int{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_getlocal*(L: Plua_State, ar: Plua_Debug, n: int): cstring{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_setlocal*(L: Plua_State, ar: Plua_Debug, n: int): cstring{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_getupvalue*(L: Plua_State, funcindex: int, n: int): cstring{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_setupvalue*(L: Plua_State, funcindex: int, n: int): cstring{.cdecl, 
    dynlib: LUA_NAME, importc.}
proc lua_sethook*(L: Plua_State, func: lua_Hook, mask: int, count: int): int{.
    cdecl, dynlib: LUA_NAME, importc.}
proc lua_gethook*(L: Plua_State): lua_Hook{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_gethookmask*(L: Plua_State): int{.cdecl, dynlib: LUA_NAME, importc.}
proc lua_gethookcount*(L: Plua_State): int{.cdecl, dynlib: LUA_NAME, importc.}
# implementation

proc lua_upvalueindex(I: int): int = 
  Result = LUA_GLOBALSINDEX - i

proc lua_pop(L: Plua_State, n: int) = 
  lua_settop(L, - n - 1)

proc lua_newtable(L: Plua_State) = 
  lua_createtable(L, 0, 0)

proc lua_register(L: Plua_State, n: cstring, f: lua_CFunction) = 
  lua_pushcfunction(L, f)
  lua_setglobal(L, n)

proc lua_pushcfunction(L: Plua_State, f: lua_CFunction) = 
  lua_pushcclosure(L, f, 0)

proc lua_strlen(L: Plua_State, i: int): size_t = 
  Result = lua_objlen(L, i)

proc lua_isfunction(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TFUNCTION

proc lua_istable(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TTABLE

proc lua_islightuserdata(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TLIGHTUSERDATA

proc lua_isnil(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TNIL

proc lua_isboolean(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TBOOLEAN

proc lua_isthread(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TTHREAD

proc lua_isnone(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) == LUA_TNONE

proc lua_isnoneornil(L: Plua_State, n: int): bool = 
  Result = lua_type(L, n) <= 0

proc lua_pushliteral(L: Plua_State, s: cstring) = 
  lua_pushlstring(L, s, len(s))

proc lua_setglobal(L: Plua_State, s: cstring) = 
  lua_setfield(L, LUA_GLOBALSINDEX, s)

proc lua_getglobal(L: Plua_State, s: cstring) = 
  lua_getfield(L, LUA_GLOBALSINDEX, s)

proc lua_tostring(L: Plua_State, i: int): cstring = 
  Result = lua_tolstring(L, i, nil)

proc lua_getregistry(L: Plua_State) = 
  lua_pushvalue(L, LUA_REGISTRYINDEX)

proc lua_getgccount(L: Plua_State): int = 
  Result = lua_gc(L, LUA_GCCOUNT, 0)
