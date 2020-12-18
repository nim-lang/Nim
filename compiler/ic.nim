#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## incremental compilation interface

import ic/[pass, to_packed_ast]
export icPass, performCaching, available, addGeneric
