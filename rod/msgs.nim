#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  options, strutils, os

type 
  TMsgKind* = enum 
    errUnknown, errIllFormedAstX, errCannotOpenFile, errInternal, errGenerated, 
    errXCompilerDoesNotSupportCpp, errStringLiteralExpected, 
    errIntLiteralExpected, errInvalidCharacterConstant, 
    errClosingTripleQuoteExpected, errClosingQuoteExpected, 
    errTabulatorsAreNotAllowed, errInvalidToken, errLineTooLong, 
    errInvalidNumber, errNumberOutOfRange, errNnotAllowedInCharacter, 
    errClosingBracketExpected, errMissingFinalQuote, errIdentifierExpected, 
    errOperatorExpected, errTokenExpected, errStringAfterIncludeExpected, 
    errRecursiveDependencyX, errOnOrOffExpected, errNoneSpeedOrSizeExpected, 
    errInvalidPragma, errUnknownPragma, errInvalidDirectiveX, 
    errAtPopWithoutPush, errEmptyAsm, errInvalidIndentation, 
    errExceptionExpected, errExceptionAlreadyHandled, errYieldNotAllowedHere, 
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
    errAttemptToRedefineX, errMagicOnlyInSystem, errPowerOfTwoExpected, 
    errStringMayNotBeEmpty, errCallConvExpected, errProcOnlyOneCallConv, 
    errSymbolMustBeImported, errExprMustBeBool, errConstExprExpected, 
    errDuplicateCaseLabel, errRangeIsEmpty, errSelectorMustBeOfCertainTypes, 
    errSelectorMustBeOrdinal, errOrdXMustNotBeNegative, errLenXinvalid, 
    errWrongNumberOfVariables, errExprCannotBeRaised, errBreakOnlyInLoop, 
    errTypeXhasUnknownSize, errConstNeedsConstExpr, errConstNeedsValue, 
    errResultCannotBeOpenArray, errSizeTooBig, errSetTooBig, 
    errBaseTypeMustBeOrdinal, errInheritanceOnlyWithNonFinalObjects, 
    errInheritanceOnlyWithEnums, errIllegalRecursionInTypeX, 
    errCannotInstantiateX, errExprHasNoAddress, errVarForOutParamNeeded, 
    errPureTypeMismatch, errTypeMismatch, errButExpected, errButExpectedX, 
    errAmbiguousCallXYZ, errWrongNumberOfArguments, errXCannotBePassedToProcVar, 
    errXCannotBeInParamDecl, errPragmaOnlyInHeaderOfProc, errImplOfXNotAllowed, 
    errImplOfXexpected, errNoSymbolToBorrowFromFound, errDiscardValue, 
    errInvalidDiscard, errIllegalConvFromXtoY, errCannotBindXTwice, 
    errInvalidOrderInArrayConstructor,
    errInvalidOrderInEnumX, errEnumXHasHoles, errExceptExpected, errInvalidTry, 
    errOptionExpected, errXisNoLabel, errNotAllCasesCovered, 
    errUnkownSubstitionVar, errComplexStmtRequiresInd, errXisNotCallable, 
    errNoPragmasAllowedForX, errNoGenericParamsAllowedForX, 
    errInvalidParamKindX, errDefaultArgumentInvalid, errNamedParamHasToBeIdent, 
    errNoReturnTypeForX, errConvNeedsOneArg, errInvalidPragmaX, 
    errXNotAllowedHere, errInvalidControlFlowX, errATypeHasNoValue, 
    errXisNoType, errCircumNeedsPointer, errInvalidExpression, 
    errInvalidExpressionX, errEnumHasNoValueX, errNamedExprExpected, 
    errNamedExprNotAllowed, errXExpectsOneTypeParam, 
    errArrayExpectsTwoTypeParams, errInvalidVisibilityX, errInitHereNotAllowed, 
    errXCannotBeAssignedTo, errIteratorNotAllowed, errXNeedsReturnType, 
    errInvalidCommandX, errXOnlyAtModuleScope, 
    errXNeedsParamObjectType,
    errTemplateInstantiationTooNested, errInstantiationFrom, 
    errInvalidIndexValueForTuple, errCommandExpectsFilename, errXExpected, 
    errInvalidSectionStart, errGridTableNotImplemented, errGeneralParseError, 
    errNewSectionExpected, errWhitespaceExpected, errXisNoValidIndexFile, 
    errCannotRenderX, errVarVarTypeNotAllowed, errIsExpectsTwoArguments, 
    errIsExpectsObjectTypes, errXcanNeverBeOfThisSubtype, errTooManyIterations, 
    errCannotInterpretNodeX, errFieldXNotFound, errInvalidConversionFromTypeX, 
    errAssertionFailed, errCannotGenerateCodeForX, errXRequiresOneArgument, 
    errUnhandledExceptionX, errCyclicTree, errXisNoMacroOrTemplate, 
    errXhasSideEffects, errIteratorExpected, errUser, warnCannotOpenFile, 
    warnOctalEscape, warnXIsNeverRead, warnXmightNotBeenInit, 
    warnCannotWriteMO2, warnCannotReadMO2, warnDeprecated, 
    warnSmallLshouldNotBeUsed, warnUnknownMagic, warnRedefinitionOfLabel, 
    warnUnknownSubstitutionX, warnLanguageXNotSupported, warnCommentXIgnored, 
    warnXisPassedToProcVar, warnUser, hintSuccess, hintSuccessX, 
    hintLineTooLong, hintXDeclaredButNotUsed, hintConvToBaseNotNeeded, 
    hintConvFromXtoItselfNotNeeded, hintExprAlwaysX, hintQuitCalled, 
    hintProcessing, hintCodeBegin, hintCodeEnd, hintConf, hintPath, hintUser

const 
  MsgKindToStr*: array[TMsgKind, string] = [
    errUnknown: "unknown error", 
    errIllFormedAstX: "illformed AST: $1",
    errCannotOpenFile: "cannot open \'$1\'", 
    errInternal: "internal error: $1", 
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
    errNumberOutOfRange: "number $1 out of valid range", 
    errNnotAllowedInCharacter: "\\n not allowed in character literal", 
    errClosingBracketExpected: "closing ']' expected, but end of file reached", 
    errMissingFinalQuote: "missing final \'", 
    errIdentifierExpected: "identifier expected, but found \'$1\'", 
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
    errYieldNotAllowedHere: "\'yield\' only allowed in a loop of an iterator", 
    errInvalidNumberOfYieldExpr: "invalid number of \'yield\' expresions", 
    errCannotReturnExpr: "current routine cannot return an expression", 
    errAttemptToRedefine: "attempt to redefine \'$1\'", 
    errStmtInvalidAfterReturn: "statement not allowed after \'return\', \'break\' or \'raise\'", 
    errStmtExpected: "statement expected", 
    errInvalidLabel: "\'$1\' is no label", 
    errInvalidCmdLineOption: "invalid command line option: \'$1\'", 
    errCmdLineArgExpected: "argument for command line option expected: \'$1\'", 
    errCmdLineNoArgExpected: "invalid argument for command line option: \'$1\'", 
    errInvalidVarSubstitution: "invalid variable substitution in \'$1\'", 
    errUnknownVar: "unknown variable: \'$1\'", 
    errUnknownCcompiler: "unknown C compiler: \'$1\'", 
    errOnOrOffExpectedButXFound: "\'on\' or \'off\' expected, but \'$1\' found", 
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
    errUndeclaredIdentifier: "undeclared identifier: \'$1\'", 
    errUseQualifier: "ambiguous identifier: \'$1\' -- use a qualifier", 
    errTypeExpected: "type expected", 
    errSystemNeeds: "system module needs \'$1\'", 
    errExecutionOfProgramFailed: "execution of an external program failed", 
    errNotOverloadable: "overloaded \'$1\' leads to ambiguous calls", 
    errInvalidArgForX: "invalid argument for \'$1\'", 
    errStmtHasNoEffect: "statement has no effect", 
    errXExpectsTypeOrValue: "\'$1\' expects a type or value", 
    errXExpectsArrayType: "\'$1\' expects an array type", 
    errIteratorCannotBeInstantiated: "'$1' cannot be instantiated because its body has not been compiled yet", 
    errExprXAmbiguous: "expression '$1' ambiguous in this context", 
    errConstantDivisionByZero: "constant division by zero", 
    errOrdinalTypeExpected: "ordinal type expected", 
    errOrdinalOrFloatTypeExpected: "ordinal or float type expected", 
    errOverOrUnderflow: "over- or underflow", 
    errCannotEvalXBecauseIncompletelyDefined: "cannot evalutate '$1' because type is not defined completely", 
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
    errExprCannotBeCastedToX: "expression cannot be casted to $1", 
    errCommaOrParRiExpected: "',' or ')' expected", 
    errCurlyLeOrParLeExpected: "\'{\' or \'(\' expected", 
    errSectionExpected: "section (\'type\', \'proc\', etc.) expected", 
    errRangeExpected: "range expected", 
    errAttemptToRedefineX: "attempt to redefine \'$1\'", 
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
    errExprCannotBeRaised: "only objects can be raised", 
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
    errVarForOutParamNeeded: "for a \'var\' type a variable needs to be passed",
    errPureTypeMismatch: "type mismatch", 
    errTypeMismatch: "type mismatch: got (", 
    errButExpected: "but expected one of: ",
    errButExpectedX: "but expected \'$1\'", 
    errAmbiguousCallXYZ: "ambiguous call; both $1 and $2 match for: $3", 
    errWrongNumberOfArguments: "wrong number of arguments", 
    errXCannotBePassedToProcVar: "\'$1\' cannot be passed to a procvar", 
    errXCannotBeInParamDecl: "$1 cannot be declared in parameter declaration", 
    errPragmaOnlyInHeaderOfProc: "pragmas are only in the header of a proc allowed", 
    errImplOfXNotAllowed: "implementation of \'$1\' is not allowed", 
    errImplOfXexpected: "implementation of \'$1\' expected", 
    errNoSymbolToBorrowFromFound: "no symbol to borrow from found", 
    errDiscardValue: "value returned by statement has to be discarded", 
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
    errUnkownSubstitionVar: "unknown substitution variable: \'$1\'", 
    errComplexStmtRequiresInd: "complex statement requires indentation",
    errXisNotCallable: "\'$1\' is not callable", 
    errNoPragmasAllowedForX: "no pragmas allowed for $1", 
    errNoGenericParamsAllowedForX: "no generic parameters allowed for $1", 
    errInvalidParamKindX: "invalid param kind: \'$1\'", 
    errDefaultArgumentInvalid: "default argument invalid", 
    errNamedParamHasToBeIdent: "named parameter has to be an identifier", 
    errNoReturnTypeForX: "no return type for $1 allowed", 
    errConvNeedsOneArg: "a type conversion needs exactly one argument", 
    errInvalidPragmaX: "invalid pragma: $1", 
    errXNotAllowedHere: "$1 not allowed here",
    errInvalidControlFlowX: "invalid control flow: $1",
    errATypeHasNoValue: "a type has no value", 
    errXisNoType: "invalid type: \'$1\'",
    errCircumNeedsPointer: "\'^\' needs a pointer or reference type", 
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
    errInvalidCommandX: "invalid command: \'$1\'", 
    errXOnlyAtModuleScope: "\'$1\' is only allowed at top level", 
    errXNeedsParamObjectType: "'$1' needs a parameter that has an object type",
    errTemplateInstantiationTooNested: "template/macro instantiation too nested",
    errInstantiationFrom: "instantiation from here", 
    errInvalidIndexValueForTuple: "invalid index value for tuple subscript", 
    errCommandExpectsFilename: "command expects a filename argument",
    errXExpected: "\'$1\' expected", 
    errInvalidSectionStart: "invalid section start",
    errGridTableNotImplemented: "grid table is not implemented", 
    errGeneralParseError: "general parse error",
    errNewSectionExpected: "new section expected", 
    errWhitespaceExpected: "whitespace expected, got \'$1\'",
    errXisNoValidIndexFile: "\'$1\' is no valid index file", 
    errCannotRenderX: "cannot render reStructuredText element \'$1\'", 
    errVarVarTypeNotAllowed: "type \'var var\' is not allowed",
    errIsExpectsTwoArguments: "\'is\' expects two arguments", 
    errIsExpectsObjectTypes: "\'is\' expects object types",
    errXcanNeverBeOfThisSubtype: "\'$1\' can never be of this subtype", 
    errTooManyIterations: "interpretation requires too many iterations", 
    errCannotInterpretNodeX: "cannot interpret node kind \'$1\'", 
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
    errUser: "$1", 
    warnCannotOpenFile: "cannot open \'$1\' [CannotOpenFile]",
    warnOctalEscape: "octal escape sequences do not exist; leading zero is ignored [OctalEscape]", 
    warnXIsNeverRead: "\'$1\' is never read [XIsNeverRead]", 
    warnXmightNotBeenInit: "\'$1\' might not have been initialized [XmightNotBeenInit]", 
    warnCannotWriteMO2: "cannot write file \'$1\' [CannotWriteMO2]", 
    warnCannotReadMO2: "cannot read file \'$1\' [CannotReadMO2]", 
    warnDeprecated: "\'$1\' is deprecated [Deprecated]", 
    warnSmallLshouldNotBeUsed: "\'l\' should not be used as an identifier; may look like \'1\' (one) [SmallLshouldNotBeUsed]", 
    warnUnknownMagic: "unknown magic \'$1\' might crash the compiler [UnknownMagic]", 
    warnRedefinitionOfLabel: "redefinition of label \'$1\' [RedefinitionOfLabel]", 
    warnUnknownSubstitutionX: "unknown substitution \'$1\' [UnknownSubstitutionX]", 
    warnLanguageXNotSupported: "language \'$1\' not supported [LanguageXNotSupported]", 
    warnCommentXIgnored: "comment \'$1\' ignored [CommentXIgnored]", 
    warnXisPassedToProcVar: "\'$1\' is passed to a procvar; deprecated [XisPassedToProcVar]", 
    warnUser: "$1 [User]", 
    hintSuccess: "operation successful [Success]", 
    hintSuccessX: "operation successful ($1 lines compiled; $2 sec total) [SuccessX]", 
    hintLineTooLong: "line too long [LineTooLong]", 
    hintXDeclaredButNotUsed: "\'$1\' is declared but not used [XDeclaredButNotUsed]", 
    hintConvToBaseNotNeeded: "conversion to base object is not needed [ConvToBaseNotNeeded]", 
    hintConvFromXtoItselfNotNeeded: "conversion from $1 to itself is pointless [ConvFromXtoItselfNotNeeded]", 
    hintExprAlwaysX: "expression evaluates always to \'$1\' [ExprAlwaysX]", 
    hintQuitCalled: "quit() called [QuitCalled]",
    hintProcessing: "$1 [Processing]", 
    hintCodeBegin: "generated code listing: [CodeBegin]",
    hintCodeEnd: "end of listing [CodeEnd]", 
    hintConf: "used config file \'$1\' [Conf]", 
    hintPath: "added path: '$1' [Path]",
    hintUser: "$1 [User]"]

const 
  WarningsToStr*: array[0..14, string] = ["CannotOpenFile", "OctalEscape", 
    "XIsNeverRead", "XmightNotBeenInit", "CannotWriteMO2", "CannotReadMO2", 
    "Deprecated", "SmallLshouldNotBeUsed", "UnknownMagic", 
    "RedefinitionOfLabel", "UnknownSubstitutionX", "LanguageXNotSupported", 
    "CommentXIgnored", "XisPassedToProcVar", "User"]

const 
  HintsToStr*: array[0..13, string] = ["Success", "SuccessX", "LineTooLong", 
    "XDeclaredButNotUsed", "ConvToBaseNotNeeded", "ConvFromXtoItselfNotNeeded", 
    "ExprAlwaysX", "QuitCalled", "Processing", "CodeBegin", "CodeEnd", "Conf", 
    "Path",
    "User"]

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
  TLineInfo*{.final.} = object # This is designed to be as small as possible,
                               # because it is used
                               # in syntax nodes. We safe space here by using 
                               # two int16 and an int32
                               # on 64 bit and on 32 bit systems this is 
                               # only 8 bytes.
    line*, col*: int16
    fileIndex*: int32


proc UnknownLineInfo*(): TLineInfo

var 
  gNotes*: TNoteKinds = {low(TNoteKind)..high(TNoteKind)}
  gErrorCounter*: int = 0     # counts the number of errors
  gHintCounter*: int = 0
  gWarnCounter*: int = 0
  gErrorMax*: int = 1         # stop after gErrorMax errors

const # this format is understood by many text editors: it is the same that
      # Borland and Freepascal use
  PosErrorFormat* = "$1($2, $3) Error: $4"
  PosWarningFormat* = "$1($2, $3) Warning: $4"
  PosHintFormat* = "$1($2, $3) Hint: $4"
  RawErrorFormat* = "Error: $1"
  RawWarningFormat* = "Warning: $1"
  RawHintFormat* = "Hint: $1"

proc MessageOut*(s: string)
proc rawMessage*(msg: TMsgKind, arg: string)
proc rawMessage*(msg: TMsgKind, args: openarray[string])
proc liMessage*(info: TLineInfo, msg: TMsgKind, arg: string = "")
proc InternalError*(info: TLineInfo, errMsg: string)
proc InternalError*(errMsg: string)
proc newLineInfo*(filename: string, line, col: int): TLineInfo
proc ToFilename*(info: TLineInfo): string
proc toColumn*(info: TLineInfo): int
proc ToLinenumber*(info: TLineInfo): int
proc MsgKindToString*(kind: TMsgKind): string
  # checkpoints are used for debugging:
proc checkpoint*(info: TLineInfo, filename: string, line: int): bool
proc addCheckpoint*(info: TLineInfo)
proc addCheckpoint*(filename: string, line: int)
proc inCheckpoint*(current: TLineInfo): bool
  # prints the line information if in checkpoint
proc pushInfoContext*(info: TLineInfo)
proc popInfoContext*()
proc includeFilename*(f: string): int
# implementation

proc UnknownLineInfo(): TLineInfo = 
  result.line = int16(- 1)
  result.col = int16(- 1)
  result.fileIndex = - 1

var 
  filenames: seq[string] = @ []
  msgContext: seq[TLineInfo] = @ []

proc pushInfoContext(info: TLineInfo) = 
  var length: int
  length = len(msgContext)
  setlen(msgContext, length + 1)
  msgContext[length] = info

proc popInfoContext() = 
  setlen(msgContext, len(msgContext) - 1)

proc includeFilename(f: string): int = 
  for i in countdown(high(filenames), low(filenames)): 
    if filenames[i] == f: 
      return i
  result = len(filenames)
  setlen(filenames, result + 1)
  filenames[result] = f

proc checkpoint(info: TLineInfo, filename: string, line: int): bool = 
  result = (int(info.line) == line) and
      (ChangeFileExt(extractFilename(filenames[info.fileIndex]), "") ==
      filename)

var checkPoints: seq[TLineInfo] = @[]

proc addCheckpoint(info: TLineInfo) = 
  var length: int
  length = len(checkPoints)
  setlen(checkPoints, length + 1)
  checkPoints[length] = info

proc addCheckpoint(filename: string, line: int) = 
  addCheckpoint(newLineInfo(filename, line, - 1))

proc newLineInfo(filename: string, line, col: int): TLineInfo = 
  result.fileIndex = includeFilename(filename)
  result.line = int16(line)
  result.col = int16(col)

proc ToFilename(info: TLineInfo): string = 
  if info.fileIndex == - 1: result = "???"
  else: result = filenames[info.fileIndex]
  
proc ToLinenumber(info: TLineInfo): int = 
  result = info.line

proc toColumn(info: TLineInfo): int = 
  result = info.col

proc MessageOut(s: string) = 
  # change only this proc to put it elsewhere
  Writeln(stdout, s)
 
proc coordToStr(coord: int): string = 
  if coord == - 1: result = "???"
  else: result = $(coord)
  
proc MsgKindToString(kind: TMsgKind): string = 
  # later versions may provide translated error messages
  result = msgKindToStr[kind]

proc getMessageStr(msg: TMsgKind, arg: string): string = 
  result = `%`(msgKindToString(msg), [arg])

proc inCheckpoint(current: TLineInfo): bool = 
  result = false
  if not (optCheckpoints in gOptions): 
    return                    # ignore all checkpoints
  for i in countup(0, high(checkPoints)): 
    if (current.line == checkPoints[i].line) and
        (current.fileIndex == (checkPoints[i].fileIndex)): 
      MessageOut(`%`("$1($2, $3) Checkpoint: ", [toFilename(current), 
          coordToStr(current.line), coordToStr(current.col)]))
      return true

proc handleError(msg: TMsgKind) = 
  if msg == errInternal: 
    assert(false)             # we want a stack trace here
  if (msg >= fatalMin) and (msg <= fatalMax): 
    if gVerbosity >= 3: assert(false)
    quit(1)
  if (msg >= errMin) and (msg <= errMax): 
    inc(gErrorCounter)
    if gErrorCounter >= gErrorMax: 
      if gVerbosity >= 3: assert(false)
      quit(1)                 # one error stops the compiler
  
proc sameLineInfo(a, b: TLineInfo): bool = 
  result = (a.line == b.line) and (a.fileIndex == b.fileIndex)

proc writeContext(lastinfo: TLineInfo) = 
  var info: TLineInfo
  info = lastInfo
  for i in countup(0, len(msgContext) - 1): 
    if not sameLineInfo(msgContext[i], lastInfo) and
        not sameLineInfo(msgContext[i], info): 
      MessageOut(`%`(posErrorFormat, [toFilename(msgContext[i]), 
                                      coordToStr(msgContext[i].line), 
                                      coordToStr(msgContext[i].col), 
                                      getMessageStr(errInstantiationFrom, "")]))
    info = msgContext[i]

proc rawMessage(msg: TMsgKind, args: openarray[string]) = 
  var frmt: string
  case msg
  of errMin..errMax: 
    writeContext(unknownLineInfo())
    frmt = rawErrorFormat
  of warnMin..warnMax: 
    if not (optWarns in gOptions): return 
    if not (msg in gNotes): return 
    frmt = rawWarningFormat
    inc(gWarnCounter)
  of hintMin..hintMax: 
    if not (optHints in gOptions): return 
    if not (msg in gNotes): return 
    frmt = rawHintFormat
    inc(gHintCounter)
  else: 
    assert(false)             # cannot happen
  MessageOut(`%`(frmt, `%`(msgKindToString(msg), args)))
  handleError(msg)

proc rawMessage(msg: TMsgKind, arg: string) = 
  rawMessage(msg, [arg])

proc liMessage(info: TLineInfo, msg: TMsgKind, arg: string = "") = 
  var frmt: string
  case msg
  of errMin..errMax: 
    writeContext(info)
    frmt = posErrorFormat
  of warnMin..warnMax: 
    if not (optWarns in gOptions): return 
    if not (msg in gNotes): return 
    frmt = posWarningFormat
    inc(gWarnCounter)
  of hintMin..hintMax: 
    if not (optHints in gOptions): return 
    if not (msg in gNotes): return 
    frmt = posHintFormat
    inc(gHintCounter)
  else: 
    assert(false)             # cannot happen
  MessageOut(`%`(frmt, [toFilename(info), coordToStr(info.line), 
                        coordToStr(info.col), getMessageStr(msg, arg)]))
  handleError(msg)

proc InternalError(info: TLineInfo, errMsg: string) = 
  writeContext(info)
  liMessage(info, errInternal, errMsg)

proc InternalError(errMsg: string) = 
  writeContext(UnknownLineInfo())
  rawMessage(errInternal, errMsg)
