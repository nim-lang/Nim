discard """
  output: ""
"""

# bug #2880

type
  TMsgKind* = enum
    errUnknown, errIllFormedAstX, errInternal, errCannotOpenFile, errGenerated,
    errXCompilerDoesNotSupportCpp, errStringLiteralExpected,
    errIntLiteralExpected, errInvalidCharacterConstant,
    errClosingTripleQuoteExpected, errClosingQuoteExpected,
    errTabulatorsAreNotAllowed, errInvalidToken, errLineTooLong,
    errInvalidNumber, errInvalidNumberOctalCode, errNumberOutOfRange,
    errNnotAllowedInCharacter, errClosingBracketExpected, errMissingFinalQuote,
    errIdentifierExpected, errNewlineExpected, errInvalidModuleName,
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
    errOnOrOffExpectedButXFound, errOnOffOrListExpectedButXFound,
    errNoneBoehmRefcExpectedButXFound,
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
    warnEachIdentIsTuple
    warnProveInit, warnProveField, warnProveIndex, warnGcUnsafe, warnGcUnsafe2,
    warnUninit, warnGcMem, warnDestructor, warnLockLevel, warnResultShadowed,
    warnUser,
    hintSuccess, hintSuccessX,
    hintLineTooLong, hintXDeclaredButNotUsed, hintConvToBaseNotNeeded,
    hintConvFromXtoItselfNotNeeded, hintExprAlwaysX, hintQuitCalled,
    hintProcessing, hintCodeBegin, hintCodeEnd, hintConf, hintPath,
    hintConditionAlwaysTrue, hintName, hintPattern,
    hintExecuting, hintLinking, hintDependency,
    hintSource, hintStackTrace, hintGCStats,
    hintUser

const
  warnMin = warnCannotOpenFile
  hintMax = high(TMsgKind)

type
  TNoteKind = range[warnMin..hintMax] # "notes" are warnings or hints
  TNoteKinds = set[TNoteKind]

const
  NotesVerbosityConst: array[0..0, TNoteKinds] = [
    {low(TNoteKind)..high(TNoteKind)} - {hintGCStats}]
  fuckyou = NotesVerbosityConst[0]

var
  gNotesFromConst: TNoteKinds = NotesVerbosityConst[0]
  gNotesFromConst2: TNoteKinds = fuckyou

if hintGCStats in gNotesFromConst:
  echo "hintGCStats in gNotesFromConst A"

if hintGCStats in gNotesFromConst2:
  echo "hintGCStats in gNotesFromConst B"
