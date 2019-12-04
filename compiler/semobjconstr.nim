#
#
#           The Nim Compiler
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements Nim's object construction rules.

# included from sem.nim

type
  InitStatus = enum
    initUnknown
    initFull     # All  of the fields have been initialized
    initPartial  # Some of the fields have been initialized
    initNone     # None of the fields have been initialized
    initConflict # Fields from different branches have been initialized

proc mergeInitStatus(existing: var InitStatus, newStatus: InitStatus) =
  case newStatus
  of initConflict:
    existing = newStatus
  of initPartial:
    if existing in {initUnknown, initFull, initNone}:
      existing = initPartial
  of initNone:
    if existing == initUnknown:
      existing = initNone
    elif existing == initFull:
      existing = initPartial
  of initFull:
    if existing == initUnknown:
      existing = initFull
    elif existing == initNone:
      existing = initPartial
  of initUnknown:
    discard

proc invalidObjConstr(c: PContext, n: PNode) =
  if n.kind == nkInfix and n[0].kind == nkIdent and n[0].ident.s[0] == ':':
    localError(c.config, n.info, "incorrect object construction syntax; use a space after the colon")
  else:
    localError(c.config, n.info, "incorrect object construction syntax")

proc locateFieldInInitExpr(c: PContext, field: PSym, initExpr: PNode): PNode =
  # Returns the assignment nkExprColonExpr node or nil
  let fieldId = field.name.id
  for i in 1..<initExpr.len:
    let assignment = initExpr[i]
    if assignment.kind != nkExprColonExpr:
      invalidObjConstr(c, assignment)
      continue

    if fieldId == considerQuotedIdent(c, assignment[0]).id:
      return assignment

proc semConstrField(c: PContext, flags: TExprFlags,
                    field: PSym, initExpr: PNode): PNode =
  let assignment = locateFieldInInitExpr(c, field, initExpr)
  if assignment != nil:
    if nfSem in assignment.flags: return assignment[1]
    if not fieldVisible(c, field):
      localError(c.config, initExpr.info,
        "the field '$1' is not accessible." % [field.name.s])
      return

    var initValue = semExprFlagDispatched(c, assignment[1], flags)
    if initValue != nil:
      initValue = fitNode(c, field.typ, initValue, assignment.info)
    assignment[0] = newSymNode(field)
    assignment[1] = initValue
    assignment.flags.incl nfSem
    return initValue

proc branchVals(c: PContext, caseNode: PNode, caseIdx: int): IntSet =
  if caseNode[caseIdx].kind == nkOfBranch:
    result = initIntSet()
    for val in processBranchVals(caseNode[caseIdx]):
      result.incl(val)
  else:
    result = c.getIntSetOfType(caseNode[0].typ)
    for i in 1..<caseNode.len-1:
      for val in processBranchVals(caseNode[i]):
        result.excl(val)

proc findUsefulCaseContext(c: PContext, discrimator: PNode): (PNode, int) =
  for i in countdown(c.p.caseContext.high, 0):
    let
      (caseNode, index) = c.p.caseContext[i]
      skipped = caseNode[0].skipHidden
    if skipped.kind == nkSym and skipped.sym == discrimator.sym:
      return (caseNode, index)

proc caseBranchMatchesExpr(branch, matched: PNode): bool =
  for i in 0 ..< branch.len-1:
    if branch[i].kind == nkRange:
      if overlap(branch[i], matched): return true
    elif exprStructuralEquivalent(branch[i], matched):
      return true

proc pickCaseBranch(caseExpr, matched: PNode): int =
  let endsWithElse = caseExpr[^1].kind == nkElse
  for i in 1..<caseExpr.len - int(endsWithElse):
    if caseExpr[i].caseBranchMatchesExpr(matched):
      return i
  if endsWithElse:
    return caseExpr.len - 1

proc pickCaseBranches(caseExpr: PNode, c: PContext, possibleValues: IntSet): seq[int] =
  let endsWithElse = caseExpr[^1].kind == nkElse
  var remaining = possibleValues
  for i in 1 ..< caseExpr.len - int(endsWithElse):
    let b = branchVals(c, caseExpr, i)
    if len(remaining * b) != 0:
      result.add i
    else:
      discard "Nothing to do, lets see if the next one matches"
    remaining = remaining - b
  if (remaining.len != 0) and endsWithElse: #and result.len == 0:
    result.add caseExpr.len - 1

iterator directFieldsInRecList(recList: PNode): PNode =
  # XXX: We can remove this case by making all nkOfBranch nodes
  # regular. Currently, they try to avoid using nkRecList if they
  # include only a single field
  if recList.kind == nkSym:
    yield recList
  else:
    doAssert recList.kind == nkRecList
    for field in recList:
      if field.kind != nkSym: continue
      yield field

proc fieldsPresentInInitExpr(c: PContext, fieldsRecList, initExpr: PNode): string =
  result = ""
  for field in directFieldsInRecList(fieldsRecList):
    let assignment = locateFieldInInitExpr(c, field.sym, initExpr)
    if assignment != nil:
      if result.len != 0: result.add ", "
      result.add "'" & field.sym.name.s & "'"

proc checkForMissingFields(c: PContext, recList, initExpr: PNode, considerDefaults: bool) =
  var missing: string
  for r in directFieldsInRecList(recList):
    if {tfNotNil, tfNeedsInit} * r.sym.typ.flags != {}:
      let assignment = locateFieldInInitExpr(c, r.sym, initExpr)
      if assignment == nil and not(considerDefaults and r.sym.ast != nil):
        if missing.len == 0:
          missing = r.sym.name.s
        else:
          missing.add ", "
          missing.add r.sym.name.s
  if missing.len > 0:
    localError(c.config, initExpr.info, "fields not initialized: $1.", [missing])

proc checkForNoExplicitlyDefinedFields(c: PContext, recList, initExpr: PNode) =
  var existing: string
  for r in directFieldsInRecList(recList):
    let assignment = locateFieldInInitExpr(c, r.sym, initExpr)
    if assignment != nil:
      if existing.len == 0:
        existing = r.sym.name.s
      else:
        existing.add ", "
        existing.add r.sym.name.s
  if existing.len > 0:
    localError(c.config, initExpr.info, "runtime discriminator could select " &
               "multiple branches, so you can't initialize these fields: $1", [existing])

proc semConstructFields(c: PContext, recNode, initExpr: PNode,
                        flags: TExprFlags): tuple[status: InitStatus, defaults: seq[PNode]] =
  case recNode.kind
  of nkRecList:
    for field in recNode:
      let (subSt, subDf) = semConstructFields(c, field, initExpr, flags)
      result.status.mergeInitStatus subSt
      result.defaults.add subDf
  of nkRecCase:
    internalAssert c.config, recNode[0].kind == nkSym
    let discriminator = recNode[0]
    var discriminatorVal = semConstrField(c, flags + {efPreferStatic}, discriminator.sym, initExpr)
    let defaultValue = discriminator.sym.ast
    var selectedBranches: seq[int]

    if discriminatorVal == nil:
      if defaultValue == nil:
        # None of the branches were explicitly selected by the user and no value
        # was given to the discrimator. We can assume that it will be initialized
        # to zero and this will select a particular branch as a result:
        selectedBranches = @[recNode.pickCaseBranch newIntLit(c.graph, initExpr.info, 0)]
      else:
        # Try to use default value
        discriminatorVal = defaultValue
        selectedBranches = @[recNode.pickCaseBranch defaultValue]
        result.defaults.add newTree(nkExprColonExpr, discriminator, discriminatorVal)
    else:
      discriminatorVal = discriminatorVal.skipHidden
      if discriminatorVal.kind == nkIntLit:
        # Discriminator is a compile-time value, we know which branch will be selected
        selectedBranches = @[recNode.pickCaseBranch discriminatorVal]
        assert selectedBranches[0] != 0 #TODO: Proper error 
      else:
        if lengthOrd(c.config, discriminatorVal.typ) > BiggestInt(MaxSetElements):
          localError(c.config, discriminatorVal.info, "branch initialization with a runtime " &
                     "discriminator only supports ordinal types with 2^16 elements or less.")
        var possibleValues = c.getIntSetOfType(discriminatorVal.typ)
        let (ctorCase, ctorIdx) = findUsefulCaseContext(c, discriminatorVal)
        if ctorCase != nil and discriminatorVal.sym.kind in {skLet, skParam} and discriminatorVal.sym.typ.kind != tyVar:
          possibleValues = possibleValues * branchVals(c, ctorCase, ctorIdx)
        selectedBranches = recNode.pickCaseBranches(c, possibleValues)

    assert selectedBranches.len != 0 #XXX: Proper error, does this even occur?
    if selectedBranches.len == 1:
      let branch = recNode[selectedBranches[0]]
      #error for fields which require initialization and don't have a default
      checkForMissingFields(c, branch[^1], initExpr, considerDefaults = true)
      let (subSt, subDf) = semConstructFields(c, branch[^1], initExpr, flags)
      result.status.mergeInitStatus subSt
      result.defaults.add subDf
    else:
      for i in selectedBranches:
        assert i != 0
        let branch = recNode[i]
        if branch != nil:
          checkForNoExplicitlyDefinedFields(c, branch[^1], initExpr)
          #error for fields which require initialization no matter wether they have a default or not
          checkForMissingFields(c, branch[^1], initExpr, considerDefaults = false)
          discard semConstructFields(c, branch[^1], initExpr, flags)
          #TODO: error/warn for fields which don't require initialization but have a default
          #if subDf.len > 0: warn "Will not initalize branch fields to their default value"
      result.status = initNone
  of nkSym:
    let field = recNode.sym
    let e = semConstrField(c, flags, field, initExpr)
    if e != nil:
      result.status = initFull
    elif field.ast != nil:
      result.status = initUnknown
      result.defaults.add newTree(nkExprColonExpr, recNode, field.ast)
    else:
      result.status = initNone
  else:
    internalAssert c.config, false

proc semConstructType(c: PContext, initExpr: PNode,
                      t: PType, flags: TExprFlags): tuple[status: InitStatus, defaults: seq[PNode]] =
  var t = t
  while true:
    let (status, defaults) = semConstructFields(c, t.n, initExpr, flags)
    result.status.mergeInitStatus status
    result.defaults.add defaults
    if status in {initPartial, initNone, initUnknown}:
      checkForMissingFields c, t.n, initExpr, true
    let base = t[0]
    if base == nil: break
    t = skipTypes(base, skipPtrs)

proc semObjConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var t = semTypeNode(c, n[0], nil)
  result = newNodeIT(nkObjConstr, n.info, t)
  result.add newNodeIT(nkType, n.info, t) #This will contain the default values to be added in transf
  for i in 1..<n.len:
    result.add n[i]

  if t == nil:
    localError(c.config, n.info, errGenerated, "object constructor needs an object type")
    return

  t = skipTypes(t, {tyGenericInst, tyAlias, tySink, tyOwned})
  if t.kind == tyRef:
    t = skipTypes(t[0], {tyGenericInst, tyAlias, tySink, tyOwned})
    if optOwnedRefs in c.config.globalOptions:
      result.typ = makeVarType(c, result.typ, tyOwned)
      # we have to watch out, there are also 'owned proc' types that can be used
      # multiple times as long as they don't have closures.
      result.typ.flags.incl tfHasOwned
  if t.kind != tyObject:
    localError(c.config, n.info, errGenerated, "object constructor needs an object type")
    return

  # Check if the object is fully initialized by recursively testing each
  # field (if this is a case object, initialized fields in two different
  # branches will be reported as an error):
  let (initResult, defaults) = semConstructType(c, result, t, flags)

  result[0].sons.add defaults

  # It's possible that the object was not fully initialized while
  # specifying a .requiresInit. pragma.
  # XXX: Turn this into an error in the next release
  if tfNeedsInit in t.flags and initResult != initFull:
    # XXX: Disable this warning for now, because tfNeedsInit is propagated
    # too aggressively from fields to object types (and this is not correct
    # in case objects)
    when false: message(n.info, warnUser,
      "object type uses the 'requiresInit' pragma, but not all fields " &
      "have been initialized. future versions of Nim will treat this as " &
      "an error")

  # Since we were traversing the object fields, it's possible that
  # not all of the fields specified in the constructor was visited.
  # We'll check for such fields here:
  for i in 1..<result.len:
    let field = result[i]
    if nfSem notin field.flags:
      if field.kind != nkExprColonExpr:
        invalidObjConstr(c, field)
        continue
      let id = considerQuotedIdent(c, field[0])
      # This node was not processed. There are two possible reasons:
      # 1) It was shadowed by a field with the same name on the left
      for j in 1..<i:
        let prevId = considerQuotedIdent(c, result[j][0])
        if prevId.id == id.id:
          localError(c.config, field.info, errFieldInitTwice % id.s)
          return
      # 2) No such field exists in the constructed type
      localError(c.config, field.info, errUndeclaredFieldX % id.s)
      return
