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

proc open_base*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                  importc: "luaopen_base".}
proc open_table*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                   importc: "luaopen_table".}
proc open_io*(L: PState): cint{.cdecl, dynlib: LIB_NAME, importc: "luaopen_io".}
proc open_string*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                    importc: "luaopen_string".}
proc open_math*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                  importc: "luaopen_math".}
proc open_debug*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                   importc: "luaopen_debug".}
proc open_package*(L: PState): cint{.cdecl, dynlib: LIB_NAME, 
                                     importc: "luaopen_package".}
proc openlibs*(L: PState){.cdecl, dynlib: LIB_NAME, importc: "luaL_openlibs".}

proc baselibopen*(L: PState): Bool = 
  Result = open_base(L) != 0'i32

proc tablibopen*(L: PState): Bool = 
  Result = open_table(L) != 0'i32

proc iolibopen*(L: PState): Bool = 
  Result = open_io(L) != 0'i32

proc strlibopen*(L: PState): Bool = 
  Result = open_string(L) != 0'i32

proc mathlibopen*(L: PState): Bool = 
  Result = open_math(L) != 0'i32

proc dblibopen*(L: PState): Bool = 
  Result = open_debug(L) != 0'i32
