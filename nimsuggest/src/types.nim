## Base types needed across nimsuggest
import compiler/options
import compiler/pathutils
import macros

import net 

type
  ThreadParams* = tuple[port: Port; address: string]


type CommandData* = object
  ideCmd* :IdeCmd
  dirtyFile* :AbsoluteFile
  file* : AbsoluteFile
  col*, line* :int
  tag* :string
  ideCmdString*:string

macro unpackLet*(argsBody: untyped): untyped =
  expectKind argsBody[0], nnkAsgn
  let arg = argsBody[0][1]
  let par = argsBody[0][0]
  expectKind par, nnkTupleConstr
  var access = nnkTupleConstr.newTree
  result = nnkVarTuple.newTree
  for ch in par:
    # add fields to tuple on LHS
    result.add ch
    # build dot expressions to create RHS
    access.add nnkDotExpr.newTree(arg, ch)
  result.add newEmptyNode()
  result.add access
  # put everything into let section
  result = nnkLetSection.newTree(result)

template destructure*(cmd:CommandData)=
  ##Exposes all the properties of a CommandData object as local variables within the calling scope
  unpackLet: (ideCmd, file, line, col, dirtyFile, tag) = cmd
