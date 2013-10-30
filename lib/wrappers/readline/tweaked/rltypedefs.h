/* rltypedefs.h -- Type declarations for readline functions. */

/* Copyright (C) 2000-2009 Free Software Foundation, Inc.

   This file is part of the GNU Readline Library (Readline), a library
   for reading lines of text with interactive input and history editing.

   Readline is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Readline is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Readline.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifdef C2NIM
#  cdecl
#  prefix rl_
#  prefix RL_
#  suffix _t
#  typeprefixes
#  def PARAMS(x) x
#endif

typedef int (*Function) ();
typedef void VFunction ();
typedef char *CPFunction ();
typedef char **CPPFunction ();

/* Bindable functions */
typedef int rl_command_func_t PARAMS((int, int));

/* Typedefs for the completion system */
typedef char *rl_compentry_func_t PARAMS((const char *, int));
typedef char **rl_completion_func_t PARAMS((const char *, int, int));

typedef char *rl_quote_func_t PARAMS((char *, int, char *));
typedef char *rl_dequote_func_t PARAMS((char *, int));

typedef int rl_compignore_func_t PARAMS((char **));

typedef void rl_compdisp_func_t PARAMS((char **, int, int));

/* Type for input and pre-read hook functions like rl_event_hook */
typedef int rl_hook_func_t PARAMS((void));

/* Input function type */
typedef int rl_getc_func_t PARAMS((TFile));

/* Generic function that takes a character buffer (which could be the readline
   line buffer) and an index into it (which could be rl_point) and returns
   an int. */
typedef int rl_linebuf_func_t PARAMS((char *, int));

/* `Generic' function pointer typedefs */
typedef int rl_intfunc_t PARAMS((int));
typedef int rl_ivoidfunc_t PARAMS((void));

typedef int rl_icpfunc_t PARAMS((char *));
typedef int rl_icppfunc_t PARAMS((char **));

typedef void rl_voidfunc_t PARAMS((void));
typedef void rl_vintfunc_t PARAMS((int));
typedef void rl_vcpfunc_t PARAMS((char *));
typedef void rl_vcppfunc_t PARAMS((char **));

typedef char *rl_cpvfunc_t PARAMS((void));
typedef char *rl_cpifunc_t PARAMS((int));
typedef char *rl_cpcpfunc_t PARAMS((char  *));
typedef char *rl_cpcppfunc_t PARAMS((char  **));


