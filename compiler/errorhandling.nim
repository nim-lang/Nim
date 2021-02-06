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

import ast, renderer, options, lineinfos, strutils

type
  ErrorKind* = enum ## expand as you need.
    RawTypeMismatchError
    ExpressionCannotBeCalled
    CustomError

proc newError*(wrongNode: PNode; k: ErrorKind; args: varargs[PNode]): PNode =
  assert wrongNode.kind != nkError
  if wrongNode.hasSubnodeWith(nkError):
    return wrongNode
  result = newNodeIT(nkError, wrongNode.info, newType(tyError, ItemId(module: -1, item: -1), nil))
  result.add newIntNode(nkIntLit, ord(k))
  result.add wrongNode
  for a in args: result.add a

proc newError*(wrongNode: PNode; msg: string): PNode =
  assert wrongNode.kind != nkError
  if wrongNode.hasSubnodeWith(nkError):
    return wrongNode
  result = newNodeIT(nkError, wrongNode.info, newType(tyError, ItemId(module: -1, item: -1), nil))
  result.add newIntNode(nkIntLit, ord(CustomError))
  result.add wrongNode
  result.add newStrNode(msg, wrongNode.info)

proc errorToString*(config: ConfigRef; n: PNode): string =
  assert n.kind == nkError
  assert n.len > 1
  let k = ErrorKind(n[0].intVal)
  let wrongNode = n[1]
  case k
  of RawTypeMismatchError:
    result = "type mismatch"
  of ExpressionCannotBeCalled:
    result = "expression '$1' cannot be called" % wrongNode[0].renderTree
  of CustomError:
    result = n[2].strVal
