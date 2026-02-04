#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Type extension definitions for sparse metadata storage.
## Separated to avoid circular imports between modulegraphs and ast2nif.

import ast

type
  TypeExtKind* = enum
    ## Kinds of type extensions stored in side-tables.
    ## Extensible for future type metadata needs.
    extDeferredSize     ## size pragma with generic parameter
    extDeferredAlign    ## align pragma with generic parameter

  TypeExtension* = object
    ## Generic type extension for sparse metadata storage.
    ## Avoids adding fields to PType for rarely-used features.
    kind*: TypeExtKind
    expr*: PNode        ## The original pragma/extension expression AST
