#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains support code for new-styled error
## handling via an `nkError` node kind.

import ast, renderer, options, lineinfos

type
  ErrorKind* = enum ## expand as you need.
    TypeMismatchError = "Type mismatch: Expected $1, but got $2"

proc newError(info: TLineInfo; k: ErrorKind; args: varargs[PNode]): PNode =
  result = newNodeI(nkError, info)
  result.add newIntNode(nkIntLit, ord(k))
  for a in args: result.add a

proc errorToString*(config: ConfigRef; n: PNode): string =
  assert n.kind == nkError
  assert n.len > 1
  let k = ErrorKind(n[0].intVal)
  result = ""


