#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, types, msgs, osproc, streams, options

proc readOutput(p: PProcess): string =
  result = ""
  var output = p.outputStream
  discard p.waitForExit
  while not output.atEnd:
    result.add(output.readLine)

proc opGorge*(cmd, input: string): string =
  var p = startCmd(cmd)
  if input.len != 0:
    p.inputStream.write(input)
    p.inputStream.close()
  result = p.readOutput

proc opSlurp*(file: string, info: TLineInfo, module: PSym): string = 
  try:
    let filename = file.FindFile
    result = readFile(filename)
    # we produce a fake include statement for every slurped filename, so that
    # the module dependencies are accurate:
    appendToModule(module, newNode(nkIncludeStmt, info, @[
      newStrNode(nkStrLit, filename)]))
  except EIO:
    result = ""
    LocalError(info, errCannotOpenFile, file)

proc opTypeTrait*(n: PNode, context: PSym): PNode =
  ## XXX: This should be pretty much guaranteed to be true
  # by the type traits procs' signatures, but until the
  # code is more mature it doesn't hurt to be extra safe
  internalAssert n.len >= 2 and n.sons[1].kind == nkSym

  let typ = n.sons[1].sym.typ.skipTypes({tyTypeDesc})
  case n.sons[0].sym.name.s.normalize
  of "name":
    result = newStrNode(nkStrLit, typ.typeToString(preferExported))
    result.typ = newType(tyString, context)
    result.info = n.info
  else:
    internalAssert false

when false:
  proc opExpandToAst*(c: PEvalContext, original: PNode): PNode =
    var
      n = original.copyTree
      macroCall = n.sons[1]
      expandedSym = macroCall.sons[0].sym

    for i in countup(1, macroCall.sonsLen - 1):
      macroCall.sons[i] = evalAux(c, macroCall.sons[i], {})

    case expandedSym.kind
    of skTemplate:
      let genSymOwner = if c.tos != nil and c.tos.prc != nil:
                          c.tos.prc 
                        else:
                          c.module
      result = evalTemplate(macroCall, expandedSym, genSymOwner)
    of skMacro:
      # At this point macroCall.sons[0] is nkSym node.
      # To be completely compatible with normal macro invocation,
      # we want to replace it with nkIdent node featuring
      # the original unmangled macro name.
      macroCall.sons[0] = newIdentNode(expandedSym.name, expandedSym.info)
      result = evalMacroCall(c, macroCall, original, expandedSym)
    else:
      InternalError(macroCall.info,
        "ExpandToAst: expanded symbol is no macro or template")
      result = emptyNode

  proc opIs*(n: PNode): PNode =
    InternalAssert n.sonsLen == 3 and
      n[1].kind == nkSym and n[1].sym.kind == skType and
      n[2].kind in {nkStrLit..nkTripleStrLit, nkType}
    
    let t1 = n[1].sym.typ

    if n[2].kind in {nkStrLit..nkTripleStrLit}:
      case n[2].strVal.normalize
      of "closure":
        let t = skipTypes(t1, abstractRange)
        result = newIntNode(nkIntLit, ord(t.kind == tyProc and
                                          t.callConv == ccClosure and 
                                          tfIterator notin t.flags))
      of "iterator":
        let t = skipTypes(t1, abstractRange)
        result = newIntNode(nkIntLit, ord(t.kind == tyProc and
                                          t.callConv == ccClosure and 
                                          tfIterator in t.flags))
    else:
      let t2 = n[2].typ
      var match = if t2.kind == tyTypeClass: matchTypeClass(t2, t1)
                  else: sameType(t1, t2)
      result = newIntNode(nkIntLit, ord(match))

    result.typ = n.typ

