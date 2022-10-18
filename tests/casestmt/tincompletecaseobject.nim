discard """
errormsg: '''
not all cases are covered; missing: {nnkComesFrom, nnkDotCall, nnkHiddenCallConv, nnkVarTuple, nnkCurlyExpr, nnkRange, nnkCheckedFieldExpr, nnkDerefExpr, nnkElifExpr, nnkElseExpr, nnkLambda, nnkDo, nnkBind, nnkClosedSymChoice, nnkHiddenSubConv, nnkConv, nnkStaticExpr, nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv, nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange, nnkStringToCString, nnkCStringToString, nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit, nnkImportAs, nnkConverterDef, nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse, nnkAsmStmt, nnkTypeDef, nnkFinally, nnkContinueStmt, nnkImportStmt, nnkImportExceptStmt, nnkExportStmt, nnkExportExceptStmt, nnkFromStmt, nnkIncludeStmt, nnkUsingStmt, nnkBlockExpr, nnkStmtListType, nnkBlockType, nnkWith, nnkWithout, nnkTypeOfExpr, nnkObjectTy, nnkTupleTy, nnkTupleClassTy, nnkTypeClassTy, nnkStaticTy, nnkRecList, nnkRecCase, nnkRecWhen, nnkVarTy, nnkConstTy, nnkMutableTy, nnkDistinctTy, nnkProcTy, nnkIteratorTy, nnkSharedTy, nnkEnumTy, nnkEnumFieldDef, nnkArgList, nnkPattern, nnkReturnToken, nnkClosure, nnkGotoState, nnkState, nnkBreakState, nnkFuncDef, nnkTupleConstr}
'''
"""

# this isn't imported from macros.nim to make it robust against possible changes in the ast.

type
  NimNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym,
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit,
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkUIntLit, nnkUInt8Lit,
    nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit, nnkFloatLit,
    nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit, nnkStrLit, nnkRStrLit,
    nnkTripleStrLit, nnkNilLit, nnkComesFrom, nnkDotCall,
    nnkCommand, nnkCall, nnkCallStrLit, nnkInfix,
    nnkPrefix, nnkPostfix, nnkHiddenCallConv,
    nnkExprEqExpr,
    nnkExprColonExpr, nnkIdentDefs, nnkVarTuple,
    nnkPar, nnkObjConstr, nnkCurly, nnkCurlyExpr,
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange,
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr,
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkDo, nnkAccQuoted,
    nnkTableConstr, nnkBind,
    nnkClosedSymChoice,
    nnkOpenSymChoice,
    nnkHiddenStdConv,
    nnkHiddenSubConv, nnkConv, nnkCast, nnkStaticExpr,
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv,
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange,
    nnkStringToCString, nnkCStringToString, nnkAsgn,
    nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit,
    nnkImportAs, nnkProcDef, nnkMethodDef, nnkConverterDef,
    nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch,
    nnkElifBranch, nnkExceptBranch, nnkElse,
    nnkAsmStmt, nnkPragma, nnkPragmaBlock, nnkIfStmt, nnkWhenStmt,
    nnkForStmt, nnkParForStmt, nnkWhileStmt, nnkCaseStmt,
    nnkTypeSection, nnkVarSection, nnkLetSection, nnkConstSection,
    nnkConstDef, nnkTypeDef,
    nnkYieldStmt, nnkDefer, nnkTryStmt, nnkFinally, nnkRaiseStmt,
    nnkReturnStmt, nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, nnkStaticStmt,
    nnkDiscardStmt, nnkStmtList,
    nnkImportStmt = 1337, # make a hole just for fun
    nnkImportExceptStmt,
    nnkExportStmt,
    nnkExportExceptStmt,
    nnkFromStmt,
    nnkIncludeStmt,
    nnkBindStmt, nnkMixinStmt, nnkUsingStmt,
    nnkCommentStmt, nnkStmtListExpr, nnkBlockExpr,
    nnkStmtListType, nnkBlockType,
    nnkWith, nnkWithout,
    nnkTypeOfExpr, nnkObjectTy,
    nnkTupleTy, nnkTupleClassTy, nnkTypeClassTy, nnkStaticTy,
    nnkRecList, nnkRecCase, nnkRecWhen,
    nnkRefTy, nnkPtrTy, nnkVarTy,
    nnkConstTy, nnkMutableTy,
    nnkDistinctTy,
    nnkProcTy,
    nnkIteratorTy,         # iterator type
    nnkSharedTy,           # 'shared T'
    nnkEnumTy,
    nnkEnumFieldDef,
    nnkArgList, nnkPattern
    nnkReturnToken,
    nnkClosure,
    nnkGotoState,
    nnkState,
    nnkBreakState,
    nnkFuncDef,
    nnkTupleConstr

const
  nnkLiterals* = {nnkCharLit..nnkNilLit}

  nnkSomething* = {nnkStmtList, nnkStmtListExpr, nnkDiscardStmt, nnkVarSection, nnkLetSection,
       nnkConstSection, nnkPar, nnkAccQuoted, nnkAsgn, nnkDefer, nnkCurly, nnkBracket,
       nnkStaticStmt, nnkTableConstr, nnkExprColonExpr, nnkInfix, nnkPrefix,
       nnkRaiseStmt, nnkYieldStmt, nnkBracketExpr, nnkDotExpr, nnkCast, nnkBlockStmt,
       nnkExprEqExpr}

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
    of nnkSomething, nnkRefTy, nnkPtrTy, nnkHiddenStdConv:
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
