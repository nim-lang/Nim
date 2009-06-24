//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit pasparse;

// This module implements the parser of the Pascal variant Nimrod is written in.
// It transfers a Pascal module into a Nimrod AST. Then the renderer can be
// used to generate the Nimrod version of the compiler.

{$include config.inc}

interface

uses
  nsystem, nos, llstream, charsets, scanner, paslex, idents, wordrecg, strutils,
  ast, astalgo, msgs, options;

type
  TPasSection = (seImplementation, seInterface);
  TPasContext = (conExpr, conStmt, conTypeDesc);
  TPasParser = record
    section: TPasSection;
    inParamList: boolean;
    context: TPasContext;    // needed for the @emit command
    lastVarSection: PNode;
    lex: TPasLex;
    tok: TPasTok;
    repl: TIdTable;       // replacements
  end;

  TReplaceTuple = array [0..1] of string;

const
  ImportBlackList: array [1..3] of string = (
    'nsystem', 'sysutils', 'charsets'
  );
  stdReplacements: array [1..19] of TReplaceTuple = (
    ('include',      'incl'),
    ('exclude',      'excl'),
    ('pchar',        'cstring'),
    ('assignfile',   'open'),
    ('integer',      'int'),
    ('longword',     'int32'),
    ('cardinal',     'int'),
    ('boolean',      'bool'),
    ('shortint',     'int8'),
    ('smallint',     'int16'),
    ('longint',      'int32'),
    ('byte',         'int8'),
    ('word',         'int16'),
    ('single',       'float32'),
    ('double',       'float64'),
    ('real',         'float'),
    ('length',       'len'),
    ('len',          'length'),
    ('setlength',    'setlen')
  );
  nimReplacements: array [1..32] of TReplaceTuple = (
    ('nimread',      'read'),
    ('nimwrite',     'write'),
    ('nimclosefile', 'close'),
    ('closefile',    'close'),
    ('openfile',     'open'),
    ('nsystem', 'system'),
    ('ntime', 'times'),
    ('nos', 'os'),
    ('nmath', 'math'),

    ('ncopy', 'copy'),
    ('addChar', 'add'),
    ('halt', 'quit'),
    ('nobject', 'TObject'),
    ('eof', 'EndOfFile'),

    ('input', 'stdin'),
    ('output', 'stdout'),
    ('addu', '`+%`'),
    ('subu', '`-%`'),
    ('mulu', '`*%`'),
    ('divu', '`/%`'),
    ('modu', '`%%`'),
    ('ltu', '`<%`'),
    ('leu', '`<=%`'),
    ('shlu', '`shl`'),
    ('shru', '`shr`'),
    ('assigned',     'not isNil'),

    ('eintoverflow', 'EOverflow'),
    ('format', '`%`'),
    ('snil', 'nil'),
    ('tostringf', '$'+''),
    ('ttextfile', 'tfile'),
    ('tbinaryfile', 'tfile') {,
    ('NL', '"\n"'),
    ('tabulator', '''\t'''),
    ('esc', '''\e'''),
    ('cr', '''\r'''),
    ('lf', '''\l'''),
    ('ff', '''\f'''),
    ('bel', '''\a'''),
    ('backspace', '''\b'''),
    ('vt', '''\v''') }
  );

function ParseUnit(var p: TPasParser): PNode;

procedure openPasParser(var p: TPasParser; const filename: string;
                        inputStream: PLLStream);
procedure closePasParser(var p: TPasParser);

procedure exSymbol(var n: PNode);
procedure fixRecordDef(var n: PNode);
// XXX: move these two to an auxiliary module

implementation

procedure OpenPasParser(var p: TPasParser; const filename: string;
                        inputStream: PLLStream);
var
  i: int;
begin
{@ignore}
  FillChar(p, sizeof(p), 0);
{@emit}
  OpenLexer(p.lex, filename, inputStream);
  initIdTable(p.repl);
  for i := low(stdReplacements) to high(stdReplacements) do
    IdTablePut(p.repl, getIdent(stdReplacements[i][0]),
                       getIdent(stdReplacements[i][1]));
  if gCmd = cmdBoot then
    for i := low(nimReplacements) to high(nimReplacements) do
      IdTablePut(p.repl, getIdent(nimReplacements[i][0]),
                         getIdent(nimReplacements[i][1]));
end;

procedure ClosePasParser(var p: TPasParser);
begin
  CloseLexer(p.lex);
end;

// ---------------- parser helpers --------------------------------------------

procedure getTok(var p: TPasParser);
begin
  getPasTok(p.lex, p.tok)
end;

procedure parMessage(const p: TPasParser; const msg: TMsgKind;
                     const arg: string = '');
begin
  lexMessage(p.lex, msg, arg);
end;

function parLineInfo(const p: TPasParser): TLineInfo;
begin
  result := getLineInfo(p.lex)
end;

procedure skipCom(var p: TPasParser; n: PNode);
begin
  while p.tok.xkind = pxComment do begin
    if (n <> nil) then begin
      if n.comment = snil then n.comment := p.tok.literal
      else n.comment := n.comment +{&} nl +{&} p.tok.literal;
    end
    else
      parMessage(p, warnCommentXIgnored, p.tok.literal);
    getTok(p);
  end
end;

procedure ExpectIdent(const p: TPasParser);
begin
  if p.tok.xkind <> pxSymbol then
    lexMessage(p.lex, errIdentifierExpected, pasTokToStr(p.tok));
end;

procedure Eat(var p: TPasParser; xkind: TPasTokKind);
begin
  if p.tok.xkind = xkind then getTok(p)
  else lexMessage(p.lex, errTokenExpected, PasTokKindToStr[xkind])
end;

procedure Opt(var p: TPasParser; xkind: TPasTokKind);
begin
  if p.tok.xkind = xkind then getTok(p)
end;
// ----------------------------------------------------------------------------

function newNodeP(kind: TNodeKind; const p: TPasParser): PNode;
begin
  result := newNodeI(kind, getLineInfo(p.lex));
end;

function newIntNodeP(kind: TNodeKind; const intVal: BiggestInt;
                     const p: TPasParser): PNode;
begin
  result := newNodeP(kind, p);
  result.intVal := intVal;
end;

function newFloatNodeP(kind: TNodeKind; const floatVal: BiggestFloat;
                       const p: TPasParser): PNode;
begin
  result := newNodeP(kind, p);
  result.floatVal := floatVal;
end;

function newStrNodeP(kind: TNodeKind; const strVal: string;
                     const p: TPasParser): PNode;
begin
  result := newNodeP(kind, p);
  result.strVal := strVal;
end;

function newIdentNodeP(ident: PIdent; const p: TPasParser): PNode;
begin
  result := newNodeP(nkIdent, p);
  result.ident := ident;
end;

function createIdentNodeP(ident: PIdent; const p: TPasParser): PNode;
var
  x: PIdent;
begin
  result := newNodeP(nkIdent, p);
  x := PIdent(IdTableGet(p.repl, ident));
  if x <> nil then result.ident := x
  else result.ident := ident;
end;

// ------------------- Expression parsing ------------------------------------

function parseExpr(var p: TPasParser): PNode; forward;
function parseStmt(var p: TPasParser): PNode; forward;
function parseTypeDesc(var p: TPasParser;
                       definition: PNode=nil): PNode; forward;

function parseEmit(var p: TPasParser; definition: PNode): PNode;
var
  a: PNode;
begin
  getTok(p); // skip 'emit'
  result := nil;
  if p.tok.xkind <> pxCurlyDirRi then
    case p.context of
      conExpr: result := parseExpr(p);
      conStmt: begin
        result := parseStmt(p);
        if p.tok.xkind <> pxCurlyDirRi then begin
          a := result;
          result := newNodeP(nkStmtList, p);
          addSon(result, a);
          while p.tok.xkind <> pxCurlyDirRi do begin
            addSon(result, parseStmt(p));
          end
        end
      end;
      conTypeDesc: result := parseTypeDesc(p, definition);
    end;
  eat(p, pxCurlyDirRi);
end;

function parseCommand(var p: TPasParser; definition: PNode=nil): PNode;
var
  a: PNode;
begin
  result := nil;
  getTok(p);
  if p.tok.ident.id = getIdent('discard').id then begin
    result := newNodeP(nkDiscardStmt, p);
    getTok(p); eat(p, pxCurlyDirRi);
    addSon(result, parseExpr(p));
  end
  else if p.tok.ident.id = getIdent('set').id then begin
    getTok(p); eat(p, pxCurlyDirRi);
    result := parseExpr(p);
    result.kind := nkCurly;
    assert(sonsNotNil(result));
  end
  else if p.tok.ident.id = getIdent('cast').id then begin
    getTok(p); eat(p, pxCurlyDirRi);
    a := parseExpr(p);
    if (a.kind = nkCall) and (sonsLen(a) = 2) then begin
      result := newNodeP(nkCast, p);
      addSon(result, a.sons[0]);
      addSon(result, a.sons[1]);
    end
    else begin
      parMessage(p, errInvalidDirective);
      result := a
    end
  end
  else if p.tok.ident.id = getIdent('emit').id then begin
    result := parseEmit(p, definition);
  end
  else if p.tok.ident.id = getIdent('ignore').id then begin
    getTok(p); eat(p, pxCurlyDirRi);
    while true do begin
      case p.tok.xkind of
        pxEof: parMessage(p, errTokenExpected, '{@emit}');
        pxCommand: begin
          getTok(p);
          if p.tok.ident.id = getIdent('emit').id then begin
            result := parseEmit(p, definition);
            break
          end
          else begin
            while (p.tok.xkind <> pxCurlyDirRi) and (p.tok.xkind <> pxEof) do
              getTok(p);
            eat(p, pxCurlyDirRi);
          end;
        end;
        else getTok(p) // skip token
      end
    end
  end
  else if p.tok.ident.id = getIdent('ptr').id then begin
    result := newNodeP(nkPtrTy, p);
    getTok(p); eat(p, pxCurlyDirRi);
  end
  else if p.tok.ident.id = getIdent('tuple').id then begin
    result := newNodeP(nkTupleTy, p);
    getTok(p); eat(p, pxCurlyDirRi);
  end
  else if p.tok.ident.id = getIdent('acyclic').id then begin
    result := newIdentNodeP(p.tok.ident, p);
    getTok(p); eat(p, pxCurlyDirRi);
  end
  else begin
    parMessage(p, errUnknownDirective, pasTokToStr(p.tok));
    while true do begin
      getTok(p);
      if (p.tok.xkind = pxCurlyDirRi) or (p.tok.xkind = pxEof) then break;
    end;
    eat(p, pxCurlyDirRi);
    result := nil
  end;
end;

function getPrecedence(const kind: TPasTokKind): int;
begin
  case kind of
    pxDiv, pxMod, pxStar, pxSlash, pxShl, pxShr, pxAnd: result := 5; // highest
    pxPlus, pxMinus, pxOr, pxXor: result := 4;
    pxIn, pxEquals, pxLe, pxLt, pxGe, pxGt, pxNeq, pxIs: result := 3;
    else result := -1;
  end;
end;

function rangeExpr(var p: TPasParser): PNode;
var
  a: PNode;
begin
  a := parseExpr(p);
  if p.tok.xkind = pxDotDot then begin
    result := newNodeP(nkRange, p);
    addSon(result, a);
    getTok(p); skipCom(p, result);
    addSon(result, parseExpr(p))
  end
  else result := a
end;

function bracketExprList(var p: TPasParser; first: PNode): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkBracketExpr, p);
  addSon(result, first);
  getTok(p);
  skipCom(p, result);
  while true do begin
    if p.tok.xkind = pxBracketRi then begin
      getTok(p); break
    end;
    if p.tok.xkind = pxEof then begin
      parMessage(p, errTokenExpected, PasTokKindToStr[pxBracketRi]); break
    end;
    a := rangeExpr(p);
    skipCom(p, a);
    if p.tok.xkind = pxComma then begin
      getTok(p);
      skipCom(p, a)
    end;
    addSon(result, a);
  end;
end;

function exprColonEqExpr(var p: TPasParser; kind: TNodeKind;
                         tok: TPasTokKind): PNode;
var
  a: PNode;
begin
  a := parseExpr(p);
  if p.tok.xkind = tok then begin
    result := newNodeP(kind, p);
    getTok(p);
    skipCom(p, result);
    addSon(result, a);
    addSon(result, parseExpr(p));
  end
  else
    result := a
end;

procedure exprListAux(var p: TPasParser; elemKind: TNodeKind;
                      endTok, sepTok: TPasTokKind; result: PNode);
var
  a: PNode;
begin
  getTok(p);
  skipCom(p, result);
  while true do begin
    if p.tok.xkind = endTok then begin
      getTok(p); break
    end;
    if p.tok.xkind = pxEof then begin
      parMessage(p, errTokenExpected, PasTokKindToStr[endtok]); break
    end;
    a := exprColonEqExpr(p, elemKind, sepTok);
    skipCom(p, a);
    if (p.tok.xkind = pxComma) or (p.tok.xkind = pxSemicolon) then begin
      getTok(p);
      skipCom(p, a)
    end;
    addSon(result, a);
  end;
end;

function qualifiedIdent(var p: TPasParser): PNode;
var
  a: PNode;
begin
  if p.tok.xkind = pxSymbol then
    result := createIdentNodeP(p.tok.ident, p)
  else begin
    parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
    result := nil;
    exit
  end;
  getTok(p);
  skipCom(p, result);
  if p.tok.xkind = pxDot then begin
    getTok(p);
    skipCom(p, result);
    if p.tok.xkind = pxSymbol then begin
      a := result;
      result := newNodeI(nkQualified, a.info);
      addSon(result, a);
      addSon(result, createIdentNodeP(p.tok.ident, p));
      getTok(p);
    end
    else parMessage(p, errIdentifierExpected, pasTokToStr(p.tok))
  end;
end;

procedure qualifiedIdentListAux(var p: TPasParser; endTok: TPasTokKind;
                                result: PNode);
var
  a: PNode;
begin
  getTok(p);
  skipCom(p, result);
  while true do begin
    if p.tok.xkind = endTok then begin
      getTok(p); break
    end;
    if p.tok.xkind = pxEof then begin
      parMessage(p, errTokenExpected, PasTokKindToStr[endtok]); break
    end;
    a := qualifiedIdent(p);
    skipCom(p, a);
    if p.tok.xkind = pxComma then begin
      getTok(p); skipCom(p, a)
    end;
    addSon(result, a);
  end
end;

function exprColonEqExprList(var p: TPasParser; kind, elemKind: TNodeKind;
                             endTok, sepTok: TPasTokKind): PNode;
begin
  result := newNodeP(kind, p);
  exprListAux(p, elemKind, endTok, sepTok, result);
end;

procedure setBaseFlags(n: PNode; base: TNumericalBase);
begin
  case base of
    base10: begin end;
    base2: include(n.flags, nfBase2);
    base8: include(n.flags, nfBase8);
    base16: include(n.flags, nfBase16);
  end
end;

function identOrLiteral(var p: TPasParser): PNode;
var
  a: PNode;
begin
  case p.tok.xkind of
    pxSymbol: begin
      result := createIdentNodeP(p.tok.ident, p);
      getTok(p)
    end;
    // literals
    pxIntLit: begin
      result := newIntNodeP(nkIntLit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    pxInt64Lit: begin
      result := newIntNodeP(nkInt64Lit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    pxFloatLit: begin
      result := newFloatNodeP(nkFloatLit, p.tok.fNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    pxStrLit: begin
      if length(p.tok.literal) <> 1 then
        result := newStrNodeP(nkStrLit, p.tok.literal, p)
      else
        result := newIntNodeP(nkCharLit, ord(p.tok.literal[strStart]), p);
      getTok(p);
    end;
    pxNil: begin
      result := newNodeP(nkNilLit, p);
      getTok(p);
    end;

    pxParLe: begin // () constructor
      result := exprColonEqExprList(p, nkPar, nkExprColonExpr, pxParRi,
                                    pxColon);
      //if hasSonWith(result, nkExprColonExpr) then
      //  replaceSons(result, nkExprColonExpr, nkExprEqExpr)
      if (sonsLen(result) > 1) and not hasSonWith(result, nkExprColonExpr) then
        result.kind := nkBracket; // is an array constructor
    end;
    pxBracketLe: begin // [] constructor
      result := newNodeP(nkBracket, p);
      getTok(p);
      skipCom(p, result);
      while (p.tok.xkind <> pxBracketRi) and (p.tok.xkind <> pxEof) do begin
        a := rangeExpr(p);
        if a.kind = nkRange then
          result.kind := nkCurly; // it is definitely a set literal
        opt(p, pxComma);
        skipCom(p, a);
        assert(a <> nil);
        addSon(result, a);
      end;
      eat(p, pxBracketRi);
    end;
    pxCommand: result := parseCommand(p);
    else begin
      parMessage(p, errExprExpected, pasTokToStr(p.tok));
      getTok(p); // we must consume a token here to prevend endless loops!
      result := nil
    end
  end;
  if result <> nil then
    skipCom(p, result);
end;

function primary(var p: TPasParser): PNode;
var
  a: PNode;
begin
  // prefix operator?
  if (p.tok.xkind = pxNot) or (p.tok.xkind = pxMinus)
  or (p.tok.xkind = pxPlus) then begin
    result := newNodeP(nkPrefix, p);
    a := newIdentNodeP(getIdent(pasTokToStr(p.tok)), p);
    addSon(result, a);
    getTok(p);
    skipCom(p, a);
    addSon(result, primary(p));
    exit
  end
  else if p.tok.xkind = pxAt then begin
    result := newNodeP(nkAddr, p);
    a := newIdentNodeP(getIdent(pasTokToStr(p.tok)), p);
    getTok(p);
    if p.tok.xkind = pxBracketLe then begin
      result := newNodeP(nkPrefix, p);
      addSon(result, a);
      addSon(result, identOrLiteral(p));
    end
    else
      addSon(result, primary(p));
    exit
  end;
  result := identOrLiteral(p);
  while true do begin
    case p.tok.xkind of
      pxParLe: begin
        a := result;
        result := newNodeP(nkCall, p);
        addSon(result, a);
        exprListAux(p, nkExprEqExpr, pxParRi, pxEquals, result);
      end;
      pxDot: begin
        a := result;
        result := newNodeP(nkDotExpr, p);
        addSon(result, a);
        getTok(p); // skip '.'
        skipCom(p, result);
        if p.tok.xkind = pxSymbol then begin
          addSon(result, createIdentNodeP(p.tok.ident, p));
          getTok(p);
        end
        else
          parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
      end;
      pxHat: begin
        a := result;
        result := newNodeP(nkDerefExpr, p);
        addSon(result, a);
        getTok(p);
      end;
      pxBracketLe: result := bracketExprList(p, result);
      else break
    end
  end
end;

function lowestExprAux(var p: TPasParser; out v: PNode;
                       limit: int): TPasTokKind;
var
  op, nextop: TPasTokKind;
  opPred: int;
  v2, node, opNode: PNode;
begin
  v := primary(p);
  // expand while operators have priorities higher than 'limit'
  op := p.tok.xkind;
  opPred := getPrecedence(op);
  while (opPred > limit) do begin
    node := newNodeP(nkInfix, p);
    opNode := newIdentNodeP(getIdent(pasTokToStr(p.tok)), p);
    // skip operator:
    getTok(p);
    case op of
      pxPlus: begin
        case p.tok.xkind of
          pxPer: begin getTok(p); eat(p, pxCurlyDirRi);
                       opNode.ident := getIdent('+%') end;
          pxAmp: begin getTok(p); eat(p, pxCurlyDirRi);
                       opNode.ident := getIdent('&'+'') end;
          else begin end
        end
      end;
      pxMinus: begin
        if p.tok.xkind = pxPer then begin
          getTok(p); eat(p, pxCurlyDirRi);
          opNode.ident := getIdent('-%')
        end;
      end;
      pxEquals: opNode.ident := getIdent('==');
      pxNeq:    opNode.ident := getIdent('!=');
      else begin end
    end;

    skipCom(p, opNode);

    // read sub-expression with higher priority
    nextop := lowestExprAux(p, v2, opPred);
    addSon(node, opNode);
    addSon(node, v);
    addSon(node, v2);
    v := node;
    op := nextop;
    opPred := getPrecedence(nextop);
  end;
  result := op;  // return first untreated operator
end;

function fixExpr(n: PNode): PNode;
var
  i: int;
begin
  result := n;
  if n = nil then exit;
  case n.kind of
    nkInfix: begin
      if n.sons[1].kind = nkBracket then // binary expression with [] is a set
        n.sons[1].kind := nkCurly;
      if n.sons[2].kind = nkBracket then // binary expression with [] is a set
        n.sons[2].kind := nkCurly;
      if (n.sons[0].kind = nkIdent) then begin
        if (n.sons[0].ident.id = getIdent('+'+'').id) then begin
          if (n.sons[1].kind = nkCharLit)
              and (n.sons[2].kind = nkStrLit) and (n.sons[2].strVal = '') then
          begin
              result := newStrNode(nkStrLit, chr(int(n.sons[1].intVal))+'');
              result.info := n.info;
              exit; // do not process sons as they don't exist anymore
          end
          else if (n.sons[1].kind in [nkCharLit, nkStrLit])
               or (n.sons[2].kind in [nkCharLit, nkStrLit]) then begin
            n.sons[0].ident := getIdent('&'+''); // fix operator
          end
        end
      end
    end
    else begin end
  end;
  if not (n.kind in [nkEmpty..nkNilLit]) then
    for i := 0 to sonsLen(n)-1 do
      result.sons[i] := fixExpr(n.sons[i])
end;

function parseExpr(var p: TPasParser): PNode;
var
  oldcontext: TPasContext;
begin
  oldcontext := p.context;
  p.context := conExpr;
  if p.tok.xkind = pxCommand then begin
    result := parseCommand(p)
  end
  else begin
  {@discard} lowestExprAux(p, result, -1);
    result := fixExpr(result)
  end;
  //if result = nil then
  //  internalError(parLineInfo(p), 'parseExpr() returned nil');
  p.context := oldcontext;
end;

// ---------------------- statement parser ------------------------------------
function parseExprStmt(var p: TPasParser): PNode;
var
  a, b: PNode;
  info: TLineInfo;
begin
  info := parLineInfo(p);
  a := parseExpr(p);
  if p.tok.xkind = pxAsgn then begin
    getTok(p);
    skipCom(p, a);
    b := parseExpr(p);
    result := newNodeI(nkAsgn, info);
    addSon(result, a);
    addSon(result, b);
  end
  else
    result := a
end;

function inImportBlackList(ident: PIdent): bool;
var
  i: int;
begin
  for i := low(ImportBlackList) to high(ImportBlackList) do
    if ident.id = getIdent(ImportBlackList[i]).id then begin
      result := true; exit
    end;
  result := false
end;

function parseUsesStmt(var p: TPasParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkImportStmt, p);
  getTok(p); // skip `import`
  skipCom(p, result);
  while true do begin
    case p.tok.xkind of
      pxEof: break;
      pxSymbol:   a := newIdentNodeP(p.tok.ident, p);
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        break
      end;
    end;
    getTok(p); // skip identifier, string
    skipCom(p, a);
    if (gCmd <> cmdBoot) or not inImportBlackList(a.ident) then
      addSon(result, createIdentNodeP(a.ident, p));
    if p.tok.xkind = pxComma then begin
      getTok(p);
      skipCom(p, a)
    end
    else break
  end;
  if sonsLen(result) = 0 then result := nil;
end;

function parseIncludeDir(var p: TPasParser): PNode;
var
  filename: string;
begin
  result := newNodeP(nkIncludeStmt, p);
  getTok(p); // skip `include`
  filename := '';
  while true do begin
    case p.tok.xkind of
      pxSymbol, pxDot, pxDotDot, pxSlash: begin
        filename := filename +{&} pasTokToStr(p.tok);
        getTok(p);
      end;
      pxStrLit: begin
        filename := p.tok.literal;
        getTok(p);
        break
      end;
      pxCurlyDirRi: break;
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        break
      end;
    end;
  end;
  addSon(result, newStrNodeP(nkStrLit, changeFileExt(filename, 'nim'), p));
  if filename = 'config.inc' then result := nil;
end;

function definedExprAux(var p: TPasParser): PNode;
begin
  result := newNodeP(nkCall, p);
  addSon(result, newIdentNodeP(getIdent('defined'), p));
  ExpectIdent(p);
  addSon(result, createIdentNodeP(p.tok.ident, p));
  getTok(p);
end;

function isHandledDirective(const p: TPasParser): bool;
begin
  result := false;
  if p.tok.xkind in [pxCurlyDirLe, pxStarDirLe] then
    case whichKeyword(p.tok.ident) of
      wElse, wEndif: result := false
      else result := true
    end
end;

function parseStmtList(var p: TPasParser): PNode;
begin
  result := newNodeP(nkStmtList, p);
  while true do begin
    case p.tok.xkind of
      pxEof: break;
      pxCurlyDirLe, pxStarDirLe: begin
        if not isHandledDirective(p) then break;
      end
      else begin end
    end;
    addSon(result, parseStmt(p))
  end;
  if sonsLen(result) = 1 then result := result.sons[0];
end;

procedure parseIfDirAux(var p: TPasParser; result: PNode);
var
  s: PNode;
  endMarker: TPasTokKind;
begin
  addSon(result.sons[0], parseStmtList(p));
  if p.tok.xkind in [pxCurlyDirLe, pxStarDirLe] then begin
    endMarker := succ(p.tok.xkind);
    if whichKeyword(p.tok.ident) = wElse then begin
      s := newNodeP(nkElse, p);
      while (p.tok.xkind <> pxEof) and (p.tok.xkind <> endMarker) do getTok(p);
      eat(p, endMarker);
      addSon(s, parseStmtList(p));
      addSon(result, s);
    end;
    if p.tok.xkind in [pxCurlyDirLe, pxStarDirLe] then begin
      endMarker := succ(p.tok.xkind);
      if whichKeyword(p.tok.ident) = wEndif then begin
        while (p.tok.xkind <> pxEof) and (p.tok.xkind <> endMarker) do getTok(p);
        eat(p, endMarker);
      end
      else parMessage(p, errXExpected, '{$endif}');
    end
  end
  else
    parMessage(p, errXExpected, '{$endif}');
end;

function parseIfdefDir(var p: TPasParser; endMarker: TPasTokKind): PNode;
begin
  result := newNodeP(nkWhenStmt, p);
  addSon(result, newNodeP(nkElifBranch, p));
  getTok(p);
  addSon(result.sons[0], definedExprAux(p));
  eat(p, endMarker);
  parseIfDirAux(p, result);
end;

function parseIfndefDir(var p: TPasParser; endMarker: TPasTokKind): PNode;
var
  e: PNode;
begin
  result := newNodeP(nkWhenStmt, p);
  addSon(result, newNodeP(nkElifBranch, p));
  getTok(p);
  e := newNodeP(nkCall, p);
  addSon(e, newIdentNodeP(getIdent('not'), p));
  addSon(e, definedExprAux(p));
  eat(p, endMarker);
  addSon(result.sons[0], e);
  parseIfDirAux(p, result);
end;

function parseIfDir(var p: TPasParser; endMarker: TPasTokKind): PNode;
begin
  result := newNodeP(nkWhenStmt, p);
  addSon(result, newNodeP(nkElifBranch, p));
  getTok(p);
  addSon(result.sons[0], parseExpr(p));
  eat(p, endMarker);
  parseIfDirAux(p, result);
end;

function parseDirective(var p: TPasParser): PNode;
var
  endMarker: TPasTokKind;
begin
  result := nil;
  if not (p.tok.xkind in [pxCurlyDirLe, pxStarDirLe]) then exit;
  endMarker := succ(p.tok.xkind);
  if p.tok.ident <> nil then
    case whichKeyword(p.tok.ident) of
      wInclude: begin
        result := parseIncludeDir(p);
        eat(p, endMarker);
      end;
      wIf: result := parseIfDir(p, endMarker);
      wIfdef: result := parseIfdefDir(p, endMarker);
      wIfndef: result := parseIfndefDir(p, endMarker);
      else begin
        // skip unknown compiler directive
        while (p.tok.xkind <> pxEof) and (p.tok.xkind <> endMarker) do
          getTok(p);
        eat(p, endMarker);
      end
    end
  else eat(p, endMarker);
end;

function parseRaise(var p: TPasParser): PNode;
begin
  result := newNodeP(nkRaiseStmt, p);
  getTok(p);
  skipCom(p, result);
  if p.tok.xkind <> pxSemicolon then addSon(result, parseExpr(p))
  else addSon(result, nil);
end;

function parseIf(var p: TPasParser): PNode;
var
  branch: PNode;
begin
  result := newNodeP(nkIfStmt, p);
  while true do begin
    getTok(p); // skip ``if``
    branch := newNodeP(nkElifBranch, p);
    skipCom(p, branch);
    addSon(branch, parseExpr(p));
    eat(p, pxThen);
    skipCom(p, branch);
    addSon(branch, parseStmt(p));
    skipCom(p, branch);
    addSon(result, branch);
    if p.tok.xkind = pxElse then begin
      getTok(p);
      if p.tok.xkind <> pxIf then begin
        // ordinary else part:
        branch := newNodeP(nkElse, p);
        skipCom(p, result); // BUGFIX
        addSon(branch, parseStmt(p));
        addSon(result, branch);
        break
      end
      // else: next iteration
    end
    else break
  end
end;

function parseWhile(var p: TPasParser): PNode;
begin
  result := newNodeP(nkWhileStmt, p);
  getTok(p);
  skipCom(p, result);
  addSon(result, parseExpr(p));
  eat(p, pxDo);
  skipCom(p, result);
  addSon(result, parseStmt(p));
end;

function parseRepeat(var p: TPasParser): PNode;
var
  a, b, c, s: PNode;
begin
  result := newNodeP(nkWhileStmt, p);
  getTok(p);
  skipCom(p, result);
  addSon(result, newIdentNodeP(getIdent('true'), p));
  s := newNodeP(nkStmtList, p);
  while (p.tok.xkind <> pxEof) and (p.tok.xkind <> pxUntil) do begin
    addSon(s, parseStmt(p))
  end;
  eat(p, pxUntil);
  a := newNodeP(nkIfStmt, p);
  skipCom(p, a);
  b := newNodeP(nkElifBranch, p);
  c := newNodeP(nkBreakStmt, p);
  addSon(c, nil);
  addSon(b, parseExpr(p));
  skipCom(p, a);
  addSon(b, c);
  addSon(a, b);

  if (b.sons[0].kind = nkIdent) and (b.sons[0].ident.id = getIdent('false').id)
  then begin end // do not add an ``if false: break`` statement
  else addSon(s, a);
  addSon(result, s);
end;

function parseCase(var p: TPasParser): PNode;
var
  b: PNode;
begin
  result := newNodeP(nkCaseStmt, p);
  getTok(p);
  addSon(result, parseExpr(p));
  eat(p, pxOf);
  skipCom(p, result);
  while (p.tok.xkind <> pxEnd) and (p.tok.xkind <> pxEof) do begin
    if p.tok.xkind = pxElse then begin
      b := newNodeP(nkElse, p);
      getTok(p);
    end
    else begin
      b := newNodeP(nkOfBranch, p);
      while (p.tok.xkind <> pxEof) and (p.tok.xkind <> pxColon) do begin
        addSon(b, rangeExpr(p));
        opt(p, pxComma);
        skipcom(p, b);
      end;
      eat(p, pxColon);
    end;
    skipCom(p, b);
    addSon(b, parseStmt(p));
    addSon(result, b);
    if b.kind = nkElse then break;
  end;
  eat(p, pxEnd);
end;

function parseTry(var p: TPasParser): PNode;
var
  b, e: PNode;
begin
  result := newNodeP(nkTryStmt, p);
  getTok(p);
  skipCom(p, result);
  b := newNodeP(nkStmtList, p);
  while not (p.tok.xkind in [pxFinally, pxExcept, pxEof, pxEnd]) do
    addSon(b, parseStmt(p));
  addSon(result, b);
  if p.tok.xkind = pxExcept then begin
    getTok(p);
    while p.tok.ident.id = getIdent('on').id do begin
      b := newNodeP(nkExceptBranch, p);
      getTok(p);
      e := qualifiedIdent(p);
      if p.tok.xkind = pxColon then begin
        getTok(p);
        e := qualifiedIdent(p);
      end;
      addSon(b, e);
      eat(p, pxDo);
      addSon(b, parseStmt(p));
      addSon(result, b);
      if p.tok.xkind = pxCommand then {@discard} parseCommand(p);
    end;
    if p.tok.xkind = pxElse then begin
      b := newNodeP(nkExceptBranch, p);
      getTok(p);
      addSon(b, parseStmt(p));
      addSon(result, b);
    end
  end;
  if p.tok.xkind = pxFinally then begin
    b := newNodeP(nkFinally, p);
    getTok(p);
    e := newNodeP(nkStmtList, p);
    while (p.tok.xkind <> pxEof) and (p.tok.xkind <> pxEnd) do begin
      addSon(e, parseStmt(p))
    end;
    if sonsLen(e) = 0 then
      addSon(e, newNodeP(nkNilLit, p));
    addSon(result, e);
  end;
  eat(p, pxEnd);
end;

function parseFor(var p: TPasParser): PNode;
var
  a, b, c: PNode;
begin
  result := newNodeP(nkForStmt, p);
  getTok(p);
  skipCom(p, result);
  expectIdent(p);
  addSon(result, createIdentNodeP(p.tok.ident, p));
  getTok(p);
  eat(p, pxAsgn);
  a := parseExpr(p);
  b := nil;
  c := newNodeP(nkCall, p);
  if p.tok.xkind = pxTo then begin
    addSon(c, newIdentNodeP(getIdent('countup'), p));
    getTok(p);
    b := parseExpr(p);
  end
  else if p.tok.xkind = pxDownto then begin
    addSon(c, newIdentNodeP(getIdent('countdown'), p));
    getTok(p);
    b := parseExpr(p);
  end
  else
    parMessage(p, errTokenExpected, PasTokKindToStr[pxTo]);
  addSon(c, a);
  addSon(c, b);

  eat(p, pxDo);
  skipCom(p, result);
  addSon(result, c);
  addSon(result, parseStmt(p))
end;

function parseParam(var p: TPasParser): PNode;
var
  a, v: PNode;
begin
  result := newNodeP(nkIdentDefs, p);
  v := nil;
  case p.tok.xkind of
    pxConst: getTok(p);
    pxVar:   begin getTok(p); v := newNodeP(nkVarTy, p); end;
    pxOut:   begin getTok(p); v := newNodeP(nkVarTy, p); end;
    else begin end
  end;
  while true do begin
    case p.tok.xkind of
      pxSymbol: a := createIdentNodeP(p.tok.ident, p);
      pxColon, pxEof, pxParRi, pxEquals: break;
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        exit;
      end;
    end;
    getTok(p); // skip identifier
    skipCom(p, a);
    if p.tok.xkind = pxComma then begin
      getTok(p); skipCom(p, a)
    end;
    addSon(result, a);
  end;
  if p.tok.xkind = pxColon then begin
    getTok(p); skipCom(p, result);
    if v <> nil then addSon(v, parseTypeDesc(p))
    else v := parseTypeDesc(p);
    addSon(result, v);
  end
  else begin
    addSon(result, nil);
    if p.tok.xkind <> pxEquals then
      parMessage(p, errColonOrEqualsExpected, pasTokToStr(p.tok))
  end;
  if p.tok.xkind = pxEquals then begin
    getTok(p); skipCom(p, result);
    addSon(result, parseExpr(p));
  end
  else
    addSon(result, nil);
end;

function parseParamList(var p: TPasParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkFormalParams, p);
  addSon(result, nil); // return type
  if p.tok.xkind = pxParLe then begin
    p.inParamList := true;
    getTok(p);
    skipCom(p, result);
    while true do begin
      case p.tok.xkind of
        pxSymbol, pxConst, pxVar, pxOut: a := parseParam(p);
        pxParRi: begin getTok(p); break end;
        else begin parMessage(p, errTokenExpected, ')'+''); break; end;
      end;
      skipCom(p, a);
      if p.tok.xkind = pxSemicolon then begin
        getTok(p); skipCom(p, a)
      end;
      addSon(result, a)
    end;
    p.inParamList := false
  end;
  if p.tok.xkind = pxColon then begin
    getTok(p);
    skipCom(p, result);
    result.sons[0] := parseTypeDesc(p)
  end
end;

function parseCallingConvention(var p: TPasParser): PNode;
begin
  result := nil;
  if p.tok.xkind = pxSymbol then begin
    case whichKeyword(p.tok.ident) of
      wStdcall, wCDecl, wSafeCall, wSysCall, wInline, wFastCall: begin
        result := newNodeP(nkPragma, p);
        addSon(result, newIdentNodeP(p.tok.ident, p));
        getTok(p);
        opt(p, pxSemicolon);
      end;
      wRegister: begin
        result := newNodeP(nkPragma, p);
        addSon(result, newIdentNodeP(getIdent('fastcall'), p));
        getTok(p);
        opt(p, pxSemicolon);
      end
      else begin end
    end
  end
end;

function parseRoutineSpecifiers(var p: TPasParser; out noBody: boolean): PNode;
var
  e: PNode;
begin
  result := parseCallingConvention(p);
  noBody := false;
  while p.tok.xkind = pxSymbol do begin
    case whichKeyword(p.tok.ident) of
      wAssembler, wOverload, wFar: begin
        getTok(p); opt(p, pxSemicolon);
      end;
      wForward: begin
        noBody := true;
        getTok(p); opt(p, pxSemicolon);
      end;
      wImportc: begin
        // This is a fake for platform module. There is no ``importc``
        // directive in Pascal.
        if result = nil then result := newNodeP(nkPragma, p);
        addSon(result, newIdentNodeP(getIdent('importc'), p));
        noBody := true;
        getTok(p); opt(p, pxSemicolon);
      end;
      wNoConv: begin
        // This is a fake for platform module. There is no ``noconv``
        // directive in Pascal.
        if result = nil then result := newNodeP(nkPragma, p);
        addSon(result, newIdentNodeP(getIdent('noconv'), p));
        noBody := true;
        getTok(p); opt(p, pxSemicolon);
      end;
      wVarargs: begin
        if result = nil then result := newNodeP(nkPragma, p);
        addSon(result, newIdentNodeP(getIdent('varargs'), p));
        getTok(p); opt(p, pxSemicolon);
      end;
      wExternal: begin
        if result = nil then result := newNodeP(nkPragma, p);
        getTok(p);
        noBody := true;
        e := newNodeP(nkExprColonExpr, p);
        addSon(e, newIdentNodeP(getIdent('dynlib'), p));
        addSon(e, parseExpr(p));
        addSon(result, e);
        opt(p, pxSemicolon);
        if (p.tok.xkind = pxSymbol)
        and (p.tok.ident.id = getIdent('name').id) then begin
          e := newNodeP(nkExprColonExpr, p);
          getTok(p);
          addSon(e, newIdentNodeP(getIdent('importc'), p));
          addSon(e, parseExpr(p));
          addSon(result, e);
        end
        else
          addSon(result, newIdentNodeP(getIdent('importc'), p));
        opt(p, pxSemicolon);
      end
      else begin
        e := parseCallingConvention(p);
        if e = nil then break;
        if result = nil then result := newNodeP(nkPragma, p);
        addSon(result, e.sons[0]);
      end;
    end
  end
end;

function parseRoutineType(var p: TPasParser): PNode;
begin
  result := newNodeP(nkProcTy, p);
  getTok(p); skipCom(p, result);
  addSon(result, parseParamList(p));
  opt(p, pxSemicolon);
  addSon(result, parseCallingConvention(p));
  skipCom(p, result);
end;

function parseEnum(var p: TPasParser): PNode;
var
  a, b: PNode;
begin
  result := newNodeP(nkEnumTy, p);
  getTok(p);
  skipCom(p, result);
  addSon(result, nil); // it does not inherit from any enumeration

  while true do begin
    case p.tok.xkind of
      pxEof, pxParRi: break;
      pxSymbol: a := newIdentNodeP(p.tok.ident, p);
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        break
      end;
    end;
    getTok(p); // skip identifier
    skipCom(p, a);
    if (p.tok.xkind = pxEquals) or (p.tok.xkind = pxAsgn) then begin
      getTok(p);
      skipCom(p, a);
      b := a;
      a := newNodeP(nkEnumFieldDef, p);
      addSon(a, b);
      addSon(a, parseExpr(p));
    end;
    if p.tok.xkind = pxComma then begin
      getTok(p); skipCom(p, a)
    end;
    addSon(result, a);
  end;
  eat(p, pxParRi)
end;

function identVis(var p: TPasParser): PNode; // identifier with visability
var
  a: PNode;
begin
  a := createIdentNodeP(p.tok.ident, p);
  if p.section = seInterface then begin
    result := newNodeP(nkPostfix, p);
    addSon(result, newIdentNodeP(getIdent('*'+''), p));
    addSon(result, a);
  end
  else
    result := a;
  getTok(p)
end;

type
  TSymbolParser = function (var p: TPasParser): PNode;

function rawIdent(var p: TPasParser): PNode;
begin
  result := createIdentNodeP(p.tok.ident, p);
  getTok(p);
end;

function parseIdentColonEquals(var p: TPasParser;
                               identParser: TSymbolParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkIdentDefs, p);
  while true do begin
    case p.tok.xkind of
      pxSymbol: a := identParser(p);
      pxColon, pxEof, pxParRi, pxEquals: break;
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        exit;
      end;
    end;
    skipCom(p, a);
    if p.tok.xkind = pxComma then begin
      getTok(p);
      skipCom(p, a)
    end;
    addSon(result, a);
  end;
  if p.tok.xkind = pxColon then begin
    getTok(p); skipCom(p, result);
    addSon(result, parseTypeDesc(p));
  end
  else begin
    addSon(result, nil);
    if p.tok.xkind <> pxEquals then
      parMessage(p, errColonOrEqualsExpected, pasTokToStr(p.tok))
  end;
  if p.tok.xkind = pxEquals then begin
    getTok(p); skipCom(p, result);
    addSon(result, parseExpr(p));
  end
  else
    addSon(result, nil);
  if p.tok.xkind = pxSemicolon then begin
    getTok(p); skipCom(p, result);
  end
end;

function parseRecordCase(var p: TPasParser): PNode;
var
  a, b, c: PNode;
begin
  result := newNodeP(nkRecCase, p);
  getTok(p);
  a := newNodeP(nkIdentDefs, p);
  addSon(a, rawIdent(p));
  eat(p, pxColon);
  addSon(a, parseTypeDesc(p));
  addSon(a, nil);
  addSon(result, a);
  eat(p, pxOf);
  skipCom(p, result);

  while true do begin
    case p.tok.xkind of
      pxEof, pxEnd: break;
      pxElse: begin
        b := newNodeP(nkElse, p);
        getTok(p);
      end;
      else begin
        b := newNodeP(nkOfBranch, p);
        while (p.tok.xkind <> pxEof) and (p.tok.xkind <> pxColon) do begin
          addSon(b, rangeExpr(p));
          opt(p, pxComma);
          skipcom(p, b);
        end;
        eat(p, pxColon);
      end
    end;
    skipCom(p, b);
    c := newNodeP(nkRecList, p);
    eat(p, pxParLe);
    while (p.tok.xkind <> pxParRi) and (p.tok.xkind <> pxEof) do begin
      addSon(c, parseIdentColonEquals(p, rawIdent));
      opt(p, pxSemicolon);
      skipCom(p, lastSon(c));
    end;
    eat(p, pxParRi);
    opt(p, pxSemicolon);
    if sonsLen(c) > 0 then skipCom(p, lastSon(c))
    else addSon(c, newNodeP(nkNilLit, p));
    addSon(b, c);
    addSon(result, b);
    if b.kind = nkElse then break;
  end
end;

function parseRecordPart(var p: TPasParser): PNode;
begin
  result := nil;
  while (p.tok.xkind <> pxEof) and (p.tok.xkind <> pxEnd) do begin
    if result = nil then result := newNodeP(nkRecList, p);
    case p.tok.xkind of
      pxSymbol: begin
        addSon(result, parseIdentColonEquals(p, rawIdent));
        opt(p, pxSemicolon);
        skipCom(p, lastSon(result));
      end;
      pxCase: begin
        addSon(result, parseRecordCase(p));
      end;
      pxComment: skipCom(p, lastSon(result));
      else begin
        parMessage(p, errIdentifierExpected, pasTokToStr(p.tok));
        break
      end
    end
  end
end;

procedure exSymbol(var n: PNode);
var
  a: PNode;
begin
  case n.kind of
    nkPostfix: begin end; // already an export marker
    nkPragmaExpr: exSymbol(n.sons[0]);
    nkIdent, nkAccQuoted: begin
      a := newNodeI(nkPostFix, n.info);
      addSon(a, newIdentNode(getIdent('*'+''), n.info));
      addSon(a, n);
      n := a
    end;
    else internalError(n.info, 'exSymbol(): ' + nodekindtostr[n.kind]);
  end
end;

procedure fixRecordDef(var n: PNode);
var
  i, len: int;
begin
  if n = nil then exit;
  case n.kind of
    nkRecCase: begin
      fixRecordDef(n.sons[0]);
      for i := 1 to sonsLen(n)-1 do begin
        len := sonsLen(n.sons[i]);
        fixRecordDef(n.sons[i].sons[len-1])
      end
    end;
    nkRecList, nkRecWhen, nkElse, nkOfBranch, nkElifBranch,
    nkObjectTy: begin
      for i := 0 to sonsLen(n)-1 do fixRecordDef(n.sons[i])
    end;
    nkIdentDefs: begin
      for i := 0 to sonsLen(n)-3 do exSymbol(n.sons[i])
    end;
    nkNilLit: begin end;
    //nkIdent: exSymbol(n);
    else internalError(n.info, 'fixRecordDef(): ' + nodekindtostr[n.kind]);
  end
end;

procedure addPragmaToIdent(var ident: PNode; pragma: PNode);
var
  e, pragmasNode: PNode;
begin
  if ident.kind <> nkPragmaExpr then begin
    pragmasNode := newNodeI(nkPragma, ident.info);
    e := newNodeI(nkPragmaExpr, ident.info);
    addSon(e, ident);
    addSon(e, pragmasNode);
    ident := e;
  end
  else begin
    pragmasNode := ident.sons[1];
    if pragmasNode.kind <> nkPragma then
      InternalError(ident.info, 'addPragmaToIdent');
  end;
  addSon(pragmasNode, pragma);
end;

procedure parseRecordBody(var p: TPasParser; result, definition: PNode);
var
  a: PNode;
begin
  skipCom(p, result);
  a := parseRecordPart(p);
  if result.kind <> nkTupleTy then fixRecordDef(a);
  addSon(result, a);
  eat(p, pxEnd);
  case p.tok.xkind of
    pxSymbol: begin
      if (p.tok.ident.id = getIdent('acyclic').id) then begin
        if definition <> nil then
          addPragmaToIdent(definition.sons[0], newIdentNodeP(p.tok.ident, p))
        else
          InternalError(result.info, 'anonymous record is not supported');
        getTok(p);
      end
      else
        InternalError(result.info, 'parseRecordBody');
    end;
    pxCommand: begin
      if definition <> nil then
        addPragmaToIdent(definition.sons[0], parseCommand(p))
      else
        InternalError(result.info, 'anonymous record is not supported');
    end;
    else begin end
  end;
  opt(p, pxSemicolon);
  skipCom(p, result);
end;

function parseRecordOrObject(var p: TPasParser; kind: TNodeKind;
                             definition: PNode): PNode;
var
  a: PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  addSon(result, nil);
  if p.tok.xkind = pxParLe then begin
    a := newNodeP(nkOfInherit, p);
    getTok(p);
    addSon(a, parseTypeDesc(p));
    addSon(result, a);
    eat(p, pxParRi);
  end
  else addSon(result, nil);
  parseRecordBody(p, result, definition);
end;

function parseTypeDesc(var p: TPasParser; definition: PNode=nil): PNode;
var
  oldcontext: TPasContext;
  a, r: PNode;
  i: int;
begin
  oldcontext := p.context;
  p.context := conTypeDesc;
  if p.tok.xkind = pxPacked then getTok(p);
  case p.tok.xkind of
    pxCommand: result := parseCommand(p, definition);
    pxProcedure, pxFunction: result := parseRoutineType(p);
    pxRecord: begin
      getTok(p);
      if p.tok.xkind = pxCommand then begin
        result := parseCommand(p);
        if result.kind <> nkTupleTy then
          InternalError(result.info, 'parseTypeDesc');
        parseRecordBody(p, result, definition);
        a := lastSon(result);
        // embed nkRecList directly into nkTupleTy
        for i := 0 to sonsLen(a)-1 do
          if i = 0 then result.sons[sonsLen(result)-1] := a.sons[0]
          else addSon(result, a.sons[i]);
      end
      else begin
        result := newNodeP(nkObjectTy, p);
        addSon(result, nil);
        addSon(result, nil);
        parseRecordBody(p, result, definition);
        if definition <> nil then
          addPragmaToIdent(definition.sons[0],
                           newIdentNodeP(getIdent('final'), p))
        else
          InternalError(result.info, 'anonymous record is not supported');
      end;
    end;
    pxObject: result := parseRecordOrObject(p, nkObjectTy, definition);
    pxParLe: result := parseEnum(p);
    pxArray: begin
      result := newNodeP(nkBracketExpr, p);
      getTok(p);
      if p.tok.xkind = pxBracketLe then begin
        addSon(result, newIdentNodeP(getIdent('array'), p));
        getTok(p);
        addSon(result, rangeExpr(p));
        eat(p, pxBracketRi);
      end
      else begin
        if p.inParamList then
          addSon(result, newIdentNodeP(getIdent('openarray'), p))
        else
          addSon(result, newIdentNodeP(getIdent('seq'), p));
      end;
      eat(p, pxOf);
      addSon(result, parseTypeDesc(p));
    end;
    pxSet: begin
      result := newNodeP(nkBracketExpr, p);
      getTok(p);
      eat(p, pxOf);
      addSon(result, newIdentNodeP(getIdent('set'), p));
      addSon(result, parseTypeDesc(p));
    end;
    pxHat: begin
      getTok(p);
      if p.tok.xkind = pxCommand then
        result := parseCommand(p)
      else if gCmd = cmdBoot then
        result := newNodeP(nkRefTy, p)
      else
        result := newNodeP(nkPtrTy, p);
      addSon(result, parseTypeDesc(p))
    end;
    pxType: begin
      getTok(p);
      result := parseTypeDesc(p);
    end;
    else begin
      a := primary(p);
      if p.tok.xkind = pxDotDot then begin
        result := newNodeP(nkBracketExpr, p);
        r := newNodeP(nkRange, p);
        addSon(result, newIdentNodeP(getIdent('range'), p));
        getTok(p);
        addSon(r, a);
        addSon(r, parseExpr(p));
        addSon(result, r);
      end
      else
        result := a
    end
  end;
  p.context := oldcontext;
end;

function parseTypeDef(var p: TPasParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkTypeDef, p);
  addSon(result, identVis(p));
  addSon(result, nil); // generic params
  if p.tok.xkind = pxEquals then begin
    getTok(p); skipCom(p, result);
    a := parseTypeDesc(p, result);
    addSon(result, a);
  end
  else
    addSon(result, nil);
  if p.tok.xkind = pxSemicolon then begin
    getTok(p); skipCom(p, result);
  end;
end;

function parseTypeSection(var p: TPasParser): PNode;
begin
  result := newNodeP(nkTypeSection, p);
  getTok(p);
  skipCom(p, result);
  while p.tok.xkind = pxSymbol do begin
    addSon(result, parseTypeDef(p))
  end
end;

function parseConstant(var p: TPasParser): PNode;
begin
  result := newNodeP(nkConstDef, p);
  addSon(result, identVis(p));
  if p.tok.xkind = pxColon then begin
    getTok(p); skipCom(p, result);
    addSon(result, parseTypeDesc(p));
  end
  else begin
    addSon(result, nil);
    if p.tok.xkind <> pxEquals then
      parMessage(p, errColonOrEqualsExpected, pasTokToStr(p.tok));
  end;
  if p.tok.xkind = pxEquals then begin
    getTok(p); skipCom(p, result);
    addSon(result, parseExpr(p));
  end
  else
    addSon(result, nil);
  if p.tok.xkind = pxSemicolon then begin
    getTok(p); skipCom(p, result);
  end;
end;

function parseConstSection(var p: TPasParser): PNode;
begin
  result := newNodeP(nkConstSection, p);
  getTok(p);
  skipCom(p, result);
  while p.tok.xkind = pxSymbol do begin
    addSon(result, parseConstant(p))
  end
end;

function parseVar(var p: TPasParser): PNode;
begin
  result := newNodeP(nkVarSection, p);
  getTok(p);
  skipCom(p, result);
  while p.tok.xkind = pxSymbol do begin
    addSon(result, parseIdentColonEquals(p, identVis));
  end;
  p.lastVarSection := result
end;

function parseRoutine(var p: TPasParser): PNode;
var
  a, stmts: PNode;
  noBody: boolean;
  i: int;
begin
  result := newNodeP(nkProcDef, p);
  getTok(p);
  skipCom(p, result);
  expectIdent(p);
  addSon(result, identVis(p));
  addSon(result, nil); // generic parameters
  addSon(result, parseParamList(p));
  opt(p, pxSemicolon);
  addSon(result, parseRoutineSpecifiers(p, noBody));
  if (p.section = seInterface) or noBody then
    addSon(result, nil)
  else begin
    stmts := newNodeP(nkStmtList, p);
    while true do begin
      case p.tok.xkind of
        pxVar:   addSon(stmts, parseVar(p));
        pxConst: addSon(stmts, parseConstSection(p));
        pxType:  addSon(stmts, parseTypeSection(p));
        pxComment: skipCom(p, result);
        pxBegin: break;
        else begin
          parMessage(p, errTokenExpected, 'begin');
          break
        end
      end
    end;
    a := parseStmt(p);
    for i := 0 to sonsLen(a)-1 do addSon(stmts, a.sons[i]);
    addSon(result, stmts);
  end
end;

function fixExit(var p: TPasParser; n: PNode): boolean;
var
  len: int;
  a: PNode;
begin
  result := false;
  if (p.tok.ident.id = getIdent('exit').id) then begin
    len := sonsLen(n);
    if (len <= 0) then exit;
    a := n.sons[len-1];
    if (a.kind = nkAsgn)
    and (a.sons[0].kind = nkIdent)
    and (a.sons[0].ident.id = getIdent('result').id) then begin
      delSon(a, 0);
      a.kind := nkReturnStmt;
      result := true;
      getTok(p); opt(p, pxSemicolon);
      skipCom(p, a);
    end
  end
end;

procedure fixVarSection(var p: TPasParser; counter: PNode);
var
  i, j: int;
  v: PNode;
begin
  if p.lastVarSection = nil then exit;
  assert(counter.kind = nkIdent);
  for i := 0 to sonsLen(p.lastVarSection)-1 do begin
    v := p.lastVarSection.sons[i];
    for j := 0 to sonsLen(v)-3 do begin
      if v.sons[j].ident.id = counter.ident.id then begin
        delSon(v, j);
        if sonsLen(v) <= 2 then // : type = int remains --> delete it
          delSon(p.lastVarSection, i);
        exit
      end
    end
  end
end;

procedure parseBegin(var p: TPasParser; result: PNode);
begin
  getTok(p);
  while true do begin
    case p.tok.xkind of
      pxComment: addSon(result, parseStmt(p));
      pxSymbol: begin
        if not fixExit(p, result) then addSon(result, parseStmt(p))
      end;
      pxEnd: begin getTok(p); break end;
      pxSemicolon: begin getTok(p); end;
      pxEof: parMessage(p, errExprExpected);
      else addSonIfNotNil(result, parseStmt(p));
    end
  end;
  if sonsLen(result) = 0 then
    addSon(result, newNodeP(nkNilLit, p));
end;

function parseStmt(var p: TPasParser): PNode;
var
  oldcontext: TPasContext;
begin
  oldcontext := p.context;
  p.context := conStmt;
  result := nil;
  case p.tok.xkind of
    pxBegin:    begin
      result := newNodeP(nkStmtList, p);
      parseBegin(p, result);
    end;
    pxCommand:  result := parseCommand(p);
    pxCurlyDirLe, pxStarDirLe: begin
      if isHandledDirective(p) then
        result := parseDirective(p);
    end;
    pxIf:       result := parseIf(p);
    pxWhile:    result := parseWhile(p);
    pxRepeat:   result := parseRepeat(p);
    pxCase:     result := parseCase(p);
    pxTry:      result := parseTry(p);
    pxProcedure, pxFunction:  result := parseRoutine(p);
    pxType:     result := parseTypeSection(p);
    pxConst:    result := parseConstSection(p);
    pxVar:      result := parseVar(p);
    pxFor:      begin
      result := parseFor(p);
      fixVarSection(p, result.sons[0]);
    end;
    pxRaise:    result := parseRaise(p);
    pxUses:     result := parseUsesStmt(p);
    pxProgram, pxUnit, pxLibrary: begin
      // skip the pointless header
      while not (p.tok.xkind in [pxSemicolon, pxEof]) do getTok(p);
      getTok(p);
    end;
    pxInitialization: begin
      getTok(p); // just skip the token
    end;
    pxImplementation: begin
      p.section := seImplementation;
      result := newNodeP(nkCommentStmt, p);
      result.comment := '# implementation';
      getTok(p);
    end;
    pxInterface: begin
      p.section := seInterface;
      getTok(p);
    end;
    pxComment: begin
      result := newNodeP(nkCommentStmt, p);
      skipCom(p, result);
    end;
    pxSemicolon: getTok(p);
    pxSymbol: begin
      if p.tok.ident.id = getIdent('break').id then begin
        result := newNodeP(nkBreakStmt, p);
        getTok(p); skipCom(p, result);
        addSon(result, nil);
      end
      else if p.tok.ident.id = getIdent('continue').id then begin
        result := newNodeP(nkContinueStmt, p);
        getTok(p); skipCom(p, result);
        addSon(result, nil);
      end
      else if p.tok.ident.id = getIdent('exit').id then begin
        result := newNodeP(nkReturnStmt, p);
        getTok(p); skipCom(p, result);
        addSon(result, nil);
      end
      else result := parseExprStmt(p)
    end;
    pxDot: getTok(p); // BUGFIX for ``end.`` in main program
    else result := parseExprStmt(p)
  end;
  opt(p, pxSemicolon);
  if result <> nil then skipCom(p, result);
  p.context := oldcontext;
end;

function parseUnit(var p: TPasParser): PNode;
begin
  result := newNodeP(nkStmtList, p);
  getTok(p); // read first token
  while true do begin
    case p.tok.xkind of
      pxEof, pxEnd: break;
      pxBegin: parseBegin(p, result);
      pxCurlyDirLe, pxStarDirLe: begin
        if isHandledDirective(p) then
          addSon(result, parseDirective(p))
        else
          parMessage(p, errXNotAllowedHere, p.tok.ident.s)
      end
      else addSon(result, parseStmt(p))
    end;
  end;
  opt(p, pxEnd);
  opt(p, pxDot);
  if p.tok.xkind <> pxEof then
    addSon(result, parseStmt(p)); // comments after final 'end.'
end;

end.
