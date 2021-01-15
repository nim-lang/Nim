#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / intsets
import ".." / [ast, options, lineinfos]

import packed_ast, to_packed_ast, bitabs, dce

proc generateCode*(g: PackedModuleGraph; conf: ConfigRef) =
  discard

