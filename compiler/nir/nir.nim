#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim Intermediate Representation, designed to capture all of Nim's semantics without losing too much
## precious information. Can easily be translated into C. And to JavaScript, hopefully.

import nirtypes, nirinsts

type
  Module* = object
    types: TypeGraph
    data: seq[Tree]
    init: seq[Tree]
    procs: seq[Tree]


