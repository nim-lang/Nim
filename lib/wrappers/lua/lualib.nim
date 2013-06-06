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

import 
  lua

const 
  COLIBNAME* = "coroutine"
  TABLIBNAME* = "table"
  IOLIBNAME* = "io"
  OSLIBNAME* = "os"
  STRLINAME* = "string"
  MATHLIBNAME* = "math"
  DBLIBNAME* = "debug"
  LOADLIBNAME* = "package"

{.pragma: ilua, importc: "lua$1".}

{.push callConv: cdecl, dynlib: lua.LIB_NAME.}
proc open_base*(L: PState): cint{.ilua.}
proc open_table*(L: PState): cint{.ilua.}
proc open_io*(L: PState): cint{.ilua.}
proc open_string*(L: PState): cint{.ilua.}
proc open_math*(L: PState): cint{.ilua.}
proc open_debug*(L: PState): cint{.ilua.}
proc open_package*(L: PState): cint{.ilua.}
proc openlibs*(L: PState){.importc: "luaL_openlibs".}
{.pop.}

proc baselibopen*(L: PState): Bool = 
  open_base(L) != 0'i32

proc tablibopen*(L: PState): Bool = 
  open_table(L) != 0'i32

proc iolibopen*(L: PState): Bool = 
  open_io(L) != 0'i32

proc strlibopen*(L: PState): Bool = 
  open_string(L) != 0'i32

proc mathlibopen*(L: PState): Bool = 
  open_math(L) != 0'i32

proc dblibopen*(L: PState): Bool = 
  open_debug(L) != 0'i32
