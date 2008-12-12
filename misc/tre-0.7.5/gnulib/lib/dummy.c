/* A dummy file, to prevent empty libraries from breaking builds.
   Copyright (C) 2004 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
   USA.  */

/* Some systems, reportedly OpenBSD and Mac OS X, refuse to create
   libraries without any object files.  You might get an error like:

   > ar cru .libs/libgl.a
   > ar: no archive members specified

   Compiling this file, and adding its object file to the library, will
   prevent the library from being empty.  */

/* This declaration is solely to ensure that after preprocessing
   this file is never empty.  */
typedef int dummy;
