#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  options, strutils, os, tables, ropes, platform, terminal, macros

type
  TMsgKind* = enum
    errUnknown, errInternal, errIllFormedAstX, errCannotOpenFile, errGenerated,
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
    errInvalidNumberOfYieldExpr, errCannotReturnExpr,
    errNoReturnWithReturnTypeNotAllowed, errAttemptToRedefine,
    errStmtInvalidAfterReturn, errStmtExpected, errInvalidLabel,
    errInvalidCmdLineOption, errCmdLineArgExpected, errCmdLineNoArgExpected,
    errInvalidVarSubstitution, errUnknownVar, errUnknownCcompiler,
    errOnOrOffExpectedButXFound, errOnOffOrListExpectedButXFound,
    errNoneBoehmRefcExpectedButXFound,
    errNoneSpeedOrSizeExpectedButXFound, errGuiConsoleOrLibExpectedButXFound,
    errUnknownOS, errUnknownCPU, errGenOutExpectedButXFound,
    errArgsNeedRunOption, errInvalidMultipleAsgn, errColonOrEqualsExpected,
    errExprExpected, errUndeclaredField,
    errUndeclaredRoutine, errUseQualifier,
    errTypeExpected,
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
    errCastNotInSafeMode, errExprCannotBeCastToX, errCommaOrParRiExpected,
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
    errVarForOutParamNeededX,
    errPureTypeMismatch, errTypeMismatch, errButExpected, errButExpectedX,
    errAmbiguousCallXYZ, errWrongNumberOfArguments,
    errWrongNumberOfArgumentsInCall,
    errMissingGenericParamsForTemplate,
    errXCannotBePassedToProcVar,
    errXCannotBeInParamDecl, errPragmaOnlyInHeaderOfProcX, errImplOfXNotAllowed,
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
    errNoCommand, errInvalidCommandX, errXOnlyAtModuleScope,
    errXNeedsParamObjectType,
    errTemplateInstantiationTooNested, errInstantiationFrom,
    errInvalidIndexValueForTuple, errCommandExpectsFilename,
    errMainModuleMustBeSpecified,
    errXExpected,
    errTIsNotAConcreteType,
    errCastToANonConcreteType,
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
    errCannotInferStaticParam,
    errGenericLambdaNotAllowed,
    errProcHasNoConcreteType,
    errCompilerDoesntSupportTarget,
    errInOutFlagNotExtern,
    errUser,
    warnCannotOpenFile,
    warnOctalEscape, warnXIsNeverRead, warnXmightNotBeenInit,
    warnDeprecated, warnConfigDeprecated,
    warnSmallLshouldNotBeUsed, warnUnknownMagic, warnRedefinitionOfLabel,
    warnUnknownSubstitutionX, warnLanguageXNotSupported,
    warnFieldXNotSupported, warnCommentXIgnored,
    warnNilStatement, warnTypelessParam,
    warnUseBase, warnWriteToForeignHeap, warnUnsafeCode,
    warnEachIdentIsTuple, warnShadowIdent,
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
    hintUser, hintUserRaw

const
  MsgKindToStr*: array[TMsgKind, string] = [
    errUnknown: "unknown error",
    errInternal: "internal error: $1",
    errIllFormedAstX: "illformed AST: $1",
    errCannotOpenFile: "cannot open \'$1\'",
    errGenerated: "$1",
    errXCompilerDoesNotSupportCpp: "\'$1\' compiler does not support C++",
    errStringLiteralExpected: "string literal expected",
    errIntLiteralExpected: "integer literal expected",
    errInvalidCharacterConstant: "invalid character constant",
    errClosingTripleQuoteExpected: "closing \"\"\" expected, but end of file reached",
    errClosingQuoteExpected: "closing \" expected",
    errTabulatorsAreNotAllowed: "tabulators are not allowed",
    errInvalidToken: "invalid token: $1",
    errLineTooLong: "line too long",
    errInvalidNumber: "$1 is not a valid number",
    errInvalidNumberOctalCode: "$1 is not a valid number; did you mean octal? Then use one of '0o', '0c' or '0C'.",
    errNumberOutOfRange: "number $1 out of valid range",
    errNnotAllowedInCharacter: "\\n not allowed in character literal",
    errClosingBracketExpected: "closing ']' expected, but end of file reached",
    errMissingFinalQuote: "missing final \' for character literal",
    errIdentifierExpected: "identifier expected, but found \'$1\'",
    errNewlineExpected: "newline expected, but found \'$1\'",
    errInvalidModuleName: "invalid module name: '$1'",
    errOperatorExpected: "operator expected, but found \'$1\'",
    errTokenExpected: "\'$1\' expected",
    errStringAfterIncludeExpected: "string after \'include\' expected",
    errRecursiveDependencyX: "recursive dependency: \'$1\'",
    errOnOrOffExpected: "\'on\' or \'off\' expected",
    errNoneSpeedOrSizeExpected: "\'none\', \'speed\' or \'size\' expected",
    errInvalidPragma: "invalid pragma",
    errUnknownPragma: "unknown pragma: \'$1\'",
    errInvalidDirectiveX: "invalid directive: \'$1\'",
    errAtPopWithoutPush: "\'pop\' without a \'push\' pragma",
    errEmptyAsm: "empty asm statement",
    errInvalidIndentation: "invalid indentation",
    errExceptionExpected: "exception expected",
    errExceptionAlreadyHandled: "exception already handled",
    errYieldNotAllowedHere: "'yield' only allowed in an iterator",
    errYieldNotAllowedInTryStmt: "'yield' cannot be used within 'try' in a non-inlined iterator",
    errInvalidNumberOfYieldExpr: "invalid number of \'yield\' expressions",
    errCannotReturnExpr: "current routine cannot return an expression",
    errNoReturnWithReturnTypeNotAllowed: "routines with NoReturn pragma are not allowed to have return type",
    errAttemptToRedefine: "redefinition of \'$1\'",
    errStmtInvalidAfterReturn: "statement not allowed after \'return\', \'break\', \'raise\', \'continue\' or proc call with noreturn pragma",
    errStmtExpected: "statement expected",
    errInvalidLabel: "\'$1\' is no label",
    errInvalidCmdLineOption: "invalid command line option: \'$1\'",
    errCmdLineArgExpected: "argument for command line option expected: \'$1\'",
    errCmdLineNoArgExpected: "invalid argument for command line option: \'$1\'",
    errInvalidVarSubstitution: "invalid variable substitution in \'$1\'",
    errUnknownVar: "unknown variable: \'$1\'",
    errUnknownCcompiler: "unknown C compiler: \'$1\'",
    errOnOrOffExpectedButXFound: "\'on\' or \'off\' expected, but \'$1\' found",
    errOnOffOrListExpectedButXFound: "\'on\', \'off\' or \'list\' expected, but \'$1\' found",
    errNoneBoehmRefcExpectedButXFound: "'none', 'boehm' or 'refc' expected, but '$1' found",
    errNoneSpeedOrSizeExpectedButXFound: "'none', 'speed' or 'size' expected, but '$1' found",
    errGuiConsoleOrLibExpectedButXFound: "'gui', 'console' or 'lib' expected, but '$1' found",
    errUnknownOS: "unknown OS: '$1'",
    errUnknownCPU: "unknown CPU: '$1'",
    errGenOutExpectedButXFound: "'c', 'c++' or 'yaml' expected, but '$1' found",
    errArgsNeedRunOption: "arguments can only be given if the '--run' option is selected",
    errInvalidMultipleAsgn: "multiple assignment is not allowed",
    errColonOrEqualsExpected: "\':\' or \'=\' expected, but found \'$1\'",
    errExprExpected: "expression expected, but found \'$1\'",
    errUndeclaredField: "undeclared field: \'$1\'",
    errUndeclaredRoutine: "attempting to call undeclared routine: \'$1\'",
    errUseQualifier: "ambiguous identifier: \'$1\' -- use a qualifier",
    errTypeExpected: "type expected",
    errSystemNeeds: "system module needs \'$1\'",
    errExecutionOfProgramFailed: "execution of an external program failed: '$1'",
    errNotOverloadable: "overloaded \'$1\' leads to ambiguous calls",
    errInvalidArgForX: "invalid argument for \'$1\'",
    errStmtHasNoEffect: "statement has no effect",
    errXExpectsTypeOrValue: "\'$1\' expects a type or value",
    errXExpectsArrayType: "\'$1\' expects an array type",
    errIteratorCannotBeInstantiated: "'$1' cannot be instantiated because its body has not been compiled yet",
    errExprXAmbiguous: "expression '$1' ambiguous in this context",
    errConstantDivisionByZero: "division by zero",
    errOrdinalTypeExpected: "ordinal type expected",
    errOrdinalOrFloatTypeExpected: "ordinal or float type expected",
    errOverOrUnderflow: "over- or underflow",
    errCannotEvalXBecauseIncompletelyDefined: "cannot evaluate '$1' because type is not defined completely",
    errChrExpectsRange0_255: "\'chr\' expects an int in the range 0..255",
    errDynlibRequiresExportc: "\'dynlib\' requires \'exportc\'",
    errUndeclaredFieldX: "undeclared field: \'$1\'",
    errNilAccess: "attempt to access a nil address",
    errIndexOutOfBounds: "index out of bounds",
    errIndexTypesDoNotMatch: "index types do not match",
    errBracketsInvalidForType: "\'[]\' operator invalid for this type",
    errValueOutOfSetBounds: "value out of set bounds",
    errFieldInitTwice: "field initialized twice: \'$1\'",
    errFieldNotInit: "field \'$1\' not initialized",
    errExprXCannotBeCalled: "expression \'$1\' cannot be called",
    errExprHasNoType: "expression has no type",
    errExprXHasNoType: "expression \'$1\' has no type (or is ambiguous)",
    errCastNotInSafeMode: "\'cast\' not allowed in safe mode",
    errExprCannotBeCastToX: "expression cannot be cast to $1",
    errCommaOrParRiExpected: "',' or ')' expected",
    errCurlyLeOrParLeExpected: "\'{\' or \'(\' expected",
    errSectionExpected: "section (\'type\', \'proc\', etc.) expected",
    errRangeExpected: "range expected",
    errMagicOnlyInSystem: "\'magic\' only allowed in system module",
    errPowerOfTwoExpected: "power of two expected",
    errStringMayNotBeEmpty: "string literal may not be empty",
    errCallConvExpected: "calling convention expected",
    errProcOnlyOneCallConv: "a proc can only have one calling convention",
    errSymbolMustBeImported: "symbol must be imported if 'lib' pragma is used",
    errExprMustBeBool: "expression must be of type 'bool'",
    errConstExprExpected: "constant expression expected",
    errDuplicateCaseLabel: "duplicate case label",
    errRangeIsEmpty: "range is empty",
    errSelectorMustBeOfCertainTypes: "selector must be of an ordinal type, float or string",
    errSelectorMustBeOrdinal: "selector must be of an ordinal type",
    errOrdXMustNotBeNegative: "ord($1) must not be negative",
    errLenXinvalid: "len($1) must be less than 32768",
    errWrongNumberOfVariables: "wrong number of variables",
    errExprCannotBeRaised: "only a 'ref object' can be raised",
    errBreakOnlyInLoop: "'break' only allowed in loop construct",
    errTypeXhasUnknownSize: "type \'$1\' has unknown size",
    errConstNeedsConstExpr: "a constant can only be initialized with a constant expression",
    errConstNeedsValue: "a constant needs a value",
    errResultCannotBeOpenArray: "the result type cannot be on open array",
    errSizeTooBig: "computing the type\'s size produced an overflow",
    errSetTooBig: "set is too large",
    errBaseTypeMustBeOrdinal: "base type of a set must be an ordinal",
    errInheritanceOnlyWithNonFinalObjects: "inheritance only works with non-final objects",
    errInheritanceOnlyWithEnums: "inheritance only works with an enum",
    errIllegalRecursionInTypeX: "illegal recursion in type \'$1\'",
    errCannotInstantiateX: "cannot instantiate: \'$1\'",
    errExprHasNoAddress: "expression has no address",
    errXStackEscape: "address of '$1' may not escape its stack frame",
    errVarForOutParamNeededX: "for a \'var\' type a variable needs to be passed; but '$1' is immutable",
    errPureTypeMismatch: "type mismatch",
    errTypeMismatch: "type mismatch: got <",
    errButExpected: "but expected one of: ",
    errButExpectedX: "but expected \'$1\'",
    errAmbiguousCallXYZ: "ambiguous call; both $1 and $2 match for: $3",
    errWrongNumberOfArguments: "wrong number of arguments",
    errWrongNumberOfArgumentsInCall: "wrong number of arguments in call to '$1'",
    errMissingGenericParamsForTemplate: "'$1' has unspecified generic parameters",
    errXCannotBePassedToProcVar: "\'$1\' cannot be passed to a procvar",
    errXCannotBeInParamDecl: "$1 cannot be declared in parameter declaration",
    errPragmaOnlyInHeaderOfProcX: "pragmas are only allowed in the header of a proc; redefinition of $1",
    errImplOfXNotAllowed: "implementation of \'$1\' is not allowed",
    errImplOfXexpected: "implementation of \'$1\' expected",
    errNoSymbolToBorrowFromFound: "no symbol to borrow from found",
    errDiscardValueX: "value of type '$1' has to be discarded",
    errInvalidDiscard: "statement returns no value that can be discarded",
    errIllegalConvFromXtoY: "conversion from $1 to $2 is invalid",
    errCannotBindXTwice: "cannot bind parameter \'$1\' twice",
    errInvalidOrderInArrayConstructor: "invalid order in array constructor",
    errInvalidOrderInEnumX: "invalid order in enum \'$1\'",
    errEnumXHasHoles: "enum \'$1\' has holes",
    errExceptExpected: "\'except\' or \'finally\' expected",
    errInvalidTry: "after catch all \'except\' or \'finally\' no section may follow",
    errOptionExpected: "option expected, but found \'$1\'",
    errXisNoLabel: "\'$1\' is not a label",
    errNotAllCasesCovered: "not all cases are covered",
    errUnknownSubstitionVar: "unknown substitution variable: \'$1\'",
    errComplexStmtRequiresInd: "complex statement requires indentation",
    errXisNotCallable: "\'$1\' is not callable",
    errNoPragmasAllowedForX: "no pragmas allowed for $1",
    errNoGenericParamsAllowedForX: "no generic parameters allowed for $1",
    errInvalidParamKindX: "invalid param kind: \'$1\'",
    errDefaultArgumentInvalid: "default argument invalid",
    errNamedParamHasToBeIdent: "named parameter has to be an identifier",
    errNoReturnTypeForX: "no return type allowed for $1",
    errConvNeedsOneArg: "a type conversion needs exactly one argument",
    errInvalidPragmaX: "invalid pragma: $1",
    errXNotAllowedHere: "$1 not allowed here",
    errInvalidControlFlowX: "invalid control flow: $1",
    errXisNoType: "invalid type: \'$1\'",
    errCircumNeedsPointer: "'[]' needs a pointer or reference type",
    errInvalidExpression: "invalid expression",
    errInvalidExpressionX: "invalid expression: \'$1\'",
    errEnumHasNoValueX: "enum has no value \'$1\'",
    errNamedExprExpected: "named expression expected",
    errNamedExprNotAllowed: "named expression not allowed here",
    errXExpectsOneTypeParam: "\'$1\' expects one type parameter",
    errArrayExpectsTwoTypeParams: "array expects two type parameters",
    errInvalidVisibilityX: "invalid visibility: \'$1\'",
    errInitHereNotAllowed: "initialization not allowed here",
    errXCannotBeAssignedTo: "\'$1\' cannot be assigned to",
    errIteratorNotAllowed: "iterators can only be defined at the module\'s top level",
    errXNeedsReturnType: "$1 needs a return type",
    errNoReturnTypeDeclared: "no return type declared",
    errNoCommand: "no command given",
    errInvalidCommandX: "invalid command: \'$1\'",
    errXOnlyAtModuleScope: "\'$1\' is only allowed at top level",
    errXNeedsParamObjectType: "'$1' needs a parameter that has an object type",
    errTemplateInstantiationTooNested: "template/macro instantiation too nested",
    errInstantiationFrom: "template/generic instantiation from here",
    errInvalidIndexValueForTuple: "invalid index value for tuple subscript",
    errCommandExpectsFilename: "command expects a filename argument",
    errMainModuleMustBeSpecified: "please, specify a main module in the project configuration file",
    errXExpected: "\'$1\' expected",
    errTIsNotAConcreteType: "\'$1\' is not a concrete type.",
    errCastToANonConcreteType: "cannot cast to a non concrete type: \'$1\'",
    errInvalidSectionStart: "invalid section start",
    errGridTableNotImplemented: "grid table is not implemented",
    errGeneralParseError: "general parse error",
    errNewSectionExpected: "new section expected",
    errWhitespaceExpected: "whitespace expected, got \'$1\'",
    errXisNoValidIndexFile: "\'$1\' is no valid index file",
    errCannotRenderX: "cannot render reStructuredText element \'$1\'",
    errVarVarTypeNotAllowed: "type \'var var\' is not allowed",
    errInstantiateXExplicitly: "instantiate '$1' explicitly",
    errOnlyACallOpCanBeDelegator: "only a call operator can be a delegator",
    errUsingNoSymbol: "'$1' is not a variable, constant or a proc name",
    errMacroBodyDependsOnGenericTypes: "the macro body cannot be compiled, " &
                                       "because the parameter '$1' has a generic type",
    errDestructorNotGenericEnough: "Destructor signature is too specific. " &
                                   "A destructor must be associated will all instantiations of a generic type",
    errInlineIteratorsAsProcParams: "inline iterators can be used as parameters only for " &
                                    "templates, macros and other inline iterators",
    errXExpectsTwoArguments: "\'$1\' expects two arguments",
    errXExpectsObjectTypes: "\'$1\' expects object types",
    errXcanNeverBeOfThisSubtype: "\'$1\' can never be of this subtype",
    errTooManyIterations: "interpretation requires too many iterations; " &
      "if you are sure this is not a bug in your code edit " &
      "compiler/vmdef.MaxLoopIterations and rebuild the compiler",
    errCannotInterpretNodeX: "cannot evaluate \'$1\'",
    errFieldXNotFound: "field \'$1\' cannot be found",
    errInvalidConversionFromTypeX: "invalid conversion from type \'$1\'",
    errAssertionFailed: "assertion failed",
    errCannotGenerateCodeForX: "cannot generate code for \'$1\'",
    errXRequiresOneArgument: "$1 requires one parameter",
    errUnhandledExceptionX: "unhandled exception: $1",
    errCyclicTree: "macro returned a cyclic abstract syntax tree",
    errXisNoMacroOrTemplate: "\'$1\' is no macro or template",
    errXhasSideEffects: "\'$1\' can have side effects",
    errIteratorExpected: "iterator within for loop context expected",
    errLetNeedsInit: "'let' symbol requires an initialization",
    errThreadvarCannotInit: "a thread var cannot be initialized explicitly; this would only run for the main thread",
    errWrongSymbolX: "usage of \'$1\' is a user-defined error",
    errIllegalCaptureX: "illegal capture '$1'",
    errXCannotBeClosure: "'$1' cannot have 'closure' calling convention",
    errXMustBeCompileTime: "'$1' can only be used in compile-time context",
    errCannotInferTypeOfTheLiteral: "cannot infer the type of the $1",
    errCannotInferReturnType: "cannot infer the return type of the proc",
    errCannotInferStaticParam: "cannot infer the value of the static param `$1`",
    errGenericLambdaNotAllowed: "A nested proc can have generic parameters only when " &
                                "it is used as an operand to another routine and the types " &
                                "of the generic paramers can be inferred from the expected signature.",
    errProcHasNoConcreteType: "'$1' doesn't have a concrete type, due to unspecified generic parameters.",
    errCompilerDoesntSupportTarget: "The current compiler \'$1\' doesn't support the requested compilation target",
    errInOutFlagNotExtern: "The `$1` modifier can be used only with imported types",
    errUser: "$1",
    warnCannotOpenFile: "cannot open \'$1\'",
    warnOctalEscape: "octal escape sequences do not exist; leading zero is ignored",
    warnXIsNeverRead: "\'$1\' is never read",
    warnXmightNotBeenInit: "\'$1\' might not have been initialized",
    warnDeprecated: "$1 is deprecated",
    warnConfigDeprecated: "config file '$1' is deprecated",
    warnSmallLshouldNotBeUsed: "\'l\' should not be used as an identifier; may look like \'1\' (one)",
    warnUnknownMagic: "unknown magic \'$1\' might crash the compiler",
    warnRedefinitionOfLabel: "redefinition of label \'$1\'",
    warnUnknownSubstitutionX: "unknown substitution \'$1\'",
    warnLanguageXNotSupported: "language \'$1\' not supported",
    warnFieldXNotSupported: "field \'$1\' not supported",
    warnCommentXIgnored: "comment \'$1\' ignored",
    warnNilStatement: "'nil' statement is deprecated; use an empty 'discard' statement instead",
    warnTypelessParam: "'$1' has no type. Typeless parameters are deprecated; only allowed for 'template'",
    warnUseBase: "use {.base.} for base methods; baseless methods are deprecated",
    warnWriteToForeignHeap: "write to foreign heap",
    warnUnsafeCode: "unsafe code: '$1'",
    warnEachIdentIsTuple: "each identifier is a tuple",
    warnShadowIdent: "shadowed identifier: '$1'",
    warnProveInit: "Cannot prove that '$1' is initialized. This will become a compile time error in the future.",
    warnProveField: "cannot prove that field '$1' is accessible",
    warnProveIndex: "cannot prove index '$1' is valid",
    warnGcUnsafe: "not GC-safe: '$1'",
    warnGcUnsafe2: "$1",
    warnUninit: "'$1' might not have been initialized",
    warnGcMem: "'$1' uses GC'ed memory",
    warnDestructor: "usage of a type with a destructor in a non destructible context. This will become a compile time error in the future.",
    warnLockLevel: "$1",
    warnResultShadowed: "Special variable 'result' is shadowed.",
    warnUser: "$1",
    hintSuccess: "operation successful",
    hintSuccessX: "operation successful ($# lines compiled; $# sec total; $#; $#)",
    hintLineTooLong: "line too long",
    hintXDeclaredButNotUsed: "\'$1\' is declared but not used",
    hintConvToBaseNotNeeded: "conversion to base object is not needed",
    hintConvFromXtoItselfNotNeeded: "conversion from $1 to itself is pointless",
    hintExprAlwaysX: "expression evaluates always to \'$1\'",
    hintQuitCalled: "quit() called",
    hintProcessing: "$1",
    hintCodeBegin: "generated code listing:",
    hintCodeEnd: "end of listing",
    hintConf: "used config file \'$1\'",
    hintPath: "added path: '$1'",
    hintConditionAlwaysTrue: "condition is always true: '$1'",
    hintName: "name should be: '$1'",
    hintPattern: "$1",
    hintExecuting: "$1",
    hintLinking: "",
    hintDependency: "$1",
    hintSource: "$1",
    hintStackTrace: "$1",
    hintGCStats: "$1",
    hintUser: "$1",
    hintUserRaw: "$1"]

const
  WarningsToStr* = ["CannotOpenFile", "OctalEscape",
    "XIsNeverRead", "XmightNotBeenInit",
    "Deprecated", "ConfigDeprecated",
    "SmallLshouldNotBeUsed", "UnknownMagic",
    "RedefinitionOfLabel", "UnknownSubstitutionX",
    "LanguageXNotSupported", "FieldXNotSupported",
    "CommentXIgnored", "NilStmt",
    "TypelessParam", "UseBase", "WriteToForeignHeap",
    "UnsafeCode", "EachIdentIsTuple", "ShadowIdent",
    "ProveInit", "ProveField", "ProveIndex", "GcUnsafe", "GcUnsafe2", "Uninit",
    "GcMem", "Destructor", "LockLevel", "ResultShadowed", "User"]

  HintsToStr* = ["Success", "SuccessX", "LineTooLong",
    "XDeclaredButNotUsed", "ConvToBaseNotNeeded", "ConvFromXtoItselfNotNeeded",
    "ExprAlwaysX", "QuitCalled", "Processing", "CodeBegin", "CodeEnd", "Conf",
    "Path", "CondTrue", "Name", "Pattern", "Exec", "Link", "Dependency",
    "Source", "StackTrace", "GCStats",
    "User", "UserRaw"]

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

  TFileInfo* = object
    fullPath: string           # This is a canonical full filesystem path
    projPath*: string          # This is relative to the project's root
    shortName*: string         # short name of the module
    quotedName*: Rope          # cached quoted short name for codegen
                               # purposes
    quotedFullName*: Rope      # cached quoted full name for codegen
                               # purposes

    lines*: seq[Rope]          # the source code of the module
                               #   used for better error messages and
                               #   embedding the original source in the
                               #   generated code
    dirtyfile: string          # the file that is actually read into memory
                               # and parsed; usually 'nil' but is used
                               # for 'nimsuggest'
    hash*: string              # the checksum of the file

  TLineInfo* = object          # This is designed to be as small as possible,
                               # because it is used
                               # in syntax nodes. We save space here by using
                               # two int16 and an int32.
                               # On 64 bit and on 32 bit systems this is
                               # only 8 bytes.
    line*, col*: int16
    fileIndex*: int32
    when defined(nimpretty):
      offsetA*, offsetB*: int
      commentOffsetA*, commentOffsetB*: int

  TErrorOutput* = enum
    eStdOut
    eStdErr

  TErrorOutputs* = set[TErrorOutput]

  ERecoverableError* = object of ValueError
  ESuggestDone* = object of Exception

const
  NotesVerbosity*: array[0..3, TNoteKinds] = [
    {low(TNoteKind)..high(TNoteKind)} - {warnShadowIdent, warnUninit,
                                         warnProveField, warnProveIndex,
                                         warnGcUnsafe,
                                         hintSuccessX, hintPath, hintConf,
                                         hintProcessing, hintPattern,
                                         hintDependency,
                                         hintExecuting, hintLinking,
                                         hintCodeBegin, hintCodeEnd,
                                         hintSource, hintStackTrace,
                                         hintGCStats},
    {low(TNoteKind)..high(TNoteKind)} - {warnShadowIdent, warnUninit,
                                         warnProveField, warnProveIndex,
                                         warnGcUnsafe,
                                         hintPath,
                                         hintDependency,
                                         hintCodeBegin, hintCodeEnd,
                                         hintSource, hintStackTrace,
                                         hintGCStats},
    {low(TNoteKind)..high(TNoteKind)} - {hintStackTrace, warnUninit},
    {low(TNoteKind)..high(TNoteKind)}]

const
  InvalidFileIDX* = int32(-1)

var
  ForeignPackageNotes*: TNoteKinds = {hintProcessing, warnUnknownMagic,
    hintQuitCalled, hintExecuting}
  filenameToIndexTbl = initTable[string, int32]()
  fileInfos*: seq[TFileInfo] = @[]
  systemFileIdx*: int32

proc toCChar*(c: char): string =
  case c
  of '\0'..'\x1F', '\x7F'..'\xFF': result = '\\' & toOctal(c)
  of '\'', '\"', '\\', '?': result = '\\' & c
  else: result = $(c)

proc makeCString*(s: string): Rope =
  const
    MaxLineLength = 64
  result = nil
  var res = newStringOfCap(int(s.len.toFloat * 1.1) + 1)
  add(res, "\"")
  for i in countup(0, len(s) - 1):
    if (i + 1) mod MaxLineLength == 0:
      add(res, '\"')
      add(res, tnl)
      add(res, '\"')
    add(res, toCChar(s[i]))
  add(res, '\"')
  add(result, rope(res))


proc newFileInfo(fullPath, projPath: string): TFileInfo =
  result.fullPath = fullPath
  #shallow(result.fullPath)
  result.projPath = projPath
  #shallow(result.projPath)
  let fileName = projPath.extractFilename
  result.shortName = fileName.changeFileExt("")
  result.quotedName = fileName.makeCString
  result.quotedFullName = fullPath.makeCString
  if optEmbedOrigSrc in gGlobalOptions or true:
    result.lines = @[]

proc fileInfoKnown*(filename: string): bool =
  var
    canon: string
  try:
    canon = canonicalizePath(filename)
  except:
    canon = filename
  result = filenameToIndexTbl.hasKey(canon)

proc fileInfoIdx*(filename: string; isKnownFile: var bool): int32 =
  var
    canon: string
    pseudoPath = false

  try:
    canon = canonicalizePath(filename)
    shallow(canon)
  except:
    canon = filename
    # The compiler uses "filenames" such as `command line` or `stdin`
    # This flag indicates that we are working with such a path here
    pseudoPath = true

  if filenameToIndexTbl.hasKey(canon):
    result = filenameToIndexTbl[canon]
  else:
    isKnownFile = false
    result = fileInfos.len.int32
    fileInfos.add(newFileInfo(canon, if pseudoPath: filename
                                     else: canon.shortenDir))
    filenameToIndexTbl[canon] = result

proc fileInfoIdx*(filename: string): int32 =
  var dummy: bool
  result = fileInfoIdx(filename, dummy)

proc newLineInfo*(fileInfoIdx: int32, line, col: int): TLineInfo =
  result.fileIndex = fileInfoIdx
  result.line = int16(line)
  result.col = int16(col)

proc newLineInfo*(filename: string, line, col: int): TLineInfo {.inline.} =
  result = newLineInfo(filename.fileInfoIdx, line, col)

fileInfos.add(newFileInfo("", "command line"))
var gCmdLineInfo* = newLineInfo(int32(0), 1, 1)

fileInfos.add(newFileInfo("", "compilation artifact"))
var gCodegenLineInfo* = newLineInfo(int32(1), 1, 1)

proc raiseRecoverableError*(msg: string) {.noinline, noreturn.} =
  raise newException(ERecoverableError, msg)

proc sourceLine*(i: TLineInfo): Rope

var
  gNotes*: TNoteKinds = NotesVerbosity[1] # defaults to verbosity of 1
  gErrorCounter*: int = 0     # counts the number of errors
  gHintCounter*: int = 0
  gWarnCounter*: int = 0
  gErrorMax*: int = 1         # stop after gErrorMax errors
  gMainPackageNotes*: TNoteKinds = NotesVerbosity[1]

proc unknownLineInfo*(): TLineInfo =
  result.line = int16(-1)
  result.col = int16(-1)
  result.fileIndex = -1

type
  Severity* {.pure.} = enum ## VS Code only supports these three
    Hint, Warning, Error

var
  msgContext: seq[TLineInfo] = @[]
  lastError = unknownLineInfo()

  errorOutputs* = {eStdOut, eStdErr}
  writelnHook*: proc (output: string) {.closure.}
  structuredErrorHook*: proc (info: TLineInfo; msg: string; severity: Severity) {.closure.}

proc concat(strings: openarray[string]): string =
  var totalLen = 0
  for s in strings: totalLen += s.len
  result = newStringOfCap totalLen
  for s in strings: result.add s

proc suggestWriteln*(s: string) =
  if eStdOut in errorOutputs:
    if isNil(writelnHook):
      writeLine(stdout, s)
      flushFile(stdout)
    else:
      writelnHook(s)

proc msgQuit*(x: int8) = quit x
proc msgQuit*(x: string) = quit x

proc suggestQuit*() =
  raise newException(ESuggestDone, "suggest done")

# this format is understood by many text editors: it is the same that
# Borland and Freepascal use
const
  PosFormat    = "$1($2, $3) "
  KindFormat   = " [$1]"
  KindColor    = fgCyan
  ErrorTitle   = "Error: "
  ErrorColor   = fgRed
  WarningTitle = "Warning: "
  WarningColor = fgYellow
  HintTitle    = "Hint: "
  HintColor    = fgGreen

proc getInfoContextLen*(): int = return msgContext.len
proc setInfoContextLen*(L: int) = setLen(msgContext, L)

proc pushInfoContext*(info: TLineInfo) =
  msgContext.add(info)

proc popInfoContext*() =
  setLen(msgContext, len(msgContext) - 1)

proc getInfoContext*(index: int): TLineInfo =
  let L = msgContext.len
  let i = if index < 0: L + index else: index
  if i >=% L: result = unknownLineInfo()
  else: result = msgContext[i]

template toFilename*(fileIdx: int32): string =
  (if fileIdx < 0: "???" else: fileInfos[fileIdx].projPath)

proc toFullPath*(fileIdx: int32): string =
  if fileIdx < 0: result = "???"
  else: result = fileInfos[fileIdx].fullPath

proc setDirtyFile*(fileIdx: int32; filename: string) =
  assert fileIdx >= 0
  fileInfos[fileIdx].dirtyFile = filename

proc setHash*(fileIdx: int32; hash: string) =
  assert fileIdx >= 0
  shallowCopy(fileInfos[fileIdx].hash, hash)

proc getHash*(fileIdx: int32): string =
  assert fileIdx >= 0
  shallowCopy(result, fileInfos[fileIdx].hash)

proc toFullPathConsiderDirty*(fileIdx: int32): string =
  if fileIdx < 0:
    result = "???"
  elif not fileInfos[fileIdx].dirtyFile.isNil:
    result = fileInfos[fileIdx].dirtyFile
  else:
    result = fileInfos[fileIdx].fullPath

template toFilename*(info: TLineInfo): string =
  info.fileIndex.toFilename

template toFullPath*(info: TLineInfo): string =
  info.fileIndex.toFullPath

proc toMsgFilename*(info: TLineInfo): string =
  if info.fileIndex < 0:
    result = "???"
  elif gListFullPaths:
    result = fileInfos[info.fileIndex].fullPath
  else:
    result = fileInfos[info.fileIndex].projPath

proc toLinenumber*(info: TLineInfo): int {.inline.} =
  result = info.line

proc toColumn*(info: TLineInfo): int {.inline.} =
  result = info.col

proc toFileLine*(info: TLineInfo): string {.inline.} =
  result = info.toFilename & ":" & $info.line

proc toFileLineCol*(info: TLineInfo): string {.inline.} =
  result = info.toFilename & "(" & $info.line & ", " & $info.col & ")"

proc `$`*(info: TLineInfo): string = toFileLineCol(info)

proc `??`* (info: TLineInfo, filename: string): bool =
  # only for debugging purposes
  result = filename in info.toFilename

const trackPosInvalidFileIdx* = -2 # special marker so that no suggestions
                                   # are produced within comments and string literals
var gTrackPos*: TLineInfo
var gTrackPosAttached*: bool ## whether the tracking position was attached to some
                             ## close token.

type
  MsgFlag* = enum  ## flags altering msgWriteln behavior
    msgStdout,     ## force writing to stdout, even stderr is default
    msgSkipHook    ## skip message hook even if it is present
  MsgFlags* = set[MsgFlag]

proc msgWriteln*(s: string, flags: MsgFlags = {}) =
  ## Writes given message string to stderr by default.
  ## If ``--stdout`` option is given, writes to stdout instead. If message hook
  ## is present, then it is used to output message rather than stderr/stdout.
  ## This behavior can be altered by given optional flags.

  ## This is used for 'nim dump' etc. where we don't have nimsuggest
  ## support.
  #if gCmd == cmdIdeTools and optCDebug notin gGlobalOptions: return

  if not isNil(writelnHook) and msgSkipHook notin flags:
    writelnHook(s)
  elif optStdout in gGlobalOptions or msgStdout in flags:
    if eStdOut in errorOutputs:
      writeLine(stdout, s)
      flushFile(stdout)
  else:
    if eStdErr in errorOutputs:
      writeLine(stderr, s)
      # On Windows stderr is fully-buffered when piped, regardless of C std.
      when defined(windows):
        flushFile(stderr)

macro callIgnoringStyle(theProc: typed, first: typed,
                        args: varargs[typed]): untyped =
  let typForegroundColor = bindSym"ForegroundColor".getType
  let typBackgroundColor = bindSym"BackgroundColor".getType
  let typStyle = bindSym"Style".getType
  let typTerminalCmd = bindSym"TerminalCmd".getType
  result = newCall(theProc)
  if first.kind != nnkNilLit: result.add(first)
  for arg in children(args[0][1]):
    if arg.kind == nnkNilLit: continue
    let typ = arg.getType
    if typ.kind != nnkEnumTy or
       typ != typForegroundColor and
       typ != typBackgroundColor and
       typ != typStyle and
       typ != typTerminalCmd:
      result.add(arg)

macro callStyledWriteLineStderr(args: varargs[typed]): untyped =
  result = newCall(bindSym"styledWriteLine")
  result.add(bindSym"stderr")
  for arg in children(args[0][1]):
    result.add(arg)

template callWritelnHook(args: varargs[string, `$`]) =
  writelnHook concat(args)

template styledMsgWriteln*(args: varargs[typed]) =
  if not isNil(writelnHook):
    callIgnoringStyle(callWritelnHook, nil, args)
  elif optStdout in gGlobalOptions:
    if eStdOut in errorOutputs:
      callIgnoringStyle(writeLine, stdout, args)
      flushFile(stdout)
  else:
    if eStdErr in errorOutputs:
      if optUseColors in gGlobalOptions:
        callStyledWriteLineStderr(args)
      else:
        callIgnoringStyle(writeLine, stderr, args)
      # On Windows stderr is fully-buffered when piped, regardless of C std.
      when defined(windows):
        flushFile(stderr)

proc coordToStr(coord: int): string =
  if coord == -1: result = "???"
  else: result = $coord

proc msgKindToString*(kind: TMsgKind): string =
  # later versions may provide translated error messages
  result = MsgKindToStr[kind]

proc getMessageStr(msg: TMsgKind, arg: string): string =
  result = msgKindToString(msg) % [arg]

type
  TErrorHandling = enum doNothing, doAbort, doRaise

proc log*(s: string) {.procvar.} =
  var f: File
  if open(f, getHomeDir() / "nimsuggest.log", fmAppend):
    f.writeLine(s)
    close(f)

proc quit(msg: TMsgKind) =
  if defined(debug) or msg == errInternal or hintStackTrace in gNotes:
    if stackTraceAvailable() and isNil(writelnHook):
      writeStackTrace()
    else:
      styledMsgWriteln(fgRed, "No stack traceback available\n" &
          "To create a stacktrace, rerun compilation with ./koch temp " &
          options.command & " <file>")
  quit 1

proc handleError(msg: TMsgKind, eh: TErrorHandling, s: string) =
  if msg >= fatalMin and msg <= fatalMax:
    if gCmd == cmdIdeTools: log(s)
    quit(msg)
  if msg >= errMin and msg <= errMax:
    inc(gErrorCounter)
    options.gExitcode = 1'i8
    if gErrorCounter >= gErrorMax:
      quit(msg)
    elif eh == doAbort and gCmd != cmdIdeTools:
      quit(msg)
    elif eh == doRaise:
      raiseRecoverableError(s)

proc `==`*(a, b: TLineInfo): bool =
  result = a.line == b.line and a.fileIndex == b.fileIndex

proc exactEquals*(a, b: TLineInfo): bool =
  result = a.fileIndex == b.fileIndex and a.line == b.line and a.col == b.col

proc writeContext(lastinfo: TLineInfo) =
  var info = lastinfo
  for i in countup(0, len(msgContext) - 1):
    if msgContext[i] != lastinfo and msgContext[i] != info:
      if structuredErrorHook != nil:
        structuredErrorHook(msgContext[i], getMessageStr(errInstantiationFrom, ""),
                            Severity.Error)
      else:
        styledMsgWriteln(styleBright,
                         PosFormat % [toMsgFilename(msgContext[i]),
                                      coordToStr(msgContext[i].line),
                                      coordToStr(msgContext[i].col+1)],
                         resetStyle,
                         getMessageStr(errInstantiationFrom, ""))
    info = msgContext[i]

proc ignoreMsgBecauseOfIdeTools(msg: TMsgKind): bool =
  msg >= errGenerated and gCmd == cmdIdeTools and optIdeDebug notin gGlobalOptions

proc rawMessage*(msg: TMsgKind, args: openArray[string]) =
  var
    title: string
    color: ForegroundColor
    kind: string
    sev: Severity
  case msg
  of errMin..errMax:
    sev = Severity.Error
    writeContext(unknownLineInfo())
    title = ErrorTitle
    color = ErrorColor
  of warnMin..warnMax:
    sev = Severity.Warning
    if optWarns notin gOptions: return
    if msg notin gNotes: return
    writeContext(unknownLineInfo())
    title = WarningTitle
    color = WarningColor
    kind = WarningsToStr[ord(msg) - ord(warnMin)]
    inc(gWarnCounter)
  of hintMin..hintMax:
    sev = Severity.Hint
    if optHints notin gOptions: return
    if msg notin gNotes: return
    title = HintTitle
    color = HintColor
    if msg != hintUserRaw: kind = HintsToStr[ord(msg) - ord(hintMin)]
    inc(gHintCounter)
  let s = msgKindToString(msg) % args

  if structuredErrorHook != nil:
    structuredErrorHook(unknownLineInfo(), s & (if kind != nil: KindFormat % kind else: ""), sev)

  if not ignoreMsgBecauseOfIdeTools(msg):
    if kind != nil:
      styledMsgWriteln(color, title, resetStyle, s,
                       KindColor, `%`(KindFormat, kind))
    else:
      styledMsgWriteln(color, title, resetStyle, s)
  handleError(msg, doAbort, s)

proc rawMessage*(msg: TMsgKind, arg: string) =
  rawMessage(msg, [arg])

proc resetAttributes* =
  if {optUseColors, optStdout} * gGlobalOptions == {optUseColors}:
    terminal.resetAttributes(stderr)

proc writeSurroundingSrc(info: TLineInfo) =
  const indent = "  "
  msgWriteln(indent & $info.sourceLine)
  msgWriteln(indent & spaces(info.col) & '^')

proc formatMsg*(info: TLineInfo, msg: TMsgKind, arg: string): string =
  let title = case msg
              of warnMin..warnMax: WarningTitle
              of hintMin..hintMax: HintTitle
              else: ErrorTitle
  result = PosFormat % [toMsgFilename(info), coordToStr(info.line),
                        coordToStr(info.col+1)] &
           title &
           getMessageStr(msg, arg)

proc liMessage(info: TLineInfo, msg: TMsgKind, arg: string,
               eh: TErrorHandling) =
  var
    title: string
    color: ForegroundColor
    kind:  string
    ignoreMsg = false
    sev: Severity
  case msg
  of errMin..errMax:
    sev = Severity.Error
    writeContext(info)
    title = ErrorTitle
    color = ErrorColor
    # we try to filter error messages so that not two error message
    # in the same file and line are produced:
    #ignoreMsg = lastError == info and eh != doAbort
    lastError = info
  of warnMin..warnMax:
    sev = Severity.Warning
    ignoreMsg = optWarns notin gOptions or msg notin gNotes
    if not ignoreMsg: writeContext(info)
    title = WarningTitle
    color = WarningColor
    kind = WarningsToStr[ord(msg) - ord(warnMin)]
    inc(gWarnCounter)
  of hintMin..hintMax:
    sev = Severity.Hint
    ignoreMsg = optHints notin gOptions or msg notin gNotes
    title = HintTitle
    color = HintColor
    if msg != hintUserRaw: kind = HintsToStr[ord(msg) - ord(hintMin)]
    inc(gHintCounter)
  # NOTE: currently line info line numbers start with 1,
  # but column numbers start with 0, however most editors expect
  # first column to be 1, so we need to +1 here
  let x = PosFormat % [toMsgFilename(info), coordToStr(info.line),
                       coordToStr(info.col+1)]
  let s = getMessageStr(msg, arg)

  if not ignoreMsg:
    if structuredErrorHook != nil:
      structuredErrorHook(info, s & (if kind != nil: KindFormat % kind else: ""), sev)
    if not ignoreMsgBecauseOfIdeTools(msg):
      if kind != nil:
        styledMsgWriteln(styleBright, x, resetStyle, color, title, resetStyle, s,
                         KindColor, `%`(KindFormat, kind))
      else:
        styledMsgWriteln(styleBright, x, resetStyle, color, title, resetStyle, s)
      if msg in errMin..errMax and hintSource in gNotes:
        info.writeSurroundingSrc
  handleError(msg, eh, s)

proc fatal*(info: TLineInfo, msg: TMsgKind, arg = "") =
  # this fixes bug #7080 so that it is at least obvious 'fatal'
  # was executed.
  errorOutputs = {eStdOut, eStdErr}
  liMessage(info, msg, arg, doAbort)

proc globalError*(info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(info, msg, arg, doRaise)

proc globalError*(info: TLineInfo, arg: string) =
  liMessage(info, errGenerated, arg, doRaise)

proc localError*(info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(info, msg, arg, doNothing)

proc localError*(info: TLineInfo, arg: string) =
  liMessage(info, errGenerated, arg, doNothing)

proc localError*(info: TLineInfo, format: string, params: openarray[string]) =
  localError(info, format % params)

proc message*(info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(info, msg, arg, doNothing)

proc internalError*(info: TLineInfo, errMsg: string) =
  if gCmd == cmdIdeTools and structuredErrorHook.isNil: return
  writeContext(info)
  liMessage(info, errInternal, errMsg, doAbort)

proc internalError*(errMsg: string) =
  if gCmd == cmdIdeTools and structuredErrorHook.isNil: return
  writeContext(unknownLineInfo())
  rawMessage(errInternal, errMsg)

template assertNotNil*(e): untyped =
  if e == nil: internalError($instantiationInfo())
  e

template internalAssert*(e: bool) =
  if not e: internalError($instantiationInfo())

proc addSourceLine*(fileIdx: int32, line: string) =
  fileInfos[fileIdx].lines.add line.rope

proc sourceLine*(i: TLineInfo): Rope =
  if i.fileIndex < 0: return nil

  if not optPreserveOrigSource and fileInfos[i.fileIndex].lines.len == 0:
    try:
      for line in lines(i.toFullPath):
        addSourceLine i.fileIndex, line.string
    except IOError:
      discard
  internalAssert i.fileIndex < fileInfos.len
  # can happen if the error points to EOF:
  if i.line > fileInfos[i.fileIndex].lines.len: return nil

  result = fileInfos[i.fileIndex].lines[i.line-1]

proc quotedFilename*(i: TLineInfo): Rope =
  internalAssert i.fileIndex >= 0
  if optExcessiveStackTrace in gGlobalOptions:
    result = fileInfos[i.fileIndex].quotedFullName
  else:
    result = fileInfos[i.fileIndex].quotedName

ropes.errorHandler = proc (err: RopesError, msg: string, useWarning: bool) =
  case err
  of rInvalidFormatStr:
    internalError("ropes: invalid format string: " & msg)
  of rCannotOpenFile:
    rawMessage(if useWarning: warnCannotOpenFile else: errCannotOpenFile, msg)

proc listWarnings*() =
  msgWriteln("Warnings:")
  for warn in warnMin..warnMax:
    msgWriteln("  [$1] $2" % [
      if warn in gNotes: "x" else: " ",
      msgs.WarningsToStr[ord(warn) - ord(warnMin)]
    ])

proc listHints*() =
  msgWriteln("Hints:")
  for hint in hintMin..hintMax:
    msgWriteln("  [$1] $2" % [
      if hint in gNotes: "x" else: " ",
      msgs.HintsToStr[ord(hint) - ord(hintMin)]
    ])

# enable colors by default on terminals
if terminal.isatty(stderr):
  incl(gGlobalOptions, optUseColors)
