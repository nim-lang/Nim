#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# This module implements a transformator. It transforms the syntax tree 
# to ease the work of the code generators. Does the transformation to 
# introduce temporaries to split up complex expressions.
# THIS MODULE IS NOT USED!

proc transInto(c: PContext, dest: var PNode, father, src: PNode)
  # transforms the expression `src` into the destination `dest`. Uses `father`
  # for temorary statements. If dest = nil, the expression is put into a 
  # temporary.
proc transTmp(c: PContext, father, src: PNode): PNode = 
  # convienence proc
  result = nil
  transInto(c, result, father, src)

proc newLabel(c: PContext): PSym = 
  inc(gTmpId)
  result = newSym(skLabel, getIdent(genPrefix & $(gTmpId), c.transCon.owner))

proc fewCmps(s: PNode): bool = 
  # this function estimates whether it is better to emit code
  # for constructing the set or generating a bunch of comparisons directly
  assert(s.kind in {nkSetConstr, nkConstSetConstr})
  if (s.typ.size <= platform.intSize) and (s.kind == nkConstSetConstr): 
    result = false            # it is better to emit the set generation code
  elif skipRange(s.typ.sons[0]).Kind in {tyInt..tyInt64}: 
    result = true             # better not emit the set if int is basetype!
  else: 
    result = sonsLen(s) <=
        8                     # 8 seems to be a good value
  
proc transformIn(c: PContext, father, n: PNode): PNode = 
  var 
    a, b, e, setc: PNode
    destLabel, label2: PSym
  if (n.sons[1].kind == nkSetConstr) and fewCmps(n.sons[1]): 
    # a set constructor but not a constant set:
    # do not emit the set, but generate a bunch of comparisons
    result = newSymNode(newTemp(c, n.typ, n.info))
    e = transTmp(c, father, n.sons[2])
    setc = n.sons[1]
    destLabel = newLabel(c)
    for i in countup(0, sonsLen(setc) - 1): 
      if setc.sons[i].kind == nkRange: 
        a = transTmp(c, father, setc.sons[i].sons[0])
        b = transTmp(c, father, setc.sons[i].sons[1])
        label2 = newLabel(c)
        addSon(father, newLt(result, e, a)) # e < a? --> goto end
        addSon(father, newCondJmp(result, label2))
        addSon(father, newLe(result, e, b)) # e <= b? --> goto set end
        addSon(father, newCondJmp(result, destLabel))
        addSon(father, newLabelNode(label2))
      else: 
        a = transTmp(c, father, setc.sons[i])
        addSon(father, newEq(result, e, a))
        addSon(father, newCondJmp(result, destLabel))
    addSon(father, newLabelNode(destLabel))
  else: 
    result = n

proc transformOp2(c: PContext, dest: var PNode, father, n: PNode) = 
  var a, b: PNode
  if dest == nil: dest = newSymNode(newTemp(c, n.typ, n.info))
  a = transTmp(c, father, n.sons[1])
  b = transTmp(c, father, n.sons[2])
  addSon(father, newAsgnStmt(dest, newOp2(n, a, b)))

proc transformOp1(c: PContext, dest: var PNode, father, n: PNode) = 
  var a: PNode
  if dest == nil: dest = newSymNode(newTemp(c, n.typ, n.info))
  a = transTmp(c, father, n.sons[1])
  addSon(father, newAsgnStmt(dest, newOp1(n, a)))

proc genTypeInfo(c: PContext, initSection: PNode) = 
  nil

proc genNew(c: PContext, father, n: PNode) = 
  # how do we handle compilerprocs?
  
proc transformCase(c: PContext, father, n: PNode): PNode = 
  var 
    ty: PType
    e: PNode
  ty = skipGeneric(n.sons[0].typ)
  if ty.kind == tyString: 
    # transform a string case to a bunch of comparisons:
    result = newNodeI(nkIfStmt, n)
    e = transTmp(c, father, n.sons[0])
  else: 
    result = n
  
proc transInto(c: PContext, dest: var PNode, father, src: PNode) = 
  if src == nil: return 
  if (src.typ != nil) and (src.typ.kind == tyGenericInst): 
    src.typ = skipGeneric(src.typ)
  case src.kind
  of nkIdent..nkNilLit: 
    if dest == nil: 
      dest = copyTree(src)
    else: 
      # generate assignment:
      addSon(father, newAsgnStmt(dest, src))
  of nkCall, nkCommand, nkCallStrLit: 
    nil
