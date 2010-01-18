#
#
#      Pas2nim - Pascal to Nimrod source converter
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# 

import 
  llstream, strutils, os, ast, rnimsyn, options, msgs, 
  paslex, pasparse
  
proc exSymbols(n: PNode) = 
  case n.kind
  of nkEmpty..nkNilLit: nil
  of nkProcDef..nkIteratorDef: exSymbol(n.sons[namePos])
  of nkWhenStmt, nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): exSymbols(n.sons[i])
  of nkVarSection, nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): exSymbol(n.sons[i].sons[0])
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      exSymbol(n.sons[i].sons[0])
      if (n.sons[i].sons[2] != nil) and
          (n.sons[i].sons[2].kind == nkObjectTy): 
        fixRecordDef(n.sons[i].sons[2])
  else: nil

proc CommandExportSymbols(filename: string) = 
  # now unused!
  var module = parseFile(addFileExt(filename, NimExt))
  if module != nil: 
    exSymbols(module)
    renderModule(module, getOutFile(filename, "pretty." & NimExt))

proc CommandLexPas(filename: string) = 
  var f = addFileExt(filename, "pas")
  var stream = LLStreamOpen(f, fmRead)
  if stream != nil: 
    var 
      L: TPasLex
      tok: TPasTok
    OpenLexer(L, f, stream)
    getPasTok(L, tok)
    while tok.xkind != pxEof: 
      printPasTok(tok)
      getPasTok(L, tok)
    closeLexer(L)
  else: rawMessage(errCannotOpenFile, f)

proc CommandPas(filename: string) = 
  var f = addFileExt(filename, "pas")
  var stream = LLStreamOpen(f, fmRead)
  if stream != nil: 
    var p: TPasParser
    OpenPasParser(p, f, stream)
    var module = parseUnit(p)
    closePasParser(p)
    renderModule(module, getOutFile(filename, NimExt))
  else: 
    rawMessage(errCannotOpenFile, f)
  


