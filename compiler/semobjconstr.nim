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

proc caseBranchMatchesExpr(branch, matched: PNode): bool =
  for i in 0..<branch.len-1:
    if branch[i].kind == nkRange:
      if overlap(branch[i], matched): return true
    elif exprStructuralEquivalent(branch[i], matched):
      return true

  return false

proc branchVals(c: PContext, caseNode: PNode, caseIdx: int,
                isStmtBranch: bool): IntSet =
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

proc pickCaseBranch(caseExpr, matched: PNode): PNode =
  # XXX: Perhaps this proc already exists somewhere
  let endsWithElse = caseExpr[^1].kind == nkElse
  for i in 1..<caseExpr.len - int(endsWithElse):
    if caseExpr[i].caseBranchMatchesExpr(matched):
      return caseExpr[i]

  if endsWithElse:
    return caseExpr[^1]

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

template quoteStr(s: string): string = "'" & s & "'"

proc fieldsPresentInInitExpr(c: PContext, fieldsRecList, initExpr: PNode): string =
  result = ""
  for field in directFieldsInRecList(fieldsRecList):
    let assignment = locateFieldInInitExpr(c, field.sym, initExpr)
    if assignment != nil:
      if result.len != 0: result.add ", "
      result.add field.sym.name.s.quoteStr

proc missingMandatoryFields(c: PContext, fieldsRecList, initExpr: PNode): string =
  for r in directFieldsInRecList(fieldsRecList):
    if {tfNotNil, tfNeedsInit} * r.sym.typ.flags != {}:
      let assignment = locateFieldInInitExpr(c, r.sym, initExpr)
      if assignment == nil:
        if result.len == 0:
          result = r.sym.name.s
        else:
          result.add ", "
          result.add r.sym.name.s

proc checkForMissingFields(c: PContext, recList, initExpr: PNode) =
  let missing = missingMandatoryFields(c, recList, initExpr)
  if missing.len > 0:
    localError(c.config, initExpr.info, "fields not initialized: $1.", [missing])

proc semConstructFields(c: PContext, recNode: PNode,
                        initExpr: PNode, flags: TExprFlags): InitStatus =
  result = initUnknown

  case recNode.kind
  of nkRecList:
    for field in recNode:
      let status = semConstructFields(c, field, initExpr, flags)
      mergeInitStatus(result, status)

  of nkRecCase:
    template fieldsPresentInBranch(branchIdx: int): string =
      let branch = recNode[branchIdx]
      let fields = branch[^1]
      fieldsPresentInInitExpr(c, fields, initExpr)

    template checkMissingFields(branchNode: PNode) =
      if branchNode != nil:
        let fields = branchNode[^1]
        checkForMissingFields(c, fields, initExpr)

    let discriminator = recNode[0]
    internalAssert c.config, discriminator.kind == nkSym
    var selectedBranch = -1

    for i in 1..<recNode.len:
      let innerRecords = recNode[i][^1]
      let status = semConstructFields(c, innerRecords, initExpr, flags)
      if status notin {initNone, initUnknown}:
        mergeInitStatus(result, status)
        if selectedBranch != -1:
          let prevFields = fieldsPresentInBranch(selectedBranch)
          let currentFields = fieldsPresentInBranch(i)
          localError(c.config, initExpr.info,
            ("The fields '$1' and '$2' cannot be initialized together, " &
            "because they are from conflicting branches in the case object.") %
            [prevFields, currentFields])
          result = initConflict
        else:
          selectedBranch = i

    if selectedBranch != -1:
      template badDiscriminatorError =
        let fields = fieldsPresentInBranch(selectedBranch)
        localError(c.config, initExpr.info,
          ("cannot prove that it's safe to initialize $1 with " &
          "the runtime value for the discriminator '$2' ") %
          [fields, discriminator.sym.name.s])
        mergeInitStatus(result, initNone)

      template wrongBranchError(i) =
        let fields = fieldsPresentInBranch(i)
        localError(c.config, initExpr.info,
          "a case selecting discriminator '$1' with value '$2' " &
          "appears in the object construction, but the field(s) $3 " &
          "are in conflict with this value.",
          [discriminator.sym.name.s, discriminatorVal.renderTree, fields])

      template valuesInConflictError(valsDiff) =
        localError(c.config, discriminatorVal.info, ("possible values " &
          "$2 are in conflict with discriminator values for " &
          "selected object branch $1.") % [$selectedBranch,
          valsDiff.renderAsType(recNode[0].typ)])

      let branchNode = recNode[selectedBranch]
      let flags = flags*{efAllowDestructor} + {efPreferStatic,
                                               efPreferNilResult}
      var discriminatorVal = semConstrField(c, flags,
                                            discriminator.sym, initExpr)
      if discriminatorVal != nil:
        discriminatorVal = discriminatorVal.skipHidden
        if discriminatorVal.kind notin nkLiterals and (
            not isOrdinalType(discriminatorVal.typ, true) or
            lengthOrd(c.config, discriminatorVal.typ) > MaxSetElements or
            lengthOrd(c.config, recNode[0].typ) > MaxSetElements):
          localError(c.config, discriminatorVal.info,
            "branch initialization with a runtime discriminator only " &
            "supports ordinal types with 2^16 elements or less.")

      if discriminatorVal == nil:
        badDiscriminatorError()
      elif discriminatorVal.kind == nkSym:
        let (ctorCase, ctorIdx) = findUsefulCaseContext(c, discriminatorVal)
        if ctorCase == nil:
          if discriminatorVal.typ.kind == tyRange:
            let rangeVals = c.getIntSetOfType(discriminatorVal.typ)
            let recBranchVals = branchVals(c, recNode, selectedBranch, false)
            let diff = rangeVals - recBranchVals
            if diff.len != 0:
              valuesInConflictError(diff)
          else:
            badDiscriminatorError()
        elif discriminatorVal.sym.kind notin {skLet, skParam} or
            discriminatorVal.sym.typ.kind == tyVar:
          localError(c.config, discriminatorVal.info,
            "runtime discriminator must be immutable if branch fields are " &
            "initialized, a 'let' binding is required.")
        elif ctorCase[ctorIdx].kind == nkElifBranch:
          localError(c.config, discriminatorVal.info, "branch initialization " &
            "with a runtime discriminator is not supported inside of an " &
            "`elif` branch.")
        else:
          var
            ctorBranchVals = branchVals(c, ctorCase, ctorIdx, true)
            recBranchVals = branchVals(c, recNode, selectedBranch, false)
            branchValsDiff = ctorBranchVals - recBranchVals
          if branchValsDiff.len != 0:
            valuesInConflictError(branchValsDiff)
      else:
        var failedBranch = -1
        if branchNode.kind != nkElse:
          if not branchNode.caseBranchMatchesExpr(discriminatorVal):
            failedBranch = selectedBranch
        else:
          # With an else clause, check that all other branches don't match:
          for i in 1..<recNode.len - 1:
            if recNode[i].caseBranchMatchesExpr(discriminatorVal):
              failedBranch = i
              break
        if failedBranch != -1:
          if discriminatorVal.typ.kind == tyRange:
            let rangeVals = c.getIntSetOfType(discriminatorVal.typ)
            let recBranchVals = branchVals(c, recNode, selectedBranch, false)
            let diff = rangeVals - recBranchVals
            if diff.len != 0:
              valuesInConflictError(diff)
          else:
            wrongBranchError(failedBranch)

      # When a branch is selected with a partial match, some of the fields
      # that were not initialized may be mandatory. We must check for this:
      if result == initPartial:
        checkMissingFields branchNode

    else:
      result = initNone
      let discriminatorVal = semConstrField(c, flags + {efPreferStatic},
                                            discriminator.sym, initExpr)
      if discriminatorVal == nil:
        # None of the branches were explicitly selected by the user and no
        # value was given to the discrimator. We can assume that it will be
        # initialized to zero and this will select a particular branch as
        # a result:
        let matchedBranch = recNode.pickCaseBranch newIntLit(c.graph, initExpr.info, 0)
        checkMissingFields matchedBranch
      else:
        result = initPartial
        if discriminatorVal.kind == nkIntLit:
          # When the discriminator is a compile-time value, we also know
          # which branch will be selected:
          let matchedBranch = recNode.pickCaseBranch discriminatorVal
          if matchedBranch != nil: checkMissingFields matchedBranch
        else:
          # All bets are off. If any of the branches has a mandatory
          # fields we must produce an error:
          for i in 1..<recNode.len: checkMissingFields recNode[i]

  of nkSym:
    let field = recNode.sym
    let e = semConstrField(c, flags, field, initExpr)
    result = if e != nil: initFull else: initNone

  else:
    internalAssert c.config, false

proc semConstructType(c: PContext, initExpr: PNode,
                      t: PType, flags: TExprFlags): InitStatus =
  var t = t
  result = initUnknown
  while true:
    let status = semConstructFields(c, t.n, initExpr, flags)
    mergeInitStatus(result, status)
    if status in {initPartial, initNone, initUnknown}:
      checkForMissingFields c, t.n, initExpr
    let base = t[0]
    if base == nil: break
    t = skipTypes(base, skipPtrs)

proc semObjConstr(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var t = semTypeNode(c, n[0], nil)
  result = newNodeIT(nkObjConstr, n.info, t)
  for child in n: result.add child

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
  let initResult = semConstructType(c, result, t, flags)

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
