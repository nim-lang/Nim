#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / intsets
import ".." / [ast, options, lineinfos, modulegraphs]

import packed_ast, to_packed_ast, bitabs, dce

proc generateCodeForModule(g: ModuleGraph; m: var LoadedModule) =
  discard

proc generateCode*(g: ModuleGraph) =
  let alive = computeAliveSyms(g.packed, g.config)

  for i in 0..high(g.packed):
    # case statement here to enforce exhaustive checks.
    case g.packed[i].status
    of undefined:
      discard "nothing to do"
    of loading:
      assert false
    of storing, outdated:
      generateCodeForModule(g, g.packed[i])
    of loaded:
      # Even though this module didn't change, we DCE might
      # trigger a change...
      discard "XXX to implement"

