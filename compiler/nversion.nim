#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains Nim's version. It is the only place where it needs
# to be changed.

const
  MaxSetElements* = 1 shl 16  # (2^16) to support unicode character sets?
  VersionAsString* = system.NimVersion
  RodFileVersion* = "1223"       # modify this if the rod-format changes!

  NimCompilerApiVersion* = 3 ## Check for the existence of this before accessing it
                             ## as older versions of the compiler API do not
                             ## declare this.
