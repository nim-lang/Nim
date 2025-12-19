import ast, modulegraphs, magicsys, idents, lowerings, msgs, lineinfos

import std/assertions

const
  upName* = ":up" # field name for the 'up' reference
  paramName* = ":envP"
  envName* = ":env"

# ---------------- essential helpers -------------------------------------


proc newCall(a: PSym, b: PNode): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add b

proc createClosureIterStateType*(g: ModuleGraph; iter: PSym; idgen: IdGenerator): PType =
  var n = newNodeI(nkRange, iter.info)
  n.add newIntNode(nkIntLit, -1)
  n.add newIntNode(nkIntLit, 0)
  result = newType(tyRange, idgen, iter)
  result.n = n
  var intType = nilOrSysInt(g)
  if intType.isNil: intType = newType(tyInt, idgen, iter)
  rawAddSon(result, intType)

proc createStateField(g: ModuleGraph; iter: PSym; idgen: IdGenerator): PSym =
  result = newSym(skField, getIdent(g.cache, ":state"), idgen, iter, iter.info)
  result.typ = createClosureIterStateType(g, iter, idgen)

template isIterator*(owner: PSym): bool =
  owner.kind == skIterator and owner.typ.callConv == ccClosure

proc createEnvObj*(g: ModuleGraph; idgen: IdGenerator; owner: PSym; info: TLineInfo): PType =
  result = createObj(g, idgen, owner, info, final=false)
  result.incl tfFinal
  if owner.isIterator:
    rawAddField(result, createStateField(g, owner, idgen))

proc getClosureIterResult*(g: ModuleGraph; iter: PSym; idgen: IdGenerator): PSym =
  if resultPos < iter.ast.len:
    result = iter.ast[resultPos].sym
  else:
    # XXX a bit hacky:
    result = newSym(skResult, getIdent(g.cache, ":result"), idgen, iter, iter.info, {})
    result.typ = iter.typ.returnType
    incl(result.flagsImpl, sfUsed)
    iter.ast.add newSymNode(result)

proc addHiddenParam*(routine: PSym, param: PSym) =
  assert param.kind == skParam
  var params = routine.ast[paramsPos]
  # -1 is correct here as param.position is 0 based but we have at position 0
  # some nkEffect node:
  param.position = routine.typ.n.len-1
  params.add newSymNode(param)
  #incl(routine.typ.flags, tfCapturesEnv)
  assert sfFromGeneric in param.flags
  #echo "produced environment: ", param.id, " for ", routine.id

proc getEnvParam*(routine: PSym): PSym =
  if routine.ast.isNil: return nil
  let params = routine.ast[paramsPos]
  let hidden = lastSon(params)
  if hidden.kind == nkSym and hidden.sym.kind == skParam and hidden.sym.name.s == paramName:
    result = hidden.sym
    assert sfFromGeneric in result.flags
  else:
    result = nil

proc getHiddenParam*(g: ModuleGraph; routine: PSym): PSym =
  result = getEnvParam(routine)
  if result.isNil:
    # writeStackTrace()
    localError(g.config, routine.info, "internal error: could not find env param for " & routine.name.s)
    result = routine

proc getStateField*(g: ModuleGraph; owner: PSym): PSym =
  getHiddenParam(g, owner).typ.skipTypes({tyOwned, tyRef, tyPtr}).n[0].sym
