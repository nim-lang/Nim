//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit pbraces;

{$include config.inc}

interface

uses
  nsystem, llstream, scanner, idents, strutils, ast, msgs, pnimsyn;

function ParseAll(var p: TParser): PNode;

function parseTopLevelStmt(var p: TParser): PNode;
// implements an iterator. Returns the next top-level statement or nil if end
// of stream.

implementation

// ------------------- Expression parsing ------------------------------------

function parseExpr(var p: TParser): PNode; forward;
function parseStmt(var p: TParser): PNode; forward;

function parseTypeDesc(var p: TParser): PNode; forward;
function parseParamList(var p: TParser): PNode; forward;

function optExpr(var p: TParser): PNode; // [expr]
begin
  if (p.tok.tokType <> tkComma) and (p.tok.tokType <> tkBracketRi)
  and (p.tok.tokType <> tkDotDot) then
    result := parseExpr(p)
  else
    result := nil;
end;

function dotdotExpr(var p: TParser; first: PNode = nil): PNode;
begin
  result := newNodeP(nkRange, p);
  addSon(result, first);
  getTok(p);
  optInd(p, result);
  addSon(result, optExpr(p));
end;

function indexExpr(var p: TParser): PNode;
// indexExpr ::= '..' [expr] | expr ['=' expr | '..' expr]
var
  a, b: PNode;
begin
  if p.tok.tokType = tkDotDot then
    result := dotdotExpr(p)
  else begin
    a := parseExpr(p);
    case p.tok.tokType of
      tkEquals: begin
        result := newNodeP(nkExprEqExpr, p);
        addSon(result, a);
        getTok(p);
        if p.tok.tokType = tkDotDot then
          addSon(result, dotdotExpr(p))
        else begin
          b := parseExpr(p);
          if p.tok.tokType = tkDotDot then b := dotdotExpr(p, b);
          addSon(result, b);
        end
      end;
      tkDotDot: result := dotdotExpr(p, a);
      else result := a
    end
  end
end;

function indexExprList(var p: TParser; first: PNode): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkBracketExpr, p);
  addSon(result, first);
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType <> tkBracketRi) and (p.tok.tokType <> tkEof)
  and (p.tok.tokType <> tkSad) do begin
    a := indexExpr(p);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  optSad(p);
  eat(p, tkBracketRi);
end;

function exprColonEqExpr(var p: TParser; kind: TNodeKind;
                         tok: TTokType): PNode;
var
  a: PNode;
begin
  a := parseExpr(p);
  if p.tok.tokType = tok then begin
    result := newNodeP(kind, p);
    getTok(p);
    //optInd(p, result);
    addSon(result, a);
    addSon(result, parseExpr(p));
  end
  else
    result := a
end;

procedure exprListAux(var p: TParser; elemKind: TNodeKind;
                      endTok, sepTok: TTokType; result: PNode);
var
  a: PNode;
begin
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType <> endTok) and (p.tok.tokType <> tkEof) do begin
    a := exprColonEqExpr(p, elemKind, sepTok);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  eat(p, endTok);
end;

function qualifiedIdent(var p: TParser): PNode;
var
  a: PNode;
begin
  result := parseSymbol(p);
  if p.tok.tokType = tkDot then begin
    getTok(p);
    optInd(p, result);
    a := result;
    result := newNodeI(nkDotExpr, a.info);
    addSon(result, a);
    addSon(result, parseSymbol(p));
  end;
end;

procedure qualifiedIdentListAux(var p: TParser; endTok: TTokType; result: PNode);
var
  a: PNode;
begin
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType <> endTok) and (p.tok.tokType <> tkEof) do begin
    a := qualifiedIdent(p);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  eat(p, endTok);
end;

procedure exprColonEqExprListAux(var p: TParser; elemKind: TNodeKind;
                                 endTok, sepTok: TTokType; result: PNode);
var
  a: PNode;
begin
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType <> endTok) and (p.tok.tokType <> tkEof)
  and (p.tok.tokType <> tkSad) do begin
    a := exprColonEqExpr(p, elemKind, sepTok);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  optSad(p);
  eat(p, endTok);
end;

function exprColonEqExprList(var p: TParser; kind, elemKind: TNodeKind;
                             endTok, sepTok: TTokType): PNode;
begin
  result := newNodeP(kind, p);
  exprColonEqExprListAux(p, elemKind, endTok, sepTok, result);
end;

function parseCast(var p: TParser): PNode;
begin
  result := newNodeP(nkCast, p);
  getTok(p);
  eat(p, tkBracketLe);
  optInd(p, result);
  addSon(result, parseTypeDesc(p));
  optSad(p);
  eat(p, tkBracketRi);
  eat(p, tkParLe);
  optInd(p, result);
  addSon(result, parseExpr(p));
  optSad(p);
  eat(p, tkParRi);
end;

function parseAddr(var p: TParser): PNode;
begin
  result := newNodeP(nkAddr, p);
  getTok(p);
  eat(p, tkParLe);
  optInd(p, result);
  addSon(result, parseExpr(p));
  optSad(p);
  eat(p, tkParRi);
end;

function identOrLiteral(var p: TParser): PNode;
begin
  case p.tok.tokType of
    tkSymbol: begin
      result := newIdentNodeP(p.tok.ident, p);
      getTok(p)
    end;
    tkAccent: result := accExpr(p);
    // literals
    tkIntLit: begin
      result := newIntNodeP(nkIntLit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkInt8Lit: begin
      result := newIntNodeP(nkInt8Lit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkInt16Lit: begin
      result := newIntNodeP(nkInt16Lit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkInt32Lit: begin
      result := newIntNodeP(nkInt32Lit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkInt64Lit: begin
      result := newIntNodeP(nkInt64Lit, p.tok.iNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkFloatLit: begin
      result := newFloatNodeP(nkFloatLit, p.tok.fNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkFloat32Lit: begin
      result := newFloatNodeP(nkFloat32Lit, p.tok.fNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkFloat64Lit: begin
      result := newFloatNodeP(nkFloat64Lit, p.tok.fNumber, p);
      setBaseFlags(result, p.tok.base);
      getTok(p);
    end;
    tkStrLit: begin
      result := newStrNodeP(nkStrLit, p.tok.literal, p);
      getTok(p);
    end;
    tkRStrLit: begin
      result := newStrNodeP(nkRStrLit, p.tok.literal, p);
      getTok(p);
    end;
    tkTripleStrLit: begin
      result := newStrNodeP(nkTripleStrLit, p.tok.literal, p);
      getTok(p);
    end;
    tkCallRStrLit: begin
      result := newNodeP(nkCallStrLit, p);
      addSon(result, newIdentNodeP(p.tok.ident, p));
      addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p));
      getTok(p);
    end;
    tkCallTripleStrLit: begin
      result := newNodeP(nkCallStrLit, p);
      addSon(result, newIdentNodeP(p.tok.ident, p));
      addSon(result, newStrNodeP(nkTripleStrLit, p.tok.literal, p));
      getTok(p);
    end;
    tkCharLit: begin
      result := newIntNodeP(nkCharLit, ord(p.tok.literal[strStart]), p);
      getTok(p);
    end;
    tkNil: begin
      result := newNodeP(nkNilLit, p);
      getTok(p);
    end;
    tkParLe: begin // () constructor
      result := exprColonEqExprList(p, nkPar, nkExprColonExpr, tkParRi,
                                    tkColon);
    end;
    tkCurlyLe: begin // {} constructor
      result := exprColonEqExprList(p, nkCurly, nkRange, tkCurlyRi, tkDotDot);
    end;
    tkBracketLe: begin // [] constructor
      result := exprColonEqExprList(p, nkBracket, nkExprColonExpr, tkBracketRi,
                                    tkColon);
    end;
    tkCast: result := parseCast(p);
    tkAddr: result := parseAddr(p);
    else begin
      parMessage(p, errExprExpected, tokToStr(p.tok));
      getTok(p); // we must consume a token here to prevend endless loops!
      result := nil
    end
  end
end;

function primary(var p: TParser): PNode;
var
  a: PNode;
begin
  // prefix operator?
  if (p.tok.tokType = tkNot) or (p.tok.tokType = tkOpr) then begin
    result := newNodeP(nkPrefix, p);
    a := newIdentNodeP(p.tok.ident, p);
    addSon(result, a);
    getTok(p);
    optInd(p, a);
    addSon(result, primary(p));
    exit
  end
  else if p.tok.tokType = tkBind then begin
    result := newNodeP(nkBind, p);
    getTok(p);
    optInd(p, result);
    addSon(result, primary(p));
    exit
  end;
  result := identOrLiteral(p);
  while true do begin
    case p.tok.tokType of
      tkParLe: begin
        a := result;
        result := newNodeP(nkCall, p);
        addSon(result, a);
        exprColonEqExprListAux(p, nkExprEqExpr, tkParRi, tkEquals, result);
      end;
      tkDot: begin
        a := result;
        result := newNodeP(nkDotExpr, p);
        addSon(result, a);
        getTok(p); // skip '.'
        optInd(p, result);
        addSon(result, parseSymbol(p));
      end;
      tkHat: begin
        a := result;
        result := newNodeP(nkDerefExpr, p);
        addSon(result, a);
        getTok(p);
      end;
      tkBracketLe: result := indexExprList(p, result);
      else break
    end
  end
end;

function lowestExprAux(var p: TParser; out v: PNode; limit: int): PToken;
var
  op, nextop: PToken;
  opPred: int;
  v2, node, opNode: PNode;
begin
  v := primary(p);
  // expand while operators have priorities higher than 'limit'
  op := p.tok;
  opPred := getPrecedence(p.tok);
  while (opPred > limit) do begin
    node := newNodeP(nkInfix, p);
    opNode := newIdentNodeP(op.ident, p);
    // skip operator:
    getTok(p);
    optInd(p, opNode);

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

function lowestExpr(var p: TParser): PNode;
begin
{@discard} lowestExprAux(p, result, -1);
end;

function parseIfExpr(var p: TParser): PNode;
// if (expr) expr else expr
var
  branch: PNode;
begin
  result := newNodeP(nkIfExpr, p);
  while true do begin
    getTok(p); // skip `if`, `elif`
    branch := newNodeP(nkElifExpr, p);
    eat(p, tkParLe);
    addSon(branch, parseExpr(p));
    eat(p, tkParRi);
    addSon(branch, parseExpr(p));
    addSon(result, branch);
    if p.tok.tokType <> tkElif then break
  end;
  branch := newNodeP(nkElseExpr, p);
  eat(p, tkElse);
  addSon(branch, parseExpr(p));
  addSon(result, branch);
end;

function parsePragma(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkPragma, p);
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType <> tkCurlyDotRi) and (p.tok.tokType <> tkCurlyRi)
  and (p.tok.tokType <> tkEof) and (p.tok.tokType <> tkSad) do begin
    a := exprColonEqExpr(p, nkExprColonExpr, tkColon);
    addSon(result, a);
    if p.tok.tokType = tkComma then begin
      getTok(p);
      optInd(p, a)
    end
  end;
  optSad(p);
  if (p.tok.tokType = tkCurlyDotRi) or (p.tok.tokType = tkCurlyRi) then
    getTok(p)
  else
    parMessage(p, errTokenExpected, '.}');
end;

function identVis(var p: TParser): PNode; // identifier with visability
var
  a: PNode;
begin
  a := parseSymbol(p);
  if p.tok.tokType = tkOpr then begin
    result := newNodeP(nkPostfix, p);
    addSon(result, newIdentNodeP(p.tok.ident, p));
    addSon(result, a);
    getTok(p);
  end
  else
    result := a;
end;

function identWithPragma(var p: TParser): PNode;
var
  a: PNode;
begin
  a := identVis(p);
  if p.tok.tokType = tkCurlyDotLe then begin
    result := newNodeP(nkPragmaExpr, p);
    addSon(result, a);
    addSon(result, parsePragma(p));
  end
  else
    result := a
end;

type
  TDeclaredIdentFlag = (
    withPragma,                // identifier may have pragma
    withBothOptional           // both ':' and '=' parts are optional
  );
  TDeclaredIdentFlags = set of TDeclaredIdentFlag;

function parseIdentColonEquals(var p: TParser;
                               flags: TDeclaredIdentFlags): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkIdentDefs, p);
  while true do begin
    case p.tok.tokType of
      tkSymbol, tkAccent: begin
        if withPragma in flags then
          a := identWithPragma(p)
        else
          a := parseSymbol(p);
        if a = nil then exit;
      end;
      else break;
    end;
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  if p.tok.tokType = tkColon then begin
    getTok(p); optInd(p, result);
    addSon(result, parseTypeDesc(p));
  end
  else begin
    addSon(result, nil);
    if (p.tok.tokType <> tkEquals) and not (withBothOptional in flags) then
      parMessage(p, errColonOrEqualsExpected, tokToStr(p.tok))
  end;
  if p.tok.tokType = tkEquals then begin
    getTok(p); optInd(p, result);
    addSon(result, parseExpr(p));
  end
  else
    addSon(result, nil);
end;

function parseTuple(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkTupleTy, p);
  getTok(p);
  eat(p, tkBracketLe);
  optInd(p, result);
  while (p.tok.tokType = tkSymbol) or (p.tok.tokType = tkAccent) do begin
    a := parseIdentColonEquals(p, {@set}[]);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  optSad(p);
  eat(p, tkBracketRi);
end;

function parseParamList(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkFormalParams, p);
  addSon(result, nil); // return type
  if p.tok.tokType = tkParLe then begin
    getTok(p);
    optInd(p, result);
    while true do begin
      case p.tok.tokType of
        tkSymbol, tkAccent: a := parseIdentColonEquals(p, {@set}[]);
        tkParRi: break;
        else begin parMessage(p, errTokenExpected, ')'+''); break; end;
      end;
      addSon(result, a);
      if p.tok.tokType <> tkComma then break;
      getTok(p);
      optInd(p, a)
    end;
    optSad(p);
    eat(p, tkParRi);
  end;
  if p.tok.tokType = tkColon then begin
    getTok(p);
    optInd(p, result);
    result.sons[0] := parseTypeDesc(p)
  end
end;

function parseProcExpr(var p: TParser; isExpr: bool): PNode;
// either a proc type or a anonymous proc
var
  pragmas, params: PNode;
  info: TLineInfo;
begin
  info := parLineInfo(p);
  getTok(p);
  params := parseParamList(p);
  if p.tok.tokType = tkCurlyDotLe then pragmas := parsePragma(p)
  else pragmas := nil;
  if (p.tok.tokType = tkCurlyLe) and isExpr then begin
    result := newNodeI(nkLambda, info);
    addSon(result, nil); // no name part
    addSon(result, nil); // no generic parameters
    addSon(result, params);
    addSon(result, pragmas);
    //getTok(p); skipComment(p, result);
    addSon(result, parseStmt(p));
  end
  else begin
    result := newNodeI(nkProcTy, info);
    addSon(result, params);
    addSon(result, pragmas);
  end
end;

function parseTypeDescKAux(var p: TParser; kind: TNodeKind): PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  optInd(p, result);
  addSon(result, parseTypeDesc(p));
end;

function parseExpr(var p: TParser): PNode;
(*
expr ::= lowestExpr
     | 'if' expr ':' expr ('elif' expr ':' expr)* 'else' ':' expr
     | 'var' expr
     | 'ref' expr
     | 'ptr' expr
     | 'type' expr
     | 'tuple' tupleDesc
     | 'proc' paramList [pragma] ['=' stmt] 
*)
begin
  case p.tok.toktype of
    tkVar:   result := parseTypeDescKAux(p, nkVarTy);
    tkRef:   result := parseTypeDescKAux(p, nkRefTy);
    tkPtr:   result := parseTypeDescKAux(p, nkPtrTy);
    tkType:  result := parseTypeDescKAux(p, nkTypeOfExpr);
    tkTuple: result := parseTuple(p);
    tkProc:  result := parseProcExpr(p, true);
    tkIf:    result := parseIfExpr(p);
    else     result := lowestExpr(p);
  end
end;

function parseTypeDesc(var p: TParser): PNode;
begin
  if p.tok.toktype = tkProc then result := parseProcExpr(p, false)
  else result := parseExpr(p);
end;

// ---------------------- statement parser ------------------------------------
function isExprStart(const p: TParser): bool;
begin
  case p.tok.tokType of
    tkSymbol, tkAccent, tkOpr, tkNot, tkNil, tkCast, tkIf, tkProc, tkBind,
    tkParLe, tkBracketLe, tkCurlyLe, tkIntLit..tkCharLit,
    tkVar, tkRef, tkPtr, tkTuple, tkType: result := true;
    else result := false;
  end;
end;

function parseExprStmt(var p: TParser): PNode;
var
  a, b, e: PNode;
begin
  a := lowestExpr(p);
  if p.tok.tokType = tkEquals then begin
    getTok(p);
    optInd(p, result);
    b := parseExpr(p);
    result := newNodeI(nkAsgn, a.info);
    addSon(result, a);
    addSon(result, b);
  end
  else begin
    result := newNodeP(nkCommand, p);
    result.info := a.info;
    addSon(result, a);
    while true do begin
      if not isExprStart(p) then break;
      e := parseExpr(p);
      addSon(result, e);
      if p.tok.tokType <> tkComma then break;
      getTok(p);
      optInd(p, a);
    end;
    if sonsLen(result) <= 1 then result := a
    else a := result;
    if p.tok.tokType = tkCurlyLe then begin // macro statement
      result := newNodeP(nkMacroStmt, p);
      result.info := a.info;
      addSon(result, a);
      getTok(p);
      skipComment(p, result);
      if (p.tok.tokType = tkInd)
           or not (p.tok.TokType in [tkOf, tkElif, tkElse, tkExcept]) then
        addSon(result, parseStmt(p));
      while true do begin
        if p.tok.tokType = tkSad then getTok(p);
        case p.tok.tokType of
          tkOf: begin
            b := newNodeP(nkOfBranch, p);
            exprListAux(p, nkRange, tkCurlyLe, tkDotDot, b);
          end;
          tkElif: begin
            b := newNodeP(nkElifBranch, p);
            getTok(p);
            optInd(p, b);
            addSon(b, parseExpr(p));
            eat(p, tkCurlyLe);
          end;
          tkExcept: begin
            b := newNodeP(nkExceptBranch, p);
            qualifiedIdentListAux(p, tkCurlyLe, b);
            skipComment(p, b);
          end;
          tkElse: begin
            b := newNodeP(nkElse, p);
            getTok(p);
            eat(p, tkCurlyLe);
          end;
          else break;
        end;
        addSon(b, parseStmt(p));
        eat(p, tkCurlyRi);
        addSon(result, b);
        if b.kind = nkElse then break;
      end;
      eat(p, tkCurlyRi);
    end
  end
end;

function parseImportOrIncludeStmt(var p: TParser; kind: TNodeKind): PNode;
var
  a: PNode;
begin
  result := newNodeP(kind, p);
  getTok(p); // skip `import` or `include`
  optInd(p, result);
  while true do begin
    case p.tok.tokType of
      tkEof, tkSad, tkDed: break;
      tkSymbol, tkAccent: a := parseSymbol(p);
      tkRStrLit: begin
        a := newStrNodeP(nkRStrLit, p.tok.literal, p);
        getTok(p)
      end;
      tkStrLit: begin
        a := newStrNodeP(nkStrLit, p.tok.literal, p);
        getTok(p);
      end;
      tkTripleStrLit: begin
        a := newStrNodeP(nkTripleStrLit, p.tok.literal, p);
        getTok(p)
      end;
      else begin
        parMessage(p, errIdentifierExpected, tokToStr(p.tok));
        break
      end
    end;
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
end;

function parseFromStmt(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkFromStmt, p);
  getTok(p); // skip `from`
  optInd(p, result);
  case p.tok.tokType of
    tkSymbol, tkAccent: a := parseSymbol(p);
    tkRStrLit:  begin
      a := newStrNodeP(nkRStrLit, p.tok.literal, p);
      getTok(p)
    end;
    tkStrLit: begin
      a := newStrNodeP(nkStrLit, p.tok.literal, p);
      getTok(p);
    end;
    tkTripleStrLit: begin
      a := newStrNodeP(nkTripleStrLit, p.tok.literal, p);
      getTok(p)
    end;
    else begin
      parMessage(p, errIdentifierExpected, tokToStr(p.tok)); exit
    end
  end;
  addSon(result, a);
  //optInd(p, a);
  eat(p, tkImport);
  optInd(p, result);
  while true do begin
    case p.tok.tokType of
      tkEof, tkSad, tkDed: break;
      tkSymbol, tkAccent: a := parseSymbol(p);
      else begin
        parMessage(p, errIdentifierExpected, tokToStr(p.tok));
        break
      end;
    end;
    //optInd(p, a);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
end;

function parseReturnOrRaise(var p: TParser; kind: TNodeKind): PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  optInd(p, result);
  case p.tok.tokType of
    tkEof, tkSad, tkDed: addSon(result, nil);
    else addSon(result, parseExpr(p));
  end;
end;

function parseYieldOrDiscard(var p: TParser; kind: TNodeKind): PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  optInd(p, result);
  addSon(result, parseExpr(p));
end;

function parseBreakOrContinue(var p: TParser; kind: TNodeKind): PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  optInd(p, result);
  case p.tok.tokType of
    tkEof, tkSad, tkDed: addSon(result, nil);
    else addSon(result, parseSymbol(p));
  end;
end;

function parseIfOrWhen(var p: TParser; kind: TNodeKind): PNode;
var
  branch: PNode;
begin
  result := newNodeP(kind, p);
  while true do begin
    getTok(p); // skip `if`, `when`, `elif`
    branch := newNodeP(nkElifBranch, p);
    optInd(p, branch);
    eat(p, tkParLe);
    addSon(branch, parseExpr(p));
    eat(p, tkParRi);
    skipComment(p, branch);
    addSon(branch, parseStmt(p));
    skipComment(p, branch);
    addSon(result, branch);
    if p.tok.tokType <> tkElif then break
  end;
  if p.tok.tokType = tkElse then begin
    branch := newNodeP(nkElse, p);
    eat(p, tkElse);
    skipComment(p, branch);
    addSon(branch, parseStmt(p));
    addSon(result, branch);
  end
end;

function parseWhile(var p: TParser): PNode;
begin
  result := newNodeP(nkWhileStmt, p);
  getTok(p);
  optInd(p, result);
  eat(p, tkParLe);
  addSon(result, parseExpr(p));
  eat(p, tkParRi);
  skipComment(p, result);
  addSon(result, parseStmt(p));
end;

function parseCase(var p: TParser): PNode;
var
  b: PNode;
  inElif: bool;
begin
  result := newNodeP(nkCaseStmt, p);
  getTok(p);
  eat(p, tkParLe);
  addSon(result, parseExpr(p));
  eat(p, tkParRi);
  skipComment(p, result);
  inElif := false;
  while true do begin
    if p.tok.tokType = tkSad then getTok(p);
    case p.tok.tokType of
      tkOf: begin
        if inElif then break;
        b := newNodeP(nkOfBranch, p);
        exprListAux(p, nkRange, tkColon, tkDotDot, b);
      end;
      tkElif: begin
        inElif := true;
        b := newNodeP(nkElifBranch, p);
        getTok(p);
        optInd(p, b);
        addSon(b, parseExpr(p));
        eat(p, tkColon);
      end;
      tkElse: begin
        b := newNodeP(nkElse, p);
        getTok(p);
        eat(p, tkColon);
      end;
      else break;
    end;
    skipComment(p, b);
    addSon(b, parseStmt(p));
    addSon(result, b);
    if b.kind = nkElse then break;
  end
end;

function parseTry(var p: TParser): PNode;
var
  b: PNode;
begin
  result := newNodeP(nkTryStmt, p);
  getTok(p);
  eat(p, tkColon);
  skipComment(p, result);
  addSon(result, parseStmt(p));
  b := nil;
  while true do begin
    if p.tok.tokType = tkSad then getTok(p);
    case p.tok.tokType of
      tkExcept: begin
        b := newNodeP(nkExceptBranch, p);
        qualifiedIdentListAux(p, tkColon, b);
      end;
      tkFinally: begin
        b := newNodeP(nkFinally, p);
        getTok(p);
        eat(p, tkColon);
      end;
      else break;
    end;
    skipComment(p, b);
    addSon(b, parseStmt(p));
    addSon(result, b);
    if b.kind = nkFinally then break;
  end;
  if b = nil then parMessage(p, errTokenExpected, 'except');
end;

function parseFor(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkForStmt, p);
  getTok(p);
  optInd(p, result);
  a := parseSymbol(p);
  addSon(result, a);
  while p.tok.tokType = tkComma do begin
    getTok(p);
    optInd(p, a);
    a := parseSymbol(p);
    addSon(result, a);    
  end;
  eat(p, tkIn);
  addSon(result, exprColonEqExpr(p, nkRange, tkDotDot));
  eat(p, tkColon);
  skipComment(p, result);
  addSon(result, parseStmt(p))
end;

function parseBlock(var p: TParser): PNode;
begin
  result := newNodeP(nkBlockStmt, p);
  getTok(p);
  optInd(p, result);
  case p.tok.tokType of
    tkEof, tkSad, tkDed, tkColon: addSon(result, nil);
    else addSon(result, parseSymbol(p));
  end;
  eat(p, tkColon);
  skipComment(p, result);
  addSon(result, parseStmt(p));
end;

function parseAsm(var p: TParser): PNode;
begin
  result := newNodeP(nkAsmStmt, p);
  getTok(p);
  optInd(p, result);
  if p.tok.tokType = tkCurlyDotLe then addSon(result, parsePragma(p))
  else addSon(result, nil);
  case p.tok.tokType of
    tkStrLit: addSon(result, newStrNodeP(nkStrLit, p.tok.literal, p));
    tkRStrLit: addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p));
    tkTripleStrLit:
      addSon(result, newStrNodeP(nkTripleStrLit, p.tok.literal, p));
    else begin
      parMessage(p, errStringLiteralExpected);
      addSon(result, nil); exit
    end;
  end;
  getTok(p);
end;

function parseGenericParamList(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkGenericParams, p);
  getTok(p);
  optInd(p, result);
  while (p.tok.tokType = tkSymbol) or (p.tok.tokType = tkAccent) do begin
    a := parseIdentColonEquals(p, {@set}[withBothOptional]);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  optSad(p);
  eat(p, tkBracketRi);
end;

function parseRoutine(var p: TParser; kind: TNodeKind): PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  optInd(p, result);
  addSon(result, identVis(p));
  if p.tok.tokType = tkBracketLe then addSon(result, parseGenericParamList(p))
  else addSon(result, nil);
  addSon(result, parseParamList(p));
  if p.tok.tokType = tkCurlyDotLe then addSon(result, parsePragma(p))
  else addSon(result, nil);
  if p.tok.tokType = tkEquals then begin
    getTok(p); skipComment(p, result);
    addSon(result, parseStmt(p));
  end
  else
    addSon(result, nil);
  indAndComment(p, result); // XXX: document this in the grammar!
end;

function newCommentStmt(var p: TParser): PNode;
begin
  result := newNodeP(nkCommentStmt, p);
  result.info.line := result.info.line - int16(1);
end;

type
  TDefParser = function (var p: TParser): PNode;

function parseSection(var p: TParser; kind: TNodeKind;
                      defparser: TDefParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(kind, p);
  getTok(p);
  skipComment(p, result);
  case p.tok.tokType of
    tkInd: begin
      pushInd(p.lex^, p.tok.indent);
      getTok(p); skipComment(p, result);
      while true do begin
        case p.tok.tokType of
          tkSad: getTok(p);
          tkSymbol, tkAccent: begin
            a := defparser(p);
            skipComment(p, a);
            addSon(result, a);
          end;
          tkDed: begin getTok(p); break end;
          tkEof: break; // BUGFIX
          tkComment: begin
            a := newCommentStmt(p);
            skipComment(p, a);
            addSon(result, a);
          end;
          else begin
            parMessage(p, errIdentifierExpected, tokToStr(p.tok));
            break
          end
        end
      end;
      popInd(p.lex^);
    end;
    tkSymbol, tkAccent, tkParLe: begin
      // tkParLe is allowed for ``var (x, y) = ...`` tuple parsing
      addSon(result, defparser(p));
    end
    else parMessage(p, errIdentifierExpected, tokToStr(p.tok));
  end
end;

function parseConstant(var p: TParser): PNode;
begin
  result := newNodeP(nkConstDef, p);
  addSon(result, identWithPragma(p));
  if p.tok.tokType = tkColon then begin
    getTok(p); optInd(p, result);
    addSon(result, parseTypeDesc(p));
  end
  else
    addSon(result, nil);
  eat(p, tkEquals);
  optInd(p, result);
  addSon(result, parseExpr(p));
  indAndComment(p, result); // XXX: special extension!
end;

function parseConstSection(var p: TParser): PNode;
begin
  result := newNodeP(nkConstSection, p);
  getTok(p);
  skipComment(p, result);
  if p.tok.tokType = tkCurlyLe then begin
    getTok(p);
    skipComment(p, result);
    while (p.tok.tokType <> tkCurlyRi) and (p.tok.tokType <> tkEof) do begin
      addSon(result, parseConstant(p)) 
    end;
    eat(p, tkCurlyRi);
  end
  else 
    addSon(result, parseConstant(p));
end;


function parseEnum(var p: TParser): PNode;
var
  a, b: PNode;
begin
  result := newNodeP(nkEnumTy, p);
  a := nil;
  getTok(p);
  optInd(p, result);
  if p.tok.tokType = tkOf then begin
    a := newNodeP(nkOfInherit, p);
    getTok(p); optInd(p, a);
    addSon(a, parseTypeDesc(p));
    addSon(result, a)
  end
  else addSon(result, nil);

  while true do begin
    case p.tok.tokType of
      tkEof, tkSad, tkDed: break;
      else a := parseSymbol(p);
    end;
    optInd(p, a);
    if p.tok.tokType = tkEquals then begin
      getTok(p);
      optInd(p, a);
      b := a;
      a := newNodeP(nkEnumFieldDef, p);
      addSon(a, b);
      addSon(a, parseExpr(p));
      skipComment(p, a);
    end;
    if p.tok.tokType = tkComma then begin
      getTok(p);
      optInd(p, a)
    end;
    addSon(result, a);
  end
end;

function parseObjectPart(var p: TParser): PNode; forward;

function parseObjectWhen(var p: TParser): PNode;
var
  branch: PNode;
begin
  result := newNodeP(nkRecWhen, p);
  while true do begin
    getTok(p); // skip `when`, `elif`
    branch := newNodeP(nkElifBranch, p);
    optInd(p, branch);
    addSon(branch, parseExpr(p));
    eat(p, tkColon);
    skipComment(p, branch);
    addSon(branch, parseObjectPart(p));
    skipComment(p, branch);
    addSon(result, branch);
    if p.tok.tokType <> tkElif then break
  end;
  if p.tok.tokType = tkElse then begin
    branch := newNodeP(nkElse, p);
    eat(p, tkElse); eat(p, tkColon);
    skipComment(p, branch);
    addSon(branch, parseObjectPart(p));
    addSon(result, branch);
  end
end;

function parseObjectCase(var p: TParser): PNode;
var
  a, b: PNode;
begin
  result := newNodeP(nkRecCase, p);
  getTok(p);
  a := newNodeP(nkIdentDefs, p);
  addSon(a, identWithPragma(p));
  eat(p, tkColon);
  addSon(a, parseTypeDesc(p));
  addSon(a, nil);
  addSon(result, a);
  skipComment(p, result);
  while true do begin
    if p.tok.tokType = tkSad then getTok(p);
    case p.tok.tokType of
      tkOf: begin
        b := newNodeP(nkOfBranch, p);
        exprListAux(p, nkRange, tkColon, tkDotDot, b);
      end;
      tkElse: begin
        b := newNodeP(nkElse, p);
        getTok(p);
        eat(p, tkColon);
      end;
      else break;
    end;
    skipComment(p, b);
    addSon(b, parseObjectPart(p));
    addSon(result, b);
    if b.kind = nkElse then break;
  end
end;

function parseObjectPart(var p: TParser): PNode;
begin
  case p.tok.tokType of
    tkInd: begin
      result := newNodeP(nkRecList, p);
      pushInd(p.lex^, p.tok.indent);
      getTok(p); skipComment(p, result);
      while true do begin
        case p.tok.tokType of
          tkSad: getTok(p);
          tkCase, tkWhen, tkSymbol, tkAccent, tkNil: begin
            addSon(result, parseObjectPart(p));
          end;
          tkDed: begin getTok(p); break end;
          tkEof: break;
          else begin
            parMessage(p, errIdentifierExpected, tokToStr(p.tok));
            break
          end
        end
      end;
      popInd(p.lex^);
    end;
    tkWhen: result := parseObjectWhen(p);
    tkCase: result := parseObjectCase(p);
    tkSymbol, tkAccent: begin
      result := parseIdentColonEquals(p, {@set}[withPragma]);
      skipComment(p, result);
    end;
    tkNil: begin
      result := newNodeP(nkNilLit, p);
      getTok(p);
    end;
    else result := nil
  end
end;

function parseObject(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkObjectTy, p);
  getTok(p);
  if p.tok.tokType = tkCurlyDotLe then addSon(result, parsePragma(p))
  else addSon(result, nil);
  if p.tok.tokType = tkOf then begin
    a := newNodeP(nkOfInherit, p);
    getTok(p);
    addSon(a, parseTypeDesc(p));
    addSon(result, a);
  end
  else addSon(result, nil);
  skipComment(p, result);
  addSon(result, parseObjectPart(p));
end;

function parseDistinct(var p: TParser): PNode;
begin
  result := newNodeP(nkDistinctTy, p);
  getTok(p);
  optInd(p, result);
  addSon(result, parseTypeDesc(p));
end;

function parseTypeDef(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkTypeDef, p);
  addSon(result, identWithPragma(p));
  if p.tok.tokType = tkBracketLe then addSon(result, parseGenericParamList(p))
  else addSon(result, nil);
  if p.tok.tokType = tkEquals then begin
    getTok(p); optInd(p, result);
    case p.tok.tokType of
      tkObject: a := parseObject(p);
      tkEnum: a := parseEnum(p);
      tkDistinct: a := parseDistinct(p);
      else a := parseTypeDesc(p);
    end;
    addSon(result, a);
  end
  else
    addSon(result, nil);
  indAndComment(p, result); // special extension!
end;

function parseVarTuple(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkVarTuple, p);
  getTok(p); // skip '('
  optInd(p, result);
  while (p.tok.tokType = tkSymbol) or (p.tok.tokType = tkAccent) do begin
    a := identWithPragma(p);
    addSon(result, a);
    if p.tok.tokType <> tkComma then break;
    getTok(p);
    optInd(p, a)
  end;
  addSon(result, nil); // no type desc
  optSad(p);
  eat(p, tkParRi);
  eat(p, tkEquals);
  optInd(p, result);
  addSon(result, parseExpr(p));
end;

function parseVariable(var p: TParser): PNode;
begin
  if p.tok.tokType = tkParLe then 
    result := parseVarTuple(p)
  else
    result := parseIdentColonEquals(p, {@set}[withPragma]);
  indAndComment(p, result); // special extension!
end;

function simpleStmt(var p: TParser): PNode;
begin
  case p.tok.tokType of
    tkReturn:   result := parseReturnOrRaise(p, nkReturnStmt);
    tkRaise:    result := parseReturnOrRaise(p, nkRaiseStmt);
    tkYield:    result := parseYieldOrDiscard(p, nkYieldStmt);
    tkDiscard:  result := parseYieldOrDiscard(p, nkDiscardStmt);
    tkBreak:    result := parseBreakOrContinue(p, nkBreakStmt);
    tkContinue: result := parseBreakOrContinue(p, nkContinueStmt);
    tkCurlyDotLe: result := parsePragma(p);
    tkImport: result := parseImportOrIncludeStmt(p, nkImportStmt);
    tkFrom: result := parseFromStmt(p);
    tkInclude: result := parseImportOrIncludeStmt(p, nkIncludeStmt);
    tkComment: result := newCommentStmt(p);
    else begin
      if isExprStart(p) then 
        result := parseExprStmt(p)
      else 
        result := nil;
    end
  end;
  if result <> nil then
    skipComment(p, result);
end;

function parseType(var p: TParser): PNode;
begin
  result := newNodeP(nkTypeSection, p);
  while true do begin
    case p.tok.tokType of
      tkComment: skipComment(p, result);
      tkType: begin
        // type alias:
        
      end;
      tkEnum:
      tkObject:
      tkTuple:
      else break;
    end
  end
end;

function complexOrSimpleStmt(var p: TParser): PNode;
begin
  case p.tok.tokType of
    tkIf:        result := parseIfOrWhen(p, nkIfStmt);
    tkWhile:     result := parseWhile(p);
    tkCase:      result := parseCase(p);
    tkTry:       result := parseTry(p);
    tkFor:       result := parseFor(p);
    tkBlock:     result := parseBlock(p);
    tkAsm:       result := parseAsm(p);
    tkProc:      result := parseRoutine(p, nkProcDef);
    tkMethod:    result := parseRoutine(p, nkMethodDef);
    tkIterator:  result := parseRoutine(p, nkIteratorDef);
    tkMacro:     result := parseRoutine(p, nkMacroDef);
    tkTemplate:  result := parseRoutine(p, nkTemplateDef);
    tkConverter: result := parseRoutine(p, nkConverterDef);
    tkType, tkEnum, tkObject, tkTuple:      
      result := parseTypeAlias(p, nkTypeSection, parseTypeDef);
    tkConst:     result := parseConstSection(p);
    tkWhen:      result := parseIfOrWhen(p, nkWhenStmt);
    tkVar:       result := parseSection(p, nkVarSection, parseVariable);
    else         result := simpleStmt(p);
  end
end;

function parseStmt(var p: TParser): PNode;
var
  a: PNode;
begin
  if p.tok.tokType = tkCurlyLe then begin
    result := newNodeP(nkStmtList, p);
    getTok(p);
    while true do begin
      case p.tok.tokType of
        tkSad, tkInd, tkDed: getTok(p);
        tkEof, tkCurlyRi: break;
        else begin
          a := complexOrSimpleStmt(p);
          if a = nil then break;
          addSon(result, a);
        end
      end
    end;
    eat(p, tkCurlyRi);
  end
  else begin
    // the case statement is only needed for better error messages:
    case p.tok.tokType of
      tkIf, tkWhile, tkCase, tkTry, tkFor, tkBlock, tkAsm,
      tkProc, tkIterator, tkMacro, tkType, tkConst, tkWhen, tkVar: begin
        parMessage(p, errComplexStmtRequiresInd);
        result := nil
      end
      else begin
        result := simpleStmt(p);
        if result = nil then parMessage(p, errExprExpected, tokToStr(p.tok));
        if p.tok.tokType in [tkInd, tkDed, tkSad] then getTok(p);
      end
    end
  end
end;

function parseAll(var p: TParser): PNode;
var
  a: PNode;
begin
  result := newNodeP(nkStmtList, p);
  while true do begin
    case p.tok.tokType of
      tkDed, tkInd, tkSad: getTok(p);
      tkEof: break;
      else begin
        a := complexOrSimpleStmt(p);
        if a = nil then parMessage(p, errExprExpected, tokToStr(p.tok));
        addSon(result, a);
      end
    end
  end
end;

function parseTopLevelStmt(var p: TParser): PNode;
begin
  result := nil;
  while true do begin
    case p.tok.tokType of
      tkDed, tkInd, tkSad: getTok(p);
      tkEof: break;
      else begin
        result := complexOrSimpleStmt(p);
        if result = nil then parMessage(p, errExprExpected, tokToStr(p.tok));
        break
      end
    end
  end
end;

end.
