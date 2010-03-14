#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import #[[[cog
       #from string import replace
       #enum = "type\n  TMsgKind = (\n"
       #msgs = "const\n  MsgKindToStr: array [TMsgKind] of string = (\n"
       #warns = "const\n  WarningsToStr: array [0..%d] of string = (\n"
       #hints = "const\n  HintsToStr: array [0..%d] of string = (\n"
       #w = 0 # counts the warnings
       #h = 0 # counts the hints
       #
       #for elem in eval(open('data/messages.yml').read()):
       #  for key, val in elem.items():
       #    enum = enum + '    %s,\n' % key
       #    v = replace(val, "'", "''")
       #    if key[0:4] == 'warn':
       #      msgs = msgs +  "    '%s [%s]',\n" % (v, key[4:])
       #      warns = warns + "    '%s',\n" % key[4:]
       #      w = w + 1
       #    elif key[0:4] == 'hint':
       #      msgs = msgs + "    '%s [%s]',\n" % (v, key[4:])
       #      hints = hints + "    '%s',\n" % key[4:]
       #      h = h + 1
       #    else:
       #      msgs = msgs + "    '%s',\n" % v
       #
       #enum = enum[:-2] + ');\n\n'
       #msgs = msgs[:-2] + '\n  );\n'
       #warns = (warns[:-2] + '\n  );\n') % (w-1)
       #hints = (hints[:-2] + '\n  );\n') % (h-1)
       #
       #cog.out(enum)
       #cog.out(msgs)
       #cog.out(warns)
       #cog.out(hints)
       #]]]
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
    errInvalidOrderInEnumX, errEnumXHasWholes, errExceptExpected, errInvalidTry, 
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
    hintProcessing, hintCodeBegin, hintCodeEnd, hintConf, hintUser

const 
  MsgKindToStr*: array[TMsgKind, string] = ["unknown error", 
    "illformed AST: $1", "cannot open \'$1\'", "internal error: $1", "$1", 
    "\'$1\' compiler does not support C++", "string literal expected", 
    "integer literal expected", "invalid character constant", 
    "closing \"\"\" expected, but end of file reached", "closing \" expected", 
    "tabulators are not allowed", "invalid token: $1", "line too long", 
    "$1 is not a valid number", "number $1 out of valid range", 
    "\\n not allowed in character literal", 
    "closing \']\' expected, but end of file reached", "missing final \'", 
    "identifier expected, but found \'$1\'", 
    "operator expected, but found \'$1\'", "\'$1\' expected", 
    "string after \'include\' expected", "recursive dependency: \'$1\'", 
    "\'on\' or \'off\' expected", "\'none\', \'speed\' or \'size\' expected", 
    "invalid pragma", "unknown pragma: \'$1\'", "invalid directive: \'$1\'", 
    "\'pop\' without a \'push\' pragma", "empty asm statement", 
    "invalid indentation", "exception expected", "exception already handled", 
    "\'yield\' only allowed in a loop of an iterator", 
    "invalid number of \'yield\' expresions", 
    "current routine cannot return an expression", "attempt to redefine \'$1\'", 
    "statement not allowed after \'return\', \'break\' or \'raise\'", 
    "statement expected", "\'$1\' is no label", 
    "invalid command line option: \'$1\'", 
    "argument for command line option expected: \'$1\'", 
    "invalid argument for command line option: \'$1\'", 
    "invalid variable substitution in \'$1\'", "unknown variable: \'$1\'", 
    "unknown C compiler: \'$1\'", 
    "\'on\' or \'off\' expected, but \'$1\' found", 
    "\'none\', \'boehm\' or \'refc\' expected, but \'$1\' found", 
    "\'none\', \'speed\' or \'size\' expected, but \'$1\' found", 
    "\'gui\', \'console\' or \'lib\' expected, but \'$1\' found", 
    "unknown OS: \'$1\'", "unknown CPU: \'$1\'", 
    "\'c\', \'c++\' or \'yaml\' expected, but \'$1\' found", 
    "arguments can only be given if the \'--run\' option is selected", 
    "multiple assignment is not allowed", 
    "\':\' or \'=\' expected, but found \'$1\'", 
    "expression expected, but found \'$1\'", "undeclared identifier: \'$1\'", 
    "ambiguous identifier: \'$1\' -- use a qualifier", "type expected", 
    "system module needs \'$1\'", "execution of an external program failed", 
    "overloaded \'$1\' leads to ambiguous calls", "invalid argument for \'$1\'", 
    "statement has no effect", "\'$1\' expects a type or value", 
    "\'$1\' expects an array type", 
    "\'$1\' cannot be instantiated because its body has not been compiled yet", 
    "expression \'$1\' ambiguous in this context", "constant division by zero", 
    "ordinal type expected", "ordinal or float type expected", 
    "over- or underflow", 
    "cannot evalutate \'$1\' because type is not defined completely", 
    "\'chr\' expects an int in the range 0..255", 
    "\'dynlib\' requires \'exportc\'", "undeclared field: \'$1\'", 
    "attempt to access a nil address", "index out of bounds", 
    "index types do not match", "\'[]\' operator invalid for this type", 
    "value out of set bounds", "field initialized twice: \'$1\'", 
    "field \'$1\' not initialized", "expression \'$1\' cannot be called", 
    "expression has no type", "expression \'$1\' has no type (or is ambiguous)", 
    "\'cast\' not allowed in safe mode", "expression cannot be casted to $1", 
    "\',\' or \')\' expected", "\'{\' or \'(\' expected", 
    "section (\'type\', \'proc\', etc.) expected", "range expected", 
    "attempt to redefine \'$1\'", "\'magic\' only allowed in system module", 
    "power of two expected", "string literal may not be empty", 
    "calling convention expected", 
    "a proc can only have one calling convention", 
    "symbol must be imported if \'lib\' pragma is used", 
    "expression must be of type \'bool\'", "constant expression expected", 
    "duplicate case label", "range is empty", 
    "selector must be of an ordinal type, real or string", 
    "selector must be of an ordinal type", "ord($1) must not be negative", 
    "len($1) must be less than 32768", "wrong number of variables", 
    "only objects can be raised", "\'break\' only allowed in loop construct", 
    "type \'$1\' has unknown size", 
    "a constant can only be initialized with a constant expression", 
    "a constant needs a value", "the result type cannot be on open array", 
    "computing the type\'s size produced an overflow", "set is too large", 
    "base type of a set must be an ordinal", 
    "inheritance only works with non-final objects", 
    "inheritance only works with an enum", "illegal recursion in type \'$1\'", 
    "cannot instantiate: \'$1\'", "expression has no address", 
    "for a \'var\' type a variable needs to be passed", "type mismatch", 
    "type mismatch: got (", "but expected one of: ", "but expected \'$1\'", 
    "ambiguous call; both $1 and $2 match for: $3", "wrong number of arguments", 
    "\'$1\' cannot be passed to a procvar", 
    "$1 cannot be declared in parameter declaration", 
    "pragmas are only in the header of a proc allowed", 
    "implementation of \'$1\' is not allowed", 
    "implementation of \'$1\' expected", "no symbol to borrow from found", 
    "value returned by statement has to be discarded", 
    "statement returns no value that can be discarded", 
    "conversion from $1 to $2 is invalid", "cannot bind parameter \'$1\' twice", 
    "invalid order in enum \'$1\'", "enum \'$1\' has wholes", 
    "\'except\' or \'finally\' expected", 
    "after catch all \'except\' or \'finally\' no section may follow", 
    "option expected, but found \'$1\'", "\'$1\' is not a label", 
    "not all cases are covered", "unknown substitution variable: \'$1\'", 
    "complex statement requires indentation", "\'$1\' is not callable", 
    "no pragmas allowed for $1", "no generic parameters allowed for $1", 
    "invalid param kind: \'$1\'", "default argument invalid", 
    "named parameter has to be an identifier", "no return type for $1 allowed", 
    "a type conversion needs exactly one argument", "invalid pragma: $1", 
    "$1 not allowed here", "invalid control flow: $1", "a type has no value", 
    "invalid type: \'$1\'", "\'^\' needs a pointer or reference type", 
    "invalid expression", "invalid expression: \'$1\'", 
    "enum has no value \'$1\'", "named expression expected", 
    "named expression not allowed here", "\'$1\' expects one type parameter", 
    "array expects two type parameters", "invalid visibility: \'$1\'", 
    "initialization not allowed here", "\'$1\' cannot be assigned to", 
    "iterators can only be defined at the module\'s top level", 
    "$1 needs a return type", "invalid command: \'$1\'", 
    "\'$1\' is only allowed at top level", 
    "template/macro instantiation too nested", "instantiation from here", 
    "invalid index value for tuple subscript", 
    "command expects a filename argument", "\'$1\' expected", 
    "invalid section start", "grid table is not implemented", 
    "general parse error", "new section expected", 
    "whitespace expected, got \'$1\'", "\'$1\' is no valid index file", 
    "cannot render reStructuredText element \'$1\'", 
    "type \'var var\' is not allowed", "\'is\' expects two arguments", 
    "\'is\' expects object types", "\'$1\' can never be of this subtype", 
    "interpretation requires too many iterations", 
    "cannot interpret node kind \'$1\'", "field \'$1\' cannot be found", 
    "invalid conversion from type \'$1\'", "assertion failed", 
    "cannot generate code for \'$1\'", "$1 requires one parameter", 
    "unhandled exception: $1", "macro returned a cyclic abstract syntax tree", 
    "\'$1\' is no macro or template", "\'$1\' can have side effects", 
    "iterator within for loop context expected", "$1", 
    "cannot open \'$1\' [CannotOpenFile]", "octal escape sequences do not exist; leading zero is ignored [OctalEscape]", 
    "\'$1\' is never read [XIsNeverRead]", 
    "\'$1\' might not have been initialized [XmightNotBeenInit]", 
    "cannot write file \'$1\' [CannotWriteMO2]", 
    "cannot read file \'$1\' [CannotReadMO2]", 
    "\'$1\' is deprecated [Deprecated]", "\'l\' should not be used as an identifier; may look like \'1\' (one) [SmallLshouldNotBeUsed]", 
    "unknown magic \'$1\' might crash the compiler [UnknownMagic]", 
    "redefinition of label \'$1\' [RedefinitionOfLabel]", 
    "unknown substitution \'$1\' [UnknownSubstitutionX]", 
    "language \'$1\' not supported [LanguageXNotSupported]", 
    "comment \'$1\' ignored [CommentXIgnored]", 
    "\'$1\' is passed to a procvar; deprecated [XisPassedToProcVar]", 
    "$1 [User]", "operation successful [Success]", 
    "operation successful ($1 lines compiled; $2 sec total) [SuccessX]", 
    "line too long [LineTooLong]", 
    "\'$1\' is declared but not used [XDeclaredButNotUsed]", 
    "conversion to base object is not needed [ConvToBaseNotNeeded]", 
    "conversion from $1 to itself is pointless [ConvFromXtoItselfNotNeeded]", 
    "expression evaluates always to \'$1\' [ExprAlwaysX]", 
    "quit() called [QuitCalled]", "$1 [Processing]", 
    "generated code listing: [CodeBegin]", "end of listing [CodeEnd]", 
    "used config file \'$1\' [Conf]", "$1 [User]"]

const 
  WarningsToStr*: array[0..14, string] = ["CannotOpenFile", "OctalEscape", 
    "XIsNeverRead", "XmightNotBeenInit", "CannotWriteMO2", "CannotReadMO2", 
    "Deprecated", "SmallLshouldNotBeUsed", "UnknownMagic", 
    "RedefinitionOfLabel", "UnknownSubstitutionX", "LanguageXNotSupported", 
    "CommentXIgnored", "XisPassedToProcVar", "User"]

const 
  HintsToStr*: array[0..12, string] = ["Success", "SuccessX", "LineTooLong", 
    "XDeclaredButNotUsed", "ConvToBaseNotNeeded", "ConvFromXtoItselfNotNeeded", 
    "ExprAlwaysX", "QuitCalled", "Processing", "CodeBegin", "CodeEnd", "Conf", 
    "User"]                   #[[[end]]]

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
  TLineInfo*{.final.} = object # This is designed to be as small as possible, because it is used
                               # in syntax nodes. We safe space here by using two int16 and an int32
                               # on 64 bit and on 32 bit systems this is only 8 bytes.
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

var checkPoints: seq[TLineInfo] = @ []

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
