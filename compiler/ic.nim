#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## incremental compilation interface

import
  ast, idents, msgs, options, lineinfos, pathutils,
  astalgo, modulegraphs,
  std/[sequtils, hashes],
  std/options as stdoptions

import ic/[pass, from_packed_ast, to_packed_ast, packed_ast, store]
export icPass
