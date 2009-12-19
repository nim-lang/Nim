#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple tool to expand ``importc`` pragmas. Used for the clean up process of
## the diverse wrappers.

import 
  os, ropes, idents, ast, pnimsyn, rnimsyn, msgs, wordrecg, syntaxes

proc modifyPragmas(n: PNode, name: string) =
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if it.kind == nkIdent and whichKeyword(it.ident) == wImportc:
      var x = newNode(nkExprColonExpr)
      addSon(x, it)
      addSon(x, newStrNode(nkStrLit, name))
      n.sons[i] = x

proc getName(n: PNode): string = 
  case n.kind
  of nkPostfix: result = getName(n.sons[1])
  of nkPragmaExpr: result = getName(n.sons[0])
  of nkSym: result = n.sym.name.s
  of nkIdent: result = n.ident.s
  of nkAccQuoted: result = getName(n.sons[0])
  else: internalError(n.info, "getName()")

proc processRoutine(n: PNode) =
  var name = getName(n.sons[namePos])
  modifyPragmas(n.sons[pragmasPos], name)
  
proc processTree(n: PNode) =
  if n == nil: return
  case n.kind
  of nkEmpty..nkNilLit: nil
  of nkProcDef, nkConverterDef: processRoutine(n)
  else:
    for i in 0..sonsLen(n)-1: processTree(n.sons[i])

proc main(infile, outfile: string) =
  var module = ParseFile(infile)
  processTree(module)
  renderModule(module, outfile)

if paramcount() >= 1:
  var infile = addFileExt(paramStr(1), "nim")
  var outfile = changeFileExt(infile, "new.nim")
  if paramCount() >= 2:
    outfile = addFileExt(paramStr(2), "new.nim")
  main(infile, outfile)
else:
  echo "usage: expand_importc filename[.nim] outfilename[.nim]"
