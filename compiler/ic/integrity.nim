#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Integrity checking for a set of .rod files.
## The set must cover a complete Nim project.

import ".." / [modulegraphs]

import ic

proc checkModule(g: ModuleGraph; m: PackedModule) =
  # We check that:
  # - Every type references existing types and symbols.
  # - Every symbol references existing types and symbols.
  # - Every tree node references existing types and symbols.
  discard "to do!"

proc checkIntegrity*(g: ModuleGraph) =
  for i in 0..high(g.packed):
    # case statement here to enforce exhaustive checks.
    case g.packed[i].status
    of undefined:
      discard "nothing to do"
    of loading:
      assert false, "cannot check integrity: Module still loading"
    of stored, storing, outdated, loaded:
      checkModule(g, g.packed[i].fromDisk)

