

proc copyInlineProcBody(n: PNode; locals: var Table[int, PSym]; idgen: IdGenerator): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    result = n
  of nkSym:
    let sym = locals.getOrDefault(n.sym.id)
    if sym != nil:
      result = newSymNode(sym, n.info)
    else:
      result = n
  of nkLetSection, nkVarSection, nkConstSection:
    result = shallowCopy(n)
    for i in 0..<n.len:
      let it = n[i]
      if it.kind == nkCommentStmt:
        result[i] = it
      elif it.kind == nkIdentDefs:
        if it[0].kind == nkSym:
          let oldSym = it[0].sym
          let newSym = copySym(oldSym, idgen)
          locals[oldSym.id] = newSym
          result[i] = shallowCopy(it)
          result[i][0] = newSymNode(newSym, oldSym.info)
          for j in 1..<it.len:
            result[i][j] = copyInlineProcBody(it[j], locals, idgen)
        else:
          result[i] = it
      else:
        assert it.kind == nkVarTuple
        result[i] = shallowCopy(it)
        for j in 0..<it.len-2:
          assert it[j].kind == nkSym
          let oldSym = it[j].sym
          let newSym = copySym(oldSym, idgen)
          locals[oldSym.id] = newSym
          result[i][j] = newSymNode(newSym, oldSym.info)
        for j in it.len-2..<it.len:
          result[i][j] = copyInlineProcBody(it[j], locals, idgen)

  of routineDefs, nkTypeSection, nkTypeOfExpr, nkMixinStmt, nkBindStmt:
    result = n
  else:
    result = shallowCopy(n)
    for i in 0..<n.len:
      result[i] = copyInlineProcBody(n[i], locals, idgen)
  
proc copyParams(n: PNode; locals: var Table[int, PSym]; idgen: IdGenerator): PNode =
  result = shallowCopy(n)
  result[0] = n[0] # return type
  for i in 1..<n.len:
    let it = n[i]
    assert it.kind == nkIdentDefs
    assert it[0].kind == nkSym
    let oldSym = it[0].sym
    let newSym = copySym(oldSym, idgen)
    locals[oldSym.id] = newSym
    result[i] = shallowCopy(it)
    result[i][0] = newSymNode(newSym, oldSym.info)
    for j in 1..<it.len:
      result[i][j] = copyInlineProcBody(it[j], locals, idgen)

proc copyInlineProc(prc: PSym; idgen: IdGenerator): PSym =
  result = copySym(prc, idgen)
  var locals = initTable[int, PSym]()

  var a = newNodeI(prc.ast.kind, prc.ast.info)
  for i in 0..<prc.ast.len:
    if i == paramsPos:
      a.add copyParams(prc.ast[i], locals, idgen)
    elif i == resultPos:
      assert prc.ast[i].kind == nkSym
      let oldRes = prc.ast[i].sym
      let newRes = copySym(oldRes, idgen)
      locals[oldRes.id] = newRes
      a.add newSymNode(newRes, oldRes.info)
    else:
      a.add copyInlineProcBody(prc.ast[i], locals, idgen)
  result.ast = a

