
proc copySymdef(n: PNode; locals: var Table[int, PSym]; idgen: IdGenerator; owner: PSym): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    result = n
  of nkSym:
    let oldSym = n.sym
    let newSym = copySym(oldSym, idgen)
    setOwner(newSym, owner)
    locals[oldSym.id] = newSym
    result = newSymNode(newSym, oldSym.info)
  else:
    result = shallowCopy(n)
    for i in 0..<n.len:
      result[i] = copySymdef(n[i], locals, idgen, owner)

proc copyInlineProcBody(n: PNode; locals: var Table[int, PSym]; idgen: IdGenerator; owner: PSym): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    result = n
  of nkSym:
    let sym = locals.getOrDefault(n.sym.id)
    if sym != nil:
      result = newSymNode(sym, n.info)
    else:
      result = n
  of nkLetSection, nkVarSection:
    result = shallowCopy(n)
    for i in 0..<n.len:
      let it = n[i]
      if it.kind == nkCommentStmt:
        result[i] = it
      elif it.kind in {nkIdentDefs, nkConstDef}:
        result[i] = shallowCopy(it)
        for j in 0..<it.len-2:
          result[i][j] = copySymdef(it[j], locals, idgen, owner)
        for j in it.len-2..<it.len:
          result[i][j] = copyInlineProcBody(it[j], locals, idgen, owner)
      else:
        assert it.kind == nkVarTuple
        result[i] = shallowCopy(it)
        for j in 0..<it.len-2:
          assert it[j].kind == nkSym
          let oldSym = it[j].sym
          let newSym = copySym(oldSym, idgen)
          setOwner(newSym, owner)
          locals[oldSym.id] = newSym
          result[i][j] = newSymNode(newSym, oldSym.info)
        for j in it.len-2..<it.len:
          result[i][j] = copyInlineProcBody(it[j], locals, idgen, owner)

  of nkForStmt, nkParForStmt:
    result = shallowCopy(n)
    for i in 0..<n.len-2:
      assert n[i].kind == nkSym
      let oldSym = n[i].sym
      let newSym = copySym(oldSym, idgen)
      setOwner(newSym, owner)
      locals[oldSym.id] = newSym
      result[i] = newSymNode(newSym, oldSym.info)
    result[n.len-2] = copyInlineProcBody(n[n.len-2], locals, idgen, owner)
    result[n.len-1] = copyInlineProcBody(n[n.len-1], locals, idgen, owner)
  of routineDefs, nkTypeSection, nkTypeOfExpr, nkMixinStmt, nkBindStmt, nkConstSection:
    result = n
  else:
    result = shallowCopy(n)
    for i in 0..<n.len:
      result[i] = copyInlineProcBody(n[i], locals, idgen, owner)

proc copyParams(n: PNode; locals: var Table[int, PSym]; idgen: IdGenerator; owner: PSym): PNode =
  result = shallowCopy(n)
  result[0] = n[0] # return type
  for i in 1..<n.len:
    let it = n[i]
    assert it.kind == nkIdentDefs
    result[i] = shallowCopy(it)
    for j in 0..<it.len-2:
      assert it[j].kind == nkSym
      let oldSym = it[j].sym
      let newSym = copySym(oldSym, idgen)
      setOwner(newSym, owner)
      locals[oldSym.id] = newSym
      result[i][j] = newSymNode(newSym, oldSym.info)
      owner.typ.addParam newSym
    for j in it.len-2..<it.len:
      result[i][j] = copyInlineProcBody(it[j], locals, idgen, owner)

proc copyInlineProc(prc: PSym; idgen: IdGenerator): PSym =
  result = copySym(prc, idgen)
  var locals = initTable[int, PSym]()

  var a = shallowCopy(prc.ast)
  if resultPos < prc.ast.len and prc.ast[resultPos].kind == nkSym:
    let oldRes = prc.ast[resultPos].sym
    let newRes = copySym(oldRes, idgen)
    setOwner(newRes, result)
    locals[oldRes.id] = newRes
    a[resultPos] = newSymNode(newRes, oldRes.info)

  result.typ = copyType(prc.typ, idgen, result)
  result.typ.n = newNodeI(prc.typ.n.kind, prc.typ.n.info)
  if prc.typ.n.len > 0:
    result.typ.n.add copyNode(prc.typ.n[0])
    for i in 1..<prc.typ.n.len:
      let it = prc.typ.n[i]
      assert it.kind == nkSym
      let oldSym = it.sym
      let newSym = copySym(oldSym, idgen)
      setOwner(newSym, result)
      locals[oldSym.id] = newSym
      result.typ.addParam newSym

  for i in 0..<prc.ast.len:
    if i == paramsPos:
      a[i] = copyTree(prc.ast[i])
    elif i == resultPos and prc.ast[i].kind == nkSym:
      discard "handled above"
    else:
      a[i] = copyInlineProcBody(prc.ast[i], locals, idgen, result)
  result.ast = a

  #echo "Produced: ", renderTree(result.ast, {renderIds})
