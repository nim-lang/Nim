discard """
errormsg: '''
not all cases are covered, missing: nnkComesFrom, nnkDotCall, nnkHiddenCallConv, nnkVarTuple, nnkCurlyExpr, nnkRange, nnkCheckedFieldExpr, nnkDerefExpr, nnkElifExpr, nnkElseExpr, nnkLambda, nnkDo, nnkBind, nnkClosedSymChoice, nnkHiddenSubConv, nnkConv, nnkStaticExpr, nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv, nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange, nnkStringToCString, nnkCStringToString, nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit, nnkImportAs, nnkConverterDef, nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse, nnkAsmStmt, nnkTypeDef, nnkFinally, nnkContinueStmt, nnkImportStmt, nnkImportExceptStmt, nnkExportStmt, nnkExportExceptStmt, nnkFromStmt, nnkIncludeStmt, nnkUsingStmt, nnkBlockExpr, nnkStmtListType, nnkBlockType, nnkWith, nnkWithout, nnkTypeOfExpr, nnkObjectTy, nnkTupleTy, nnkTupleClassTy, nnkTypeClassTy, nnkStaticTy, nnkRecList, nnkRecCase, nnkRecWhen, nnkVarTy, nnkConstTy, nnkMutableTy, nnkDistinctTy, nnkProcTy, nnkIteratorTy, nnkSharedTy, nnkEnumTy, nnkEnumFieldDef, nnkArglist, nnkPattern, nnkReturnToken, nnkClosure, nnkGotoState, nnkState, nnkBreakState, nnkFuncDef, nnkTupleConstr
'''
"""

import macros

type
  MyFictionalType = object
    a: int
    case n: NimNodeKind
    of nnkLiterals, nnkCommentStmt, nnkNone, nnkEmpty, nnkIdent, nnkSym,
       nnkType, nnkBindStmt, nnkMixinStmt, nnkTypeSection, nnkPragmaBlock,
       nnkPragmaExpr, nnkPragma, nnkBreakStmt, nnkCallStrLit, nnkPostfix,
       nnkOpenSymChoice:
      b: int
    of nnkCall, nnkCommand:
      c: int
    of nnkReturnStmt:
      d: int
    of nnkForStmt, nnkParForStmt, nnkWhileStmt, nnkProcDef, nnkMethodDef:
      e: int
    of nnkStmtList, nnkStmtListExpr, nnkDiscardStmt, nnkVarSection, nnkLetSection,
       nnkConstSection, nnkPar, nnkAccQuoted, nnkAsgn, nnkDefer, nnkCurly, nnkBracket,
       nnkStaticStmt, nnkTableConstr, nnkExprColonExpr, nnkInfix, nnkPrefix,
       nnkRaiseStmt, nnkYieldStmt, nnkBracketExpr, nnkDotExpr, nnkCast, nnkBlockStmt,
       nnkExprEqExpr, nnkRefTy, nnkPtrTy, nnkHiddenStdConv:
      f: int
    of nnkObjConstr:
      g: int
    of nnkIfStmt, nnkIfExpr, nnkWhenStmt:
      # if when and case statements are branching statements. So a
      # single function call is allowed to be in all of the braches and
      # the entire expression can still be considered as a forwarding
      # template.
      h: int
    of nnkCaseStmt:
      i: int
    of nnkTryStmt:
      j: int
    of nnkIdentDefs:
      k: int
    of nnkConstDef:
      l: int
