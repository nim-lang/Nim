#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains Nimrod's version. It is the only place where it needs
# to be changed.

const 
  MaxSetElements* = 1 shl 16  # (2^16) to support unicode character sets?
  VersionMajor* = 0
  VersionMinor* = 9
  VersionPatch* = 6
  VersionAsString* = $VersionMajor & "." & $VersionMinor & "." & $VersionPatch

  RodFileVersion* = "1215"       # modify this if the rod-format changes!

