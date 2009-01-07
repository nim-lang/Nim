//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit msgs;

interface

{$include 'config.inc'}

uses
  nsystem, options, strutils, nos;

//[[[cog
//from string import replace
//enum = "type\n  TMsgKind = (\n"
//msgs = "const\n  MsgKindToStr: array [TMsgKind] of string = (\n"
//warns = "const\n  WarningsToStr: array [0..%d] of string = (\n"
//hints = "const\n  HintsToStr: array [0..%d] of string = (\n"
//w = 0 # counts the warnings
//h = 0 # counts the hints
//
//for elem in eval(open('data/messages.yml').read()):
//  for key, val in elem.items():
//    enum = enum + '    %s,\n' % key
//    v = replace(val, "'", "''")
//    if key[0:4] == 'warn':
//      msgs = msgs +  "    '%s [%s]',\n" % (v, key[4:])
//      warns = warns + "    '%s',\n" % key[4:]
//      w = w + 1
//    elif key[0:4] == 'hint':
//      msgs = msgs + "    '%s [%s]',\n" % (v, key[4:])
//      hints = hints + "    '%s',\n" % key[4:]
//      h = h + 1
//    else:
//      msgs = msgs + "    '%s',\n" % v
//
//enum = enum[:-2] + ');\n\n'
//msgs = msgs[:-2] + '\n  );\n'
//warns = (warns[:-2] + '\n  );\n') % (w-1)
//hints = (hints[:-2] + '\n  );\n') % (h-1)
//
//cog.out(enum)
//cog.out(msgs)
//cog.out(warns)
//cog.out(hints)
//]]]
type
  TMsgKind = (
    errUnknown,
    errIllFormedAstX,
    errCannotOpenFile,
    errInternal,
    errGenerated,
    errXCompilerDoesNotSupportCpp,
    errStringLiteralExpected,
    errIntLiteralExpected,
    errInvalidCharacterConstant,
    errClosingTripleQuoteExpected,
    errClosingQuoteExpected,
    errTabulatorsAreNotAllowed,
    errInvalidToken,
    errLineTooLong,
    errInvalidNumber,
    errNumberOutOfRange,
    errNnotAllowedInCharacter,
    errClosingBracketExpected,
    errMissingFinalQuote,
    errIdentifierExpected,
    errOperatorExpected,
    errTokenExpected,
    errStringAfterIncludeExpected,
    errRecursiveInclude,
    errOnOrOffExpected,
    errNoneSpeedOrSizeExpected,
    errInvalidPragma,
    errUnknownPragma,
    errPragmaXHereNotAllowed,
    errUnknownDirective,
    errInvalidDirective,
    errAtPopWithoutPush,
    errEmptyAsm,
    errAsgnInvalidInExpr,
    errInvalidIndentation,
    errExceptionExpected,
    errExceptionAlreadyHandled,
    errReturnNotAllowedHere,
    errYieldNotAllowedHere,
    errInvalidNumberOfYieldExpr,
    errReturnInvalidInIterator,
    errCannotReturnExpr,
    errAttemptToRedefine,
    errStmtInvalidAfterReturn,
    errStmtExpected,
    errYieldOnlyInInterators,
    errInvalidLabel,
    errInvalidCmdLineOption,
    errCmdLineArgExpected,
    errInvalidVarSubstitution,
    errUnknownVar,
    errUnknownCcompiler,
    errOnOrOffExpectedButXFound,
    errNoneBoehmRefcExpectedButXFound,
    errNoneSpeedOrSizeExpectedButXFound,
    errGuiConsoleOrLibExpectedButXFound,
    errUnknownOS,
    errUnknownCPU,
    errGenOutExpectedButXFound,
    errArgsNeedRunOption,
    errInvalidMultipleAsgn,
    errColonOrEqualsExpected,
    errExprExpected,
    errUndeclaredIdentifier,
    errUseQualifier,
    errTwiceForwarded,
    errTypeExpected,
    errSystemNeeds,
    errExecutionOfProgramFailed,
    errNotOverloadable,
    errInvalidArgForX,
    errStmtHasNoEffect,
    errXExpectsTypeOrValue,
    errXExpectsArrayType,
    errIteratorCannotBeInstantiated,
    errExprWithNoTypeCannotBeConverted,
    errExprWithNoTypeCannotBeCasted,
    errConstantDivisionByZero,
    errOrdinalTypeExpected,
    errOrdinalOrFloatTypeExpected,
    errOverOrUnderflow,
    errCannotEvalXBecauseIncompletelyDefined,
    errChrExpectsRange0_255,
    errStaticAssertFailed,
    errStaticAssertCannotBeEval,
    errDotRequiresRecordOrObjectType,
    errUndeclaredFieldX,
    errIndexNoIntType,
    errIndexOutOfBounds,
    errIndexTypesDoNotMatch,
    errBracketsInvalidForType,
    errValueOutOfSetBounds,
    errFieldInitTwice,
    errFieldNotInit,
    errExprCannotBeCalled,
    errExprHasNoType,
    errExprXHasNoType,
    errCastNotInSafeMode,
    errExprCannotBeCastedToX,
    errUndefinedPrefixOpr,
    errCommaOrParRiExpected,
    errCurlyLeOrParLeExpected,
    errSectionExpected,
    errImplemenationExpected,
    errRangeExpected,
    errInvalidTypeDescription,
    errAttemptToRedefineX,
    errMagicOnlyInSystem,
    errUnknownOperatorX,
    errPowerOfTwoExpected,
    errStringMayNotBeEmpty,
    errCallConvExpected,
    errProcOnlyOneCallConv,
    errSymbolMustBeImported,
    errExprMustBeBool,
    errConstExprExpected,
    errDuplicateCaseLabel,
    errRangeIsEmpty,
    errSelectorMustBeOfCertainTypes,
    errSelectorMustBeOrdinal,
    errOrdXMustNotBeNegative,
    errLenXinvalid,
    errWrongNumberOfVariables,
    errExprCannotBeRaised,
    errBreakOnlyInLoop,
    errTypeXhasUnknownSize,
    errConstNeedsConstExpr,
    errConstNeedsValue,
    errResultCannotBeOpenArray,
    errSizeTooBig,
    errSetTooBig,
    errBaseTypeMustBeOrdinal,
    errInheritanceOnlyWithNonFinalObjects,
    errInheritanceOnlyWithEnums,
    errIllegalRecursionInTypeX,
    errCannotInstantiateX,
    errExprHasNoAddress,
    errVarForOutParamNeeded,
    errPureTypeMismatch,
    errTypeMismatch,
    errButExpected,
    errButExpectedX,
    errAmbigiousCallXYZ,
    errWrongNumberOfTypeParams,
    errOutParamNoDefaultValue,
    errInlineProcHasNoAddress,
    errXCannotBeInParamDecl,
    errPragmaOnlyInHeaderOfProc,
    errImportedProcCannotHaveImpl,
    errImplOfXNotAllowed,
    errImplOfXexpected,
    errDiscardValue,
    errInvalidDiscard,
    errUnknownPrecedence,
    errIllegalConvFromXtoY,
    errTypeMismatchExpectedXGotY,
    errCannotBindXTwice,
    errInvalidOrderInEnumX,
    errEnumXHasWholes,
    errExceptExpected,
    errInvalidTry,
    errEofExpectedButXFound,
    errOptionExpected,
    errCannotEvaluateForwardConst,
    errXisNoLabel,
    errXNeedsConcreteType,
    errNotAllCasesCovered,
    errStringRange,
    errUnkownSubstitionVar,
    errComplexStmtRequiresInd,
    errXisNotCallable,
    errNoPragmasAllowedForX,
    errNoGenericParamsAllowedForX,
    errInvalidParamKindX,
    errDefaultArgumentInvalid,
    errNamedParamHasToBeIdent,
    errNoReturnTypeForX,
    errConvNeedsOneArg,
    errInvalidPragmaX,
    errXNotAllowedHere,
    errInvalidControlFlowX,
    errATypeHasNoValue,
    errXisNoType,
    errCircumNeedsPointer,
    errInvalidContextForBuiltinX,
    errInvalidExpression,
    errInvalidExpressionX,
    errEnumHasNoValueX,
    errNamedExprExpected,
    errNamedExprNotAllowed,
    errXExpectsOneTypeParam,
    errArrayExpectsTwoTypeParams,
    errInvalidVisibilityX,
    errInitHereNotAllowed,
    errXCannotBeAssignedTo,
    errIteratorNotAllowed,
    errIteratorNeedsImplementation,
    errIteratorNeedsReturnType,
    errInvalidCommandX,
    errXOnlyAtModuleScope,
    errTypeXNeedsImplementation,
    errTemplateInstantiationTooNested,
    errInstantiationFrom,
    errInvalidIndexValueForTuple,
    errCommandExpectsFilename,
    errXExpected,
    errInvalidSectionStart,
    errGridTableNotImplemented,
    errGeneralParseError,
    errNewSectionExpected,
    errWhitespaceExpected,
    errXisNoValidIndexFile,
    errCannotRenderX,
    errVarVarTypeNotAllowed,
    errIsExpectsTwoArguments,
    errIsExpectsObjectTypes,
    errXcanNeverBeOfThisSubtype,
    errTooManyIterations,
    errCannotInterpretNodeX,
    errFieldXNotFound,
    errInvalidConversionFromTypeX,
    errAssertionFailed,
    errCannotGenerateCodeForX,
    errXNeedsReturnType,
    errXRequiresOneArgument,
    errUnhandledExceptionX,
    errCyclicTree,
    errUser,
    warnCannotOpenFile,
    warnOctalEscape,
    warnXIsNeverRead,
    warnXmightNotBeenInit,
    warnCannotWriteMO2,
    warnCannotReadMO2,
    warnDeprecated,
    warnSmallLshouldNotBeUsed,
    warnUnknownMagic,
    warnRedefinitionOfLabel,
    warnUnknownSubstitutionX,
    warnLanguageXNotSupported,
    warnCommentXIgnored,
    warnUser,
    hintSuccess,
    hintSuccessX,
    hintLineTooLong,
    hintXDeclaredButNotUsed,
    hintConvToBaseNotNeeded,
    hintConvFromXtoItselfNotNeeded,
    hintExprAlwaysX,
    hintQuitCalled,
    hintProcessing,
    hintCodeBegin,
    hintCodeEnd,
    hintConf,
    hintUser);

const
  MsgKindToStr: array [TMsgKind] of string = (
    'unknown error',
    'illformed AST: $1',
    'cannot open ''$1''',
    'internal error: $1',
    '$1',
    '''$1'' compiler does not support C++',
    'string literal expected',
    'integer literal expected',
    'invalid character constant',
    'closing """ expected, but end of file reached',
    'closing " expected',
    'tabulators are not allowed',
    'invalid token: $1',
    'line too long',
    '$1 is not a valid number',
    'number $1 out of valid range',
    '\n not allowed in character literal',
    'closing '']'' expected, but end of file reached',
    'missing final ''',
    'identifier expected, but found ''$1''',
    'operator expected, but found ''$1''',
    '''$1'' expected',
    'string after ''include'' expected',
    'recursive include file: ''$1''',
    '''on'' or ''off'' expected',
    '''none'', ''speed'' or ''size'' expected',
    'invalid pragma',
    'unknown pragma: ''$1''',
    'pragma ''$1'' here not allowed',
    'unknown directive: ''$1''',
    'invalid directive',
    '''pop'' without a ''push'' pragma',
    'empty asm statement makes no sense',
    '''='' invalid in an expression; probably ''=='' meant',
    'invalid indentation',
    'exception expected',
    'exception already handled',
    '''return'' only allowed in routine',
    '''yield'' only allowed in iterator',
    'invalid number of ''yield'' expresions',
    '''return'' not allowed in iterator',
    'current routine cannot return an expression',
    'attempt to redefine ''$1''',
    'statement not allowed after ''return'', ''break'' or ''raise''',
    'statement expected',
    '''yield'' statement is only allowed in iterators',
    '''$1'' is no label',
    'invalid command line option: ''$1''',
    'argument for command line option expected: ''$1''',
    'invalid variable substitution in ''$1''',
    'unknown variable: ''$1''',
    'unknown C compiler: ''$1''',
    '''on'' or ''off'' expected, but ''$1'' found',
    '''none'', ''boehm'' or ''refc'' expected, but ''$1'' found',
    '''none'', ''speed'' or ''size'' expected, but ''$1'' found',
    '''gui'', ''console'' or ''lib'' expected, but ''$1'' found',
    'unknown OS: ''$1''',
    'unknown CPU: ''$1''',
    '''c'', ''c++'' or ''yaml'' expected, but ''$1'' found',
    'arguments can only be given if the ''--run'' option is selected',
    'multiple assignment is not allowed',
    ''':'' or ''='' expected, but found ''$1''',
    'expression expected, but found ''$1''',
    'undeclared identifier: ''$1''',
    'ambigious identifier: ''$1'' -- use a qualifier',
    '''$1'' is forwarded twice',
    'type expected',
    'system module needs ''$1''',
    'execution of an external program failed',
    'overloaded ''$1'' leads to ambigious calls',
    'invalid argument for ''$1''',
    'statement has no effect',
    '''$1'' expects a type or value',
    '''$1'' expects an array type',
    '''$1'' cannot be instantiated because its body has not been compiled yet',
    'expression with no type cannot be converted',
    'expression with no type cannot be casted',
    'constant division by zero',
    'ordinal type expected',
    'ordinal or float type expected',
    'over- or underflow',
    'cannot evalutate ''$1'' because type is not defined completely',
    '''chr'' expects an int in the range 0..255',
    '''staticAssert'' failed: condition is false',
    'argument to ''staticAssert'' cannot be evaluated at compile time',
    '''.'' requires a record or object type',
    'undeclared field: ''$1''',
    'index has to be an integer type',
    'index out of bounds',
    'index types do not match',
    '''[]'' operator invalid for this type',
    'value out of set bounds',
    'field initialized twice: ''$1''',
    'field ''$1'' not initialized',
    'expression cannot be called',
    'expression has no type',
    'expression ''$1'' has no type',
    '''cast'' not allowed in safe mode',
    'expression cannot be casted to $1',
    'undefined prefix operator: $1',
    ''','' or '')'' expected',
    '''{'' or ''('' expected',
    'section (''type'', ''proc'', etc.) expected',
    '''implementation'' or end of file expected',
    'range expected',
    'invalid type description',
    'attempt to redefine ''$1''',
    '''magic'' only allowed in system module',
    'unkown operator: ''$1''',
    'power of two expected',
    'string literal may not be empty',
    'calling convention expected',
    'a proc can only have one calling convention',
    'symbol must be imported if ''lib'' pragma is used',
    'expression must be of type ''bool''',
    'constant expression expected',
    'duplicate case label',
    'range is empty',
    'selector must be of an ordinal type, real or string',
    'selector must be of an ordinal type',
    'ord($1) must not be negative',
    'len($1) must be less than 32768',
    'wrong number of variables',
    'only objects can be raised',
    '''break'' only allowed in loop construct',
    'type ''$1'' has unknown size',
    'a constant can only be initialized with a constant expression',
    'a constant needs a value',
    'the result type cannot be on open array',
    'computing the type''s size produced an overflow',
    'set is too large',
    'base type of a set must be an ordinal',
    'inheritance only works with non-final objects',
    'inheritance only works with an enum',
    'illegal recursion in type ''$1''',
    'cannot instantiate: ''$1''',
    'expression has no address',
    'for a ''var'' type a variable needs to be passed',
    'type mismatch',
    'type mismatch: got (',
    'but expected one of: ',
    'but expected ''$1''',
    'ambigious call; both $1 and $2 match for: $3',
    'wrong number of type parameters',
    'out parameters cannot have default values',
    'an inline proc has no address',
    '$1 cannot be declared in parameter declaration',
    'pragmas are only in the header of a proc allowed',
    'an imported proc cannot have an implementation',
    'implementation of ''$1'' is not allowed here',
    'implementation of ''$1'' expected',
    'value returned by statement has to be discarded',
    'statement returns no value that can be discarded',
    'unknown precedence for operator; use ''infix: prec'' pragma',
    'conversion from $1 to $2 is invalid',
    'type mismatch: expected ''$1'', but got ''$2''',
    'cannot bind parameter ''$1'' twice',
    'invalid order in enum ''$1''',
    'enum ''$1'' has wholes',
    '''except'' or ''finally'' expected',
    'after catch all ''except'' or ''finally'' no section may follow',
    'end of file expected, but found token ''$1''',
    'option expected, but found ''$1''',
    'cannot evaluate forwarded constant',
    '''$1'' is not a label',
    '''$1'' needs to be of a non-generic type',
    'not all cases are covered',
    'string range in case statement not allowed',
    'unknown substitution variable: ''$1''',
    'complex statement requires indentation',
    '''$1'' is not callable',
    'no pragmas allowed for $1',
    'no generic parameters allowed for $1',
    'invalid param kind: ''$1''',
    'default argument invalid',
    'named parameter has to be an identifier',
    'no return type for $1 allowed',
    'a type conversion needs exactly one argument',
    'invalid pragma: $1',
    '$1 here not allowed',
    'invalid control flow: $1',
    'a type has no value',
    '''$1'' is no type',
    '''^'' needs a pointer or reference type',
    'invalid context for builtin ''$1''',
    'invalid expression',
    'invalid expression: ''$1''',
    'enum has no value ''$1''',
    'named expression expected',
    'named expression here not allowed',
    '''$1'' expects one type parameter',
    'array expects two type parameters',
    'invalid invisibility: ''$1''',
    'initialization here not allowed',
    '''$1'' cannot be assigned to',
    'iterators can only be defined at the module''s top level',
    'iterator needs an implementation',
    'iterator needs a return type',
    'invalid command: ''$1''',
    '''$1'' is only allowed at top level',
    'type ''$1'' needs an implementation',
    'template instantiation too nested',
    'instantiation from here',
    'invalid index value for tuple subscript',
    'command expects a filename argument',
    '''$1'' expected',
    'invalid section start',
    'grid table is not implemented',
    'general parse error',
    'new section expected',
    'whitespace expected, got ''$1''',
    '''$1'' is no valid index file',
    'cannot render reStructuredText element ''$1''',
    'type ''var var'' is not allowed',
    '''is'' expects two arguments',
    '''is'' expects object types',
    '''$1'' can never be of this subtype',
    'interpretation requires too many iterations',
    'cannot interpret node kind ''$1''',
    'field ''$1'' cannot be found',
    'invalid conversion from type ''$1''',
    'assertion failed',
    'cannot generate code for ''$1''',
    'converter needs return type',
    'converter requires one parameter',
    'unhandled exception: $1',
    'macro returned a cyclic abstract syntax tree',
    '$1',
    'cannot open ''$1'' [CannotOpenFile]',
    'octal escape sequences do not exist; leading zero is ignored [OctalEscape]',
    '''$1'' is never read [XIsNeverRead]',
    '''$1'' might not have been initialized [XmightNotBeenInit]',
    'cannot write file ''$1'' [CannotWriteMO2]',
    'cannot read file ''$1'' [CannotReadMO2]',
    '''$1'' is deprecated [Deprecated]',
    '''l'' should not be used as an identifier; may look like ''1'' (one) [SmallLshouldNotBeUsed]',
    'unknown magic ''$1'' might crash the compiler [UnknownMagic]',
    'redefinition of label ''$1'' [RedefinitionOfLabel]',
    'unknown substitution ''$1'' [UnknownSubstitutionX]',
    'language ''$1'' not supported [LanguageXNotSupported]',
    'comment ''$1'' ignored [CommentXIgnored]',
    '$1 [User]',
    'operation successful [Success]',
    'operation successful ($1 lines compiled; $2 sec total) [SuccessX]',
    'line too long [LineTooLong]',
    '''$1'' is declared but not used [XDeclaredButNotUsed]',
    'conversion to base object is not needed [ConvToBaseNotNeeded]',
    'conversion from $1 to itself is pointless [ConvFromXtoItselfNotNeeded]',
    'expression evaluates always to ''$1'' [ExprAlwaysX]',
    'quit() called [QuitCalled]',
    'processing $1 [Processing]',
    'generated code listing: [CodeBegin]',
    'end of listing [CodeEnd]',
    'used config file ''$1'' [Conf]',
    '$1 [User]'
  );
const
  WarningsToStr: array [0..13] of string = (
    'CannotOpenFile',
    'OctalEscape',
    'XIsNeverRead',
    'XmightNotBeenInit',
    'CannotWriteMO2',
    'CannotReadMO2',
    'Deprecated',
    'SmallLshouldNotBeUsed',
    'UnknownMagic',
    'RedefinitionOfLabel',
    'UnknownSubstitutionX',
    'LanguageXNotSupported',
    'CommentXIgnored',
    'User'
  );
const
  HintsToStr: array [0..12] of string = (
    'Success',
    'SuccessX',
    'LineTooLong',
    'XDeclaredButNotUsed',
    'ConvToBaseNotNeeded',
    'ConvFromXtoItselfNotNeeded',
    'ExprAlwaysX',
    'QuitCalled',
    'Processing',
    'CodeBegin',
    'CodeEnd',
    'Conf',
    'User'
  );
//[[[end]]]

const
  fatalMin = errUnknown;
  fatalMax = errInternal;
  errMin = errUnknown;
  errMax = errUser;
  warnMin = warnCannotOpenFile;
  warnMax = pred(hintSuccess);
  hintMin = hintSuccess;
  hintMax = high(TMsgKind);

type
  TNoteKind = warnMin..hintMax;
  // "notes" are warnings or hints
  TNoteKinds = set of TNoteKind;

  TLineInfo = record
    // This is designed to be as small as possible, because it is used
    // in syntax nodes. We safe space here by using two int16 and an int32
    // on 64 bit and on 32 bit systems this is only 8 bytes.
    line, col: int16;
    fileIndex: int32;
  end;

function UnknownLineInfo(): TLineInfo;

var
  gNotes: TNoteKinds = [low(TNoteKind)..high(TNoteKind)];
  gErrorCounter: int = 0; // counts the number of errors
  gHintCounter: int = 0;
  gWarnCounter: int = 0;
  gErrorMax: int = 1; // stop after gErrorMax errors

const // this format is understood by many text editors: it is the same that
  // Borland and Freepascal use
  PosErrorFormat = '$1($2, $3) Error: $4';
  PosWarningFormat = '$1($2, $3) Warning: $4';
  PosHintFormat = '$1($2, $3) Hint: $4';

  RawErrorFormat = 'Error: $1';
  RawWarningFormat = 'Warning: $1';
  RawHintFormat = 'Hint: $1';

procedure MessageOut(const s: string);

procedure rawMessage(const msg: TMsgKind; const arg: string = ''); overload;
procedure rawMessage(const msg: TMsgKind; const args: array of string); overload;

procedure liMessage(const info: TLineInfo; const msg: TMsgKind;
                    const arg: string = '');

procedure InternalError(const info: TLineInfo; const errMsg: string);
  overload;
procedure InternalError(const errMsg: string); overload;

function newLineInfo(const filename: string; line, col: int): TLineInfo;

function ToFilename(const info: TLineInfo): string;
function toColumn(const info: TLineInfo): int;
function ToLinenumber(const info: TLineInfo): int;

function MsgKindToString(kind: TMsgKind): string;

// checkpoints are used for debugging:
function checkpoint(const info: TLineInfo; const filename: string;
                    line: int): boolean;

procedure addCheckpoint(const info: TLineInfo); overload;
procedure addCheckpoint(const filename: string; line: int); overload;
function inCheckpoint(const current: TLineInfo): boolean;
// prints the line information if in checkpoint

procedure pushInfoContext(const info: TLineInfo);
procedure popInfoContext;

implementation

function UnknownLineInfo(): TLineInfo;
begin
  result.line := int16(-1);
  result.col := int16(-1);
  result.fileIndex := -1;
end;

{@ignore}
var
  filenames: array of string;
  msgContext: array of TLineInfo;
{@emit
var
  filenames: array of string = @[];
  msgContext: array of TLineInfo = @[];
}

procedure pushInfoContext(const info: TLineInfo);
var
  len: int;
begin
  len := length(msgContext);
  setLength(msgContext, len+1);
  msgContext[len] := info;
end;

procedure popInfoContext;
begin
  setLength(msgContext, length(msgContext)-1);
end;

function includeFilename(const f: string): int;
var
  i: int;
begin
  for i := high(filenames) downto low(filenames) do
    if filenames[i] = f then begin
      result := i; exit
    end;
  // not found, so add it:
  result := length(filenames);
  setLength(filenames, result+1);
  filenames[result] := f;
end;

function checkpoint(const info: TLineInfo; const filename: string;
                    line: int): boolean;
begin
  result := (int(info.line) = line) and (
    ChangeFileExt(extractFilename(filenames[info.fileIndex]), '') = filename);
end;


{@ignore}
var
  checkPoints: array of TLineInfo;
{@emit
var
  checkPoints: array of TLineInfo = @[];
}

procedure addCheckpoint(const info: TLineInfo); overload;
var
  len: int;
begin
  len := length(checkPoints);
  setLength(checkPoints, len+1);
  checkPoints[len] := info;
end;

procedure addCheckpoint(const filename: string; line: int); overload;
begin
  addCheckpoint(newLineInfo(filename, line, -1));
end;

function newLineInfo(const filename: string; line, col: int): TLineInfo;
begin
  result.fileIndex := includeFilename(filename);
  result.line := int16(line);
  result.col := int16(col);
end;

function ToFilename(const info: TLineInfo): string;
begin
  if info.fileIndex = -1 then result := '???'
  else result := filenames[info.fileIndex]
end;

function ToLinenumber(const info: TLineInfo): int;
begin
  result := info.line
end;

function toColumn(const info: TLineInfo): int;
begin
  result := info.col
end;

procedure MessageOut(const s: string);
begin  // change only this proc to put it elsewhere
  Writeln(output, s);
end;

function coordToStr(const coord: int): string;
begin
  if coord = -1 then result := '???'
  else result := toString(coord)
end;

function MsgKindToString(kind: TMsgKind): string;
begin // later versions may provide translated error messages
  result := msgKindToStr[kind];
end;

function getMessageStr(msg: TMsgKind; const arg: string): string;
begin
  result := format(msgKindToString(msg), [arg]);
end;

function inCheckpoint(const current: TLineInfo): boolean;
var
  i: int;
begin
  result := false;
  if not (optCheckpoints in gOptions) then exit; // ignore all checkpoints
  for i := 0 to high(checkPoints) do begin
    if (current.line = checkPoints[i].line) and
       (current.fileIndex = (checkPoints[i].fileIndex)) then begin
      MessageOut(Format('$1($2, $3) Checkpoint: ', [toFilename(current),
                           coordToStr(current.line),
                           coordToStr(current.col)]));
      result := true;
      exit
    end
  end
end;

procedure handleError(const msg: TMsgKind);
begin
  if msg = errInternal then assert(false); // we want a stack trace here
  if (msg >= fatalMin) and (msg <= fatalMax) then begin
    if gVerbosity >= 3 then assert(false);
    halt(1)
  end;
  if (msg >= errMin) and (msg <= errMax) then begin
    inc(gErrorCounter);
    if gErrorCounter >= gErrorMax then begin
      if gVerbosity >= 3 then assert(false);
      halt(1) // one error stops the compiler
    end
  end
end;

procedure writeContext;
var
  i: int;
begin
  for i := 0 to length(msgContext)-1 do begin
    MessageOut(Format(posErrorFormat, [toFilename(msgContext[i]),
                             coordToStr(msgContext[i].line),
                             coordToStr(msgContext[i].col),
                             getMessageStr(errInstantiationFrom, '')]));
  end;
end;

procedure rawMessage(const msg: TMsgKind; const args: array of string);
var
  frmt: string;
begin
  case msg of
    errMin..errMax: begin
      writeContext();
      frmt := rawErrorFormat;
    end;
    warnMin..warnMax: begin
      if not (optWarns in gOptions) then exit;
      if not (msg in gNotes) then exit;
      frmt := rawWarningFormat;
      inc(gWarnCounter);
    end;
    hintMin..hintMax: begin
      if not (optHints in gOptions) then exit;
      if not (msg in gNotes) then exit;
      frmt := rawHintFormat;
      inc(gHintCounter);
    end;
    else assert(false) // cannot happen
  end;
  MessageOut(Format(frmt, format(msgKindToString(msg), args)));
  handleError(msg);
end;

procedure rawMessage(const msg: TMsgKind; const arg: string = '');
begin
  rawMessage(msg, [arg]);
end;

procedure liMessage(const info: TLineInfo; const msg: TMsgKind;
                    const arg: string = '');
var
  frmt: string;
begin
  case msg of
    errMin..errMax: begin
      writeContext();
      frmt := posErrorFormat;
    end;
    warnMin..warnMax: begin
      if not (optWarns in gOptions) then exit;
      if not (msg in gNotes) then exit;
      frmt := posWarningFormat;
      inc(gWarnCounter);
    end;
    hintMin..hintMax: begin
      if not (optHints in gOptions) then exit;
      if not (msg in gNotes) then exit;
      frmt := posHintFormat;
      inc(gHintCounter);
    end;
    else assert(false) // cannot happen
  end;
  MessageOut(Format(frmt, [toFilename(info),
                           coordToStr(info.line),
                           coordToStr(info.col),
                           getMessageStr(msg, arg)]));
  handleError(msg);
end;

procedure InternalError(const info: TLineInfo; const errMsg: string);
begin
  writeContext();
  liMessage(info, errInternal, errMsg);
end;

procedure InternalError(const errMsg: string); overload;
begin
  writeContext();
  rawMessage(errInternal, errMsg);
end;

end.
