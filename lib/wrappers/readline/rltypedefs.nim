# rltypedefs.h -- Type declarations for readline functions. 
# Copyright (C) 2000-2009 Free Software Foundation, Inc.
#
#   This file is part of the GNU Readline Library (Readline), a library
#   for reading lines of text with interactive input and history editing.      
#
#   Readline is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Readline is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Readline.  If not, see <http://www.gnu.org/licenses/>.
#

type 
  Function* = proc (): cint{.cdecl.}
  VFunction* = proc (){.cdecl.}
  CPFunction* = proc (): cstring{.cdecl.}
  CPPFunction* = proc (): cstringArray{.cdecl.}
{.deprecated: [TFunction: Function, TVFunction: VFunction,
              TCPFunction: CPFunction, TCPPFunction: CPPFunction].}

# Bindable functions 

type 
  Command_func* = proc (a2: cint, a3: cint): cint{.cdecl.}
{.deprecated: [Tcommand_func: Command_func].}

# Typedefs for the completion system 

type 
  Compentry_func* = proc (a2: cstring, a3: cint): cstring{.cdecl.}
  Completion_func* = proc (a2: cstring, a3: cint, a4: cint): cstringArray{.
      cdecl.}
  Quote_func* = proc (a2: cstring, a3: cint, a4: cstring): cstring{.cdecl.}
  Dequote_func* = proc (a2: cstring, a3: cint): cstring{.cdecl.}
  Compignore_func* = proc (a2: cstringArray): cint{.cdecl.}
  Compdisp_func* = proc (a2: cstringArray, a3: cint, a4: cint){.cdecl.}
{.deprecated: [Tcompentry_func: Compentry_func,Tcompletion_func: Completion_func,
              Tquote_func: Quote_func, Tdequote_func: Dequote_func,
              Tcompignore_func: Compignore_func, Tcompdisp_func: Compdisp_func].}
# Type for input and pre-read hook functions like rl_event_hook 

type 
  Thook_func* = proc (): cint{.cdecl.}

# Input function type 

type 
  Tgetc_func* = proc (a2: File): cint{.cdecl.}

# Generic function that takes a character buffer (which could be the readline
#   line buffer) and an index into it (which could be rl_point) and returns
#   an int. 

type 
  Tlinebuf_func* = proc (a2: cstring, a3: cint): cint{.cdecl.}

# `Generic' function pointer typedefs 

type 
  Tintfunc* = proc (a2: cint): cint{.cdecl.}
  Tivoidfunc* = proc (): cint{.cdecl.}
  Ticpfunc* = proc (a2: cstring): cint{.cdecl.}
  Ticppfunc* = proc (a2: cstringArray): cint{.cdecl.}
  Tvoidfunc* = proc (){.cdecl.}
  Tvintfunc* = proc (a2: cint){.cdecl.}
  Tvcpfunc* = proc (a2: cstring){.cdecl.}
  Tvcppfunc* = proc (a2: cstringArray){.cdecl.}
  Tcpvfunc* = proc (): cstring{.cdecl.}
  Tcpifunc* = proc (a2: cint): cstring{.cdecl.}
  Tcpcpfunc* = proc (a2: cstring): cstring{.cdecl.}
  Tcpcppfunc* = proc (a2: cstringArray): cstring{.cdecl.}
