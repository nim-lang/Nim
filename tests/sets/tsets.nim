discard """
output: '''
Ha ein F ist in s!
false
'''
"""
# Test the handling of sets

import
  strutils

proc testSets(s: var set[char]) =
  s = {'A', 'B', 'C', 'E'..'G'} + {'Z'} + s

# test sets if the first element is different from 0:
type
  TAZ = range['a'..'z']
  TAZset = set[TAZ]

  TTokType* = enum
    tkInvalid, tkEof,
    tkSymbol,
    tkAddr, tkAnd, tkAs, tkAsm, tkBlock, tkBreak, tkCase, tkCast, tkConst,
    tkContinue, tkConverter, tkDiscard, tkDiv, tkElif, tkElse, tkEnd, tkEnum,
    tkExcept, tkException, tkFinally, tkFor, tkFrom, tkGeneric, tkIf, tkImplies,
    tkImport, tkIn, tkInclude, tkIs, tkIsnot, tkIterator, tkLambda, tkMacro,
    tkMethod, tkMod, tkNil, tkNot, tkNotin, tkObject, tkOf, tkOr, tkOut, tkProc,
    tkPtr, tkRaise, tkRecord, tkRef, tkReturn, tkShl, tkShr, tkTemplate, tkTry,
    tkType, tkVar, tkWhen, tkWhere, tkWhile, tkWith, tkWithout, tkXor, tkYield,
    tkIntLit, tkInt8Lit, tkInt16Lit, tkInt32Lit, tkInt64Lit, tkFloatLit,
    tkFloat32Lit, tkFloat64Lit, tkStrLit, tkRStrLit, tkTripleStrLit, tkCharLit,
    tkRCharLit, tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe,
    tkCurlyRi, tkBracketDotLe, tkBracketDotRi,
    tkCurlyDotLe, tkCurlyDotRi,
    tkParDotLe, tkParDotRi,
    tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot, tkHat, tkOpr,
    tkComment, tkAccent, tkInd, tkSad, tkDed,
    tkSpaces, tkInfixOpr, tkPrefixOpr, tkPostfixOpr
  TTokTypeRange = range[tkSymbol..tkDed]
  TTokTypes* = set[TTokTypeRange]

const
  toktypes: TTokTypes = {TTokTypeRange(tkSymbol)..pred(tkIntLit),
                         tkStrLit..tkTripleStrLit}

var
  s: set[char]
  a: TAZset
s = {'0'..'9'}
testSets(s)
if 'F' in s: write(stdout, "Ha ein F ist in s!\n")
else: write(stdout, "BUG: F ist nicht in s!\n")
a = {} #{'a'..'z'}
for x in low(TAZ) .. high(TAZ):
  incl(a, x)
  if x in a: discard
  else: write(stdout, "BUG: something not in a!\n")

for x in low(TTokTypeRange) .. high(TTokTypeRange):
  if x in tokTypes:
    discard
    #writeLine(stdout, "the token '$1' is in the set" % repr(x))

#OUT Ha ein F ist in s!


type
  TMsgKind* = enum
    errUnknown, errIllFormedAstX, errInternal, errCannotOpenFile, errGenerated,
    errXCompilerDoesNotSupportCpp, errStringLiteralExpected,
    errIntLiteralExpected, errInvalidCharacterConstant,
    errClosingTripleQuoteExpected, errClosingQuoteExpected,
    errTabulatorsAreNotAllowed, errInvalidToken, errLineTooLong,
    errInvalidNumber, errNumberOutOfRange, errNnotAllowedInCharacter,
    errClosingBracketExpected, errMissingFinalQuote, errIdentifierExpected,
    errNewlineExpected,
    errInvalidModuleName,
    errOperatorExpected, errTokenExpected, errStringAfterIncludeExpected,
    errRecursiveDependencyX, errOnOrOffExpected, errNoneSpeedOrSizeExpected,
    errInvalidPragma, errUnknownPragma, errInvalidDirectiveX,
    errAtPopWithoutPush, errEmptyAsm, errInvalidIndentation,
    errExceptionExpected, errExceptionAlreadyHandled,
    errYieldNotAllowedHere, errYieldNotAllowedInTryStmt,
    errInvalidNumberOfYieldExpr, errCannotReturnExpr, errAttemptToRedefine,
    errStmtInvalidAfterReturn, errStmtExpected, errInvalidLabel,
    errInvalidCmdLineOption, errCmdLineArgExpected, errCmdLineNoArgExpected,
    errInvalidVarSubstitution, errUnknownVar, errUnknownCcompiler,
    errOnOrOffExpectedButXFound, errNoneBoehmRefcExpectedButXFound,
    errNoneSpeedOrSizeExpectedButXFound, errGuiConsoleOrLibExpectedButXFound,
    errUnknownOS, errUnknownCPU, errGenOutExpectedButXFound,
    errArgsNeedRunOption, errInvalidMultipleAsgn, errColonOrEqualsExpected,
    errExprExpected, errUndeclaredIdentifier, errUseQualifier, errTypeExpected,
    errSystemNeeds, errExecutionOfProgramFailed, errNotOverloadable,
    errInvalidArgForX, errStmtHasNoEffect, errXExpectsTypeOrValue,
    errXExpectsArrayType, errIteratorCannotBeInstantiated, errExprXAmbiguous,
    errConstantDivisionByZero, errOrdinalTypeExpected,
    errOrdinalOrFloatTypeExpected, errOverOrUnderflow,
    errCannotEvalXBecauseIncompletelyDefined, errChrExpectsRange0_255,
    errDynlibRequiresExportc, errUndeclaredFieldX, errNilAccess,
    errIndexOutOfBounds, errIndexTypesDoNotMatch, errBracketsInvalidForType,
    errValueOutOfSetBounds, errFieldInitTwice, errFieldNotInit,
    errExprXCannotBeCalled, errExprHasNoType, errExprXHasNoType,
    errCastNotInSafeMode, errExprCannotBeCastedToX, errCommaOrParRiExpected,
    errCurlyLeOrParLeExpected, errSectionExpected, errRangeExpected,
    errMagicOnlyInSystem, errPowerOfTwoExpected,
    errStringMayNotBeEmpty, errCallConvExpected, errProcOnlyOneCallConv,
    errSymbolMustBeImported, errExprMustBeBool, errConstExprExpected,
    errDuplicateCaseLabel, errRangeIsEmpty, errSelectorMustBeOfCertainTypes,
    errSelectorMustBeOrdinal, errOrdXMustNotBeNegative, errLenXinvalid,
    errWrongNumberOfVariables, errExprCannotBeRaised, errBreakOnlyInLoop,
    errTypeXhasUnknownSize, errConstNeedsConstExpr, errConstNeedsValue,
    errResultCannotBeOpenArray, errSizeTooBig, errSetTooBig,
    errBaseTypeMustBeOrdinal, errInheritanceOnlyWithNonFinalObjects,
    errInheritanceOnlyWithEnums, errIllegalRecursionInTypeX,
    errCannotInstantiateX, errExprHasNoAddress, errXStackEscape,
    errVarForOutParamNeeded,
    errPureTypeMismatch, errTypeMismatch, errButExpected, errButExpectedX,
    errAmbiguousCallXYZ, errWrongNumberOfArguments,
    errXCannotBePassedToProcVar,
    errXCannotBeInParamDecl, errPragmaOnlyInHeaderOfProc, errImplOfXNotAllowed,
    errImplOfXexpected, errNoSymbolToBorrowFromFound, errDiscardValueX,
    errInvalidDiscard, errIllegalConvFromXtoY, errCannotBindXTwice,
    errInvalidOrderInArrayConstructor,
    errInvalidOrderInEnumX, errEnumXHasHoles, errExceptExpected, errInvalidTry,
    errOptionExpected, errXisNoLabel, errNotAllCasesCovered,
    errUnknownSubstitionVar, errComplexStmtRequiresInd, errXisNotCallable,
    errNoPragmasAllowedForX, errNoGenericParamsAllowedForX,
    errInvalidParamKindX, errDefaultArgumentInvalid, errNamedParamHasToBeIdent,
    errNoReturnTypeForX, errConvNeedsOneArg, errInvalidPragmaX,
    errXNotAllowedHere, errInvalidControlFlowX,
    errXisNoType, errCircumNeedsPointer, errInvalidExpression,
    errInvalidExpressionX, errEnumHasNoValueX, errNamedExprExpected,
    errNamedExprNotAllowed, errXExpectsOneTypeParam,
    errArrayExpectsTwoTypeParams, errInvalidVisibilityX, errInitHereNotAllowed,
    errXCannotBeAssignedTo, errIteratorNotAllowed, errXNeedsReturnType,
    errNoReturnTypeDeclared,
    errInvalidCommandX, errXOnlyAtModuleScope,
    errXNeedsParamObjectType,
    errTemplateInstantiationTooNested, errInstantiationFrom,
    errInvalidIndexValueForTuple, errCommandExpectsFilename,
    errMainModuleMustBeSpecified,
    errXExpected,
    errTIsNotAConcreteType,
    errInvalidSectionStart, errGridTableNotImplemented, errGeneralParseError,
    errNewSectionExpected, errWhitespaceExpected, errXisNoValidIndexFile,
    errCannotRenderX, errVarVarTypeNotAllowed, errInstantiateXExplicitly,
    errOnlyACallOpCanBeDelegator, errUsingNoSymbol,
    errMacroBodyDependsOnGenericTypes,
    errDestructorNotGenericEnough,
    errInlineIteratorsAsProcParams,
    errXExpectsTwoArguments,
    errXExpectsObjectTypes, errXcanNeverBeOfThisSubtype, errTooManyIterations,
    errCannotInterpretNodeX, errFieldXNotFound, errInvalidConversionFromTypeX,
    errAssertionFailed, errCannotGenerateCodeForX, errXRequiresOneArgument,
    errUnhandledExceptionX, errCyclicTree, errXisNoMacroOrTemplate,
    errXhasSideEffects, errIteratorExpected, errLetNeedsInit,
    errThreadvarCannotInit, errWrongSymbolX, errIllegalCaptureX,
    errXCannotBeClosure, errXMustBeCompileTime,
    errCannotInferTypeOfTheLiteral,
    errCannotInferReturnType,
    errGenericLambdaNotAllowed,
    errCompilerDoesntSupportTarget,
    errUser,
    warnCannotOpenFile,
    warnOctalEscape, warnXIsNeverRead, warnXmightNotBeenInit,
    warnDeprecated, warnConfigDeprecated,
    warnSmallLshouldNotBeUsed, warnUnknownMagic, warnRedefinitionOfLabel,
    warnUnknownSubstitutionX, warnLanguageXNotSupported,
    warnFieldXNotSupported, warnCommentXIgnored,
    warnNilStatement, warnTypelessParam,
    warnDifferentHeaps, warnWriteToForeignHeap, warnUnsafeCode,
    warnEachIdentIsTuple,
    warnProveInit, warnProveField, warnProveIndex, warnGcUnsafe, warnGcUnsafe2,
    warnUninit, warnGcMem, warnDestructor, warnLockLevel, warnResultShadowed,
    warnUser,
    hintSuccess, hintSuccessX,
    hintLineTooLong, hintXDeclaredButNotUsed, hintConvToBaseNotNeeded,
    hintConvFromXtoItselfNotNeeded, hintExprAlwaysX, hintQuitCalled,
    hintProcessing, hintCodeBegin, hintCodeEnd, hintConf, hintPath,
    hintConditionAlwaysTrue, hintName, hintPattern,
    hintUser

const
  fatalMin* = errUnknown
  fatalMax* = errInternal
  errMin* = errUnknown
  errMax* = errUser
  warnMin* = warnCannotOpenFile
  warnMax* = pred(hintSuccess)
  hintMin* = hintSuccess
  hintMax* = high(TMsgKind)

type
  TNoteKind* = range[warnMin..hintMax] # "notes" are warnings or hints
  TNoteKinds* = set[TNoteKind]

var
  gNotes*: TNoteKinds = {low(TNoteKind)..high(TNoteKind)} -
                        {warnUninit, warnProveField, warnProveIndex, warnGcUnsafe}


#import compiler.msgs

echo warnUninit in gNotes

# 7555
doAssert {-1.int8, -2, -2}.card == 2
doAssert {1, 2, 2, 3..5, 4..6}.card == 6

type Foo = enum
  Foo1 = 0
  Foo2 = 1
  Foo3 = 3

let x = { Foo1, Foo2 }
# bug #8425
