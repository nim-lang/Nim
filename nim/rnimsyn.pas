//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit rnimsyn;

// This module implements the renderer of the standard Nimrod representation.

{$include config.inc}

interface

uses
  nsystem, charsets, lexbase, scanner, options, idents, strutils, ast, msgs,
  lists;

type
  TRenderFlag = (renderNone, renderNoBody, renderNoComments,
                 renderNoPragmas, renderIds);
  TRenderFlags = set of TRenderFlag;

  TRenderTok = record
    kind: TTokType;
    len: int16;
  end;
  TRenderTokSeq = array of TRenderTok;

  TSrcGen = record
    indent: int;
    lineLen: int;
    pos: int;       // current position for iteration over the buffer
    idx: int;       // current token index for iteration over the buffer
    tokens: TRenderTokSeq;
    buf: string;
    pendingNL: int; // negative if not active; else contains the
                    // indentation value
    comStack: array of PNode;  // comment stack
    flags: TRenderFlags;
  end;

procedure renderModule(n: PNode; const filename: string;
                       renderFlags: TRenderFlags = {@set}[]);

function renderTree(n: PNode; renderFlags: TRenderFlags = {@set}[]): string;

procedure initTokRender(var r: TSrcGen; n: PNode;
                        renderFlags: TRenderFlags = {@set}[]);
procedure getNextTok(var r: TSrcGen; var kind: TTokType; var literal: string);

implementation

// We render the source code in a two phases: The first
// determines how long the subtree will likely be, the second
// phase appends to a buffer that will be the output.

const
  IndentWidth = 2;
  longIndentWid = 4;
  MaxLineLen = 80;
  LineCommentColumn = 30;

procedure InitSrcGen(out g: TSrcGen; renderFlags: TRenderFlags);
begin
{@ignore}
  fillChar(g, sizeof(g), 0);
  g.comStack := nil;
  g.tokens := nil;
{@emit
  g.comStack := [];}
{@emit
  g.tokens := [];}
  g.indent := 0;
  g.lineLen := 0;
  g.pos := 0;
  g.idx := 0;
  g.buf := '';
  g.flags := renderFlags;
  g.pendingNL := -1;
end;

{@ignore}
procedure add(var dest: string; const src: string);
begin
  dest := dest +{&} src;
end;
{@emit}

procedure addTok(var g: TSrcGen; kind: TTokType; const s: string);
var
  len: int;
begin
  len := length(g.tokens);
  setLength(g.tokens, len+1);
  g.tokens[len].kind := kind;
  g.tokens[len].len := int16(length(s));
  add(g.buf, s);
end;

procedure addPendingNL(var g: TSrcGen);
begin
  if g.pendingNL >= 0 then begin
    addTok(g, tkInd, NL+{&}repeatChar(g.pendingNL));
    g.lineLen := g.pendingNL;
    g.pendingNL := -1;
  end
end;

procedure putNL(var g: TSrcGen; indent: int); overload;
begin
  if g.pendingNL >= 0 then
    addPendingNL(g)
  else
    addTok(g, tkInd, NL);
  g.pendingNL := indent;
  g.lineLen := indent;
end;

procedure putNL(var g: TSrcGen); overload;
begin
  putNL(g, g.indent);
end;

procedure optNL(var g: TSrcGen; indent: int); overload;
begin
  g.pendingNL := indent;
  g.lineLen := indent; // BUGFIX
end;

procedure optNL(var g: TSrcGen); overload;
begin
  optNL(g, g.indent)
end;

procedure indentNL(var g: TSrcGen);
begin
  inc(g.indent, indentWidth);
  g.pendingNL := g.indent;
  g.lineLen := g.indent;
end;

procedure Dedent(var g: TSrcGen);
begin
  dec(g.indent, indentWidth);
  assert(g.indent >= 0);
  if g.pendingNL > indentWidth then begin
    Dec(g.pendingNL, indentWidth);
    Dec(g.lineLen, indentWidth)
  end
end;

procedure put(var g: TSrcGen; const kind: TTokType; const s: string);
begin
  addPendingNL(g);
  if length(s) > 0 then begin
    addTok(g, kind, s);
    inc(g.lineLen, length(s));
  end
end;

procedure putLong(var g: TSrcGen; const kind: TTokType; const s: string;
                  lineLen: int);
// use this for tokens over multiple lines.
begin
  addPendingNL(g);
  addTok(g, kind, s);
  g.lineLen := lineLen;
end;

// ----------------------- helpers --------------------------------------------

function toNimChar(c: Char): string;
begin
  case c of
    #0: result := '\0';
    #1..#31, #128..#255: result := '\x' + strutils.toHex(ord(c), 2);
    '''', '"', '\': result := '\' + c;
    else result := c + ''
  end;
end;

function makeNimString(const s: string): string;
var
  i: int;
begin
  result := '"' + '';
  for i := strStart to length(s)+strStart-1 do begin
    result := result +{&} toNimChar(s[i]);
  end;
  result := result + '"';
end;

procedure putComment(var g: TSrcGen; s: string);
var
  i, j, ind, comIndent: int;
  isCode: bool;
  com: string;
begin
  {@ignore} s := s + #0; {@emit}
  i := strStart;
  comIndent := 1;
  isCode := (length(s) >= 2) and (s[strStart+1] <> ' ');
  ind := g.lineLen;
  com := '';
  while true do begin
    case s[i] of
      #0: break;
      #13: begin
        put(g, tkComment, com);
        com := '';
        inc(i);
        if s[i] = #10 then inc(i);
        optNL(g, ind);
      end;
      #10: begin
        put(g, tkComment, com);
        com := '';
        inc(i);
        optNL(g, ind);
      end;
      '#': begin
        addChar(com, s[i]);
        inc(i);
        comIndent := 0;
        while s[i] = ' ' do begin
          addChar(com, s[i]);
          inc(i); inc(comIndent);
        end
      end;
      ' ', #9: begin
        addChar(com, s[i]);
        inc(i);
      end
      else begin
        // we may break the comment into a multi-line comment if the line
        // gets too long:

        // compute length of the following word:
        j := i;
        while s[j] > ' ' do inc(j);
        if not isCode and (g.lineLen + (j-i) > MaxLineLen) then begin
          put(g, tkComment, com);
          com := '';
          optNL(g, ind);
          com := com +{&} '#' +{&} repeatChar(comIndent);
        end;
        while s[i] > ' ' do begin
          addChar(com, s[i]);
          inc(i);
        end
      end
    end
  end;
  put(g, tkComment, com);
  optNL(g);
end;

function maxLineLength(s: string): int;
var
  i, linelen: int;
begin
  {@ignore} s := s + #0; {@emit}
  result := 0;
  i := strStart;
  lineLen := 0;
  while true do begin
    case s[i] of
      #0: break;
      #13: begin
        inc(i);
        if s[i] = #10 then inc(i);
        result := max(result, lineLen);
        lineLen := 0;
      end;
      #10: begin
        inc(i);
        result := max(result, lineLen);
        lineLen := 0;
      end;
      else begin
        inc(lineLen); inc(i);
      end
    end
  end
end;

procedure putRawStr(var g: TSrcGen; kind: TTokType; const s: string);
var
  i, hi: int;
  str: string;
begin
  i := strStart;
  hi := length(s)+strStart-1;
  str := '';
  while i <= hi do begin
    case s[i] of
      #13: begin
        put(g, kind, str);
        str := '';
        inc(i);
        if (i <= hi) and (s[i] = #10) then inc(i);
        optNL(g, 0);
      end;
      #10: begin
        put(g, kind, str);
        str := '';
        inc(i);
        optNL(g, 0);
      end;
      else begin
        addChar(str, s[i]);
        inc(i)
      end
    end
  end;
  put(g, kind, str);
end;

function containsNL(const s: string): bool;
var
  i: int;
begin
  for i := strStart to length(s)+strStart-1 do
    case s[i] of
      #13, #10: begin result := true; exit end;
      else begin end
    end;
  result := false
end;

procedure pushCom(var g: TSrcGen; n: PNode);
var
  len: int;
begin
  len := length(g.comStack);
  setLength(g.comStack, len+1);
  g.comStack[len] := n;
end;

procedure popAllComs(var g: TSrcGen);
begin
  setLength(g.comStack, 0);
end;

procedure popCom(var g: TSrcGen);
begin
  setLength(g.comStack, length(g.comStack)-1);
end;

const
  Space = ' '+'';

procedure gcom(var g: TSrcGen; n: PNode);
var
  ml: int;
begin
  assert(n <> nil);
  if (n.comment <> snil) and not (renderNoComments in g.flags) then begin
    if (g.pendingNL < 0) and (length(g.buf) > 0)
    and (g.buf[length(g.buf)] <> ' ') then
      put(g, tkSpaces, Space);
    // Before long comments we cannot make sure that a newline is generated,
    // because this might be wrong. But it is no problem in practice.
    if (g.pendingNL < 0) and (length(g.buf) > 0)
        and (g.lineLen < LineCommentColumn) then begin
      ml := maxLineLength(n.comment);
      if ml+LineCommentColumn <= maxLineLen then
        put(g, tkSpaces, repeatChar(LineCommentColumn - g.lineLen));
    end;
    putComment(g, n.comment);
    //assert(g.comStack[high(g.comStack)] = n);
  end
end;

procedure gcoms(var g: TSrcGen);
var
  i: int;
begin
  for i := 0 to high(g.comStack) do gcom(g, g.comStack[i]);
  popAllComs(g);
end;

// ----------------------------------------------------------------------------

function lsub(n: PNode): int; forward;

function litAux(n: PNode; x: biggestInt; size: int): string;
begin
  if nfBase2 in n.flags then result := '0b' + toBin(x, size*8)
  else if nfBase8 in n.flags then result := '0o' + toOct(x, size*3)
  else if nfBase16 in n.flags then result := '0x' + toHex(x, size*2)
  else result := toString(x)
end;

function atom(n: PNode): string;
var
  f: float32;
begin
  case n.kind of
    nkEmpty:        result := '';
    nkIdent:        result := n.ident.s;
    nkSym:          result := n.sym.name.s;
    nkStrLit:       result := makeNimString(n.strVal);
    nkRStrLit:      result := 'r"' + n.strVal + '"';
    nkTripleStrLit: result := '"""' + n.strVal + '"""';
    nkCharLit:      result := '''' + toNimChar(chr(int(n.intVal))) + '''';
    nkIntLit:       result := litAux(n, n.intVal, 4);
    nkInt8Lit:      result := litAux(n, n.intVal, 1) + '''i8';
    nkInt16Lit:     result := litAux(n, n.intVal, 2) + '''i16';
    nkInt32Lit:     result := litAux(n, n.intVal, 4) + '''i32';
    nkInt64Lit:     result := litAux(n, n.intVal, 8) + '''i64';
    nkFloatLit:     begin
      if n.flags * [nfBase2, nfBase8, nfBase16] = [] then
        result := toStringF(n.floatVal)
      else
        result := litAux(n, ({@cast}PInt64(addr(n.floatVal)))^, 8);
    end;
    nkFloat32Lit:   begin
      if n.flags * [nfBase2, nfBase8, nfBase16] = [] then
        result := toStringF(n.floatVal) + '''f32'
      else begin
        f := n.floatVal;
        result := litAux(n, ({@cast}PInt32(addr(f)))^, 4) + '''f32'
      end;
    end;
    nkFloat64Lit:   begin
      if n.flags * [nfBase2, nfBase8, nfBase16] = [] then
        result := toStringF(n.floatVal) + '''f64'
      else
        result := litAux(n, ({@cast}PInt64(addr(n.floatVal)))^, 8) + '''f64';
    end;
    nkNilLit: result := 'nil';
    nkType: begin
      if (n.typ <> nil) and (n.typ.sym <> nil) then result := n.typ.sym.name.s
      else result := '[type node]';
    end;
    else InternalError('rnimsyn.atom ' + nodeKindToStr[n.kind]);
  end
end;

// ---------------------------------------------------------------------------

function lcomma(n: PNode; start: int = 0; theEnd: int = -1): int;
var
  i: int;
begin
  assert(theEnd < 0);
  result := 0;
  for i := start to sonsLen(n)+theEnd do begin
    inc(result, lsub(n.sons[i]));
    inc(result, 2); // for ``, ``
  end;
  if result > 0 then dec(result, 2); // last does not get a comma!
end;

function lsons(n: PNode; start: int = 0; theEnd: int = -1): int;
var
  i: int;
begin
  assert(theEnd < 0);
  result := 0;
  for i := start to sonsLen(n)+theEnd do inc(result, lsub(n.sons[i]));
end;

function lsub(n: PNode): int;
// computes the length of a tree
var
  L: int;
begin
  if n = nil then begin result := 0; exit end;
  if n.comment <> snil then begin result := maxLineLen+1; exit end;
  case n.kind of
    nkTripleStrLit: begin
      if containsNL(n.strVal) then result := maxLineLen+1
      else result := length(atom(n));
    end;
    nkEmpty..pred(nkTripleStrLit), succ(nkTripleStrLit)..nkNilLit:
      result := length(atom(n));
    nkCall, nkBracketExpr, nkConv: result := lsub(n.sons[0])+lcomma(n, 1)+2;
    nkHiddenStdConv, nkHiddenSubConv, nkHiddenCallConv: begin
      result := lsub(n.sons[1]);
    end;
    nkCast: result := lsub(n.sons[0])+lsub(n.sons[1])+length('cast[]()');
    nkAddr: result := lsub(n.sons[0])+length('addr()');
    nkHiddenAddr, nkHiddenDeref: result := lsub(n.sons[0]);
    nkCommand: result := lsub(n.sons[0])+lcomma(n, 1)+1;
    nkExprEqExpr, nkDefaultTypeParam, nkAsgn: result := lsons(n)+3;
    nkPar, nkCurly, nkBracket: result := lcomma(n)+2;
    nkTupleTy: result := lcomma(n)+length('tuple[]');
    nkQualified, nkDotExpr: result := lsons(n)+1;
    nkCheckedFieldExpr: result := lsub(n.sons[0]);
    nkLambda: result := lsons(n)+length('lambda__=_');
    nkConstDef, nkIdentDefs: begin
      result := lcomma(n, 0, -3);
      L := sonsLen(n);
      if n.sons[L-2] <> nil then
        result := result + lsub(n.sons[L-2]) + 2;
      if n.sons[L-1] <> nil then
        result := result + lsub(n.sons[L-1]) + 3;
    end;
    nkChckRangeF: result := length('chckRangeF') + 2 + lcomma(n);
    nkChckRange64: result := length('chckRange64') + 2 + lcomma(n);
    nkChckRange: result := length('chckRange') + 2 + lcomma(n);
    
    nkObjDownConv, nkObjUpConv, 
    nkStringToCString, nkCStringToString, nkPassAsOpenArray: begin
      result := 2;
      if sonsLen(n) >= 1 then
        result := result + lsub(n.sons[0]);
      result := result + lcomma(n, 1);
    end;
    nkExprColonExpr:  result := lsons(n) + 2;
    nkInfix:          result := lsons(n) + 2;
    nkPrefix:         result := lsons(n) + 1;
    nkPostfix:        result := lsons(n);
    nkPragmaExpr:     result := lsub(n.sons[0])+lcomma(n, 1);
    nkRange:          result := lsons(n) + 2;
    nkDerefExpr:      result := lsub(n.sons[0])+2;
    nkImportAs:       result := lsons(n) + length('_as_');
    nkAccQuoted:      result := lsub(n.sons[0]) + 2;
    nkHeaderQuoted:   result := lsub(n.sons[0]) + lsub(n.sons[1]) + 2;

    nkIfExpr:         result := lsub(n.sons[0].sons[0])+lsub(n.sons[0].sons[1])
                              + lsons(n, 1) + length('if_:_');
    nkElifExpr:       result := lsons(n) + length('_elif_:_');
    nkElseExpr:       result := lsub(n.sons[0])+ length('_else:_');

    // type descriptions
    nkTypeOfExpr:     result := lsub(n.sons[0])+length('type_');
    nkRefTy:          result := lsub(n.sons[0])+length('ref_');
    nkPtrTy:          result := lsub(n.sons[0])+length('ptr_');
    nkVarTy:          result := lsub(n.sons[0])+length('var_');
    nkTypeDef:        result := lsons(n)+3;
    nkOfInherit:      result := lsub(n.sons[0])+length('of_');
    nkProcTy:         result := lsons(n)+length('proc_');
    nkEnumTy:         result := lsub(n.sons[0])+lcomma(n,1)+length('enum_');
    nkEnumFieldDef:   result := lsons(n)+3;

    nkVarSection:     if sonsLen(n) > 1 then result := maxLineLen+1
                      else result := lsons(n) + length('var_');
    nkReturnStmt:     result := lsub(n.sons[0])+length('return_');
    nkRaiseStmt:      result := lsub(n.sons[0])+length('raise_');
    nkYieldStmt:      result := lsub(n.sons[0])+length('yield_');
    nkDiscardStmt:    result := lsub(n.sons[0])+length('discard_');
    nkBreakStmt:      result := lsub(n.sons[0])+length('break_');
    nkContinueStmt:   result := lsub(n.sons[0])+length('continue_');
    nkPragma:         result := lcomma(n) + 4;
    nkCommentStmt:    result := length(n.comment);

    nkOfBranch:       result := lcomma(n, 0, -2) + lsub(lastSon(n))
                              + length('of_:_');
    nkElifBranch:     result := lsons(n)+length('elif_:_');
    nkElse:           result := lsub(n.sons[0]) + length('else:_');
    nkFinally:        result := lsub(n.sons[0]) + length('finally:_');
    nkGenericParams:  result := lcomma(n) + 2;
    nkFormalParams:   begin
      result := lcomma(n, 1) + 2;
      if n.sons[0] <> nil then result := result + lsub(n.sons[0]) + 2
    end;
    nkExceptBranch:   result := lcomma(n, 0, -2) + lsub(lastSon(n))
                              + length('except_:_');
    else result := maxLineLen+1
  end
end;

function fits(const g: TSrcGen; x: int): bool;
begin
  result := x + g.lineLen <= maxLineLen
end;

// ------------------------- render part --------------------------------------

type
  TSubFlag = (rfLongMode, rfNoIndent, rfInConstExpr);
  TSubFlags = set of TSubFlag;
  TContext = record{@tuple}
    spacing: int;
    flags: TSubFlags;
  end;

const
  emptyContext: TContext = (spacing: 0; flags: {@set}[]);

procedure initContext(out c: TContext);
begin
  c.spacing := 0;
  c.flags := {@set}[];
end;

procedure gsub(var g: TSrcGen; n: PNode; const c: TContext); overload; forward;

procedure gsub(var g: TSrcGen; n: PNode); overload;
var
  c: TContext;
begin
  initContext(c);
  gsub(g, n, c);
end;

function one(b: bool): int;
begin
  if b then result := 1 else result := 0
end;

function hasCom(n: PNode): bool;
var
  i: int;
begin
  result := false;
  if n = nil then exit;
  if n.comment <> snil then begin result := true; exit end;
  case n.kind of
    nkEmpty..nkNilLit: begin end;
    else begin
      for i := 0 to sonsLen(n)-1 do
        if hasCom(n.sons[i]) then begin
          result := true; exit
        end
    end
  end
end;

procedure putWithSpace(var g: TSrcGen; kind: TTokType; const s: string);
begin
  put(g, kind, s);
  put(g, tkSpaces, Space);
end;

procedure gcommaAux(var g: TSrcGen; n: PNode; ind: int;
                    start: int = 0; theEnd: int = -1);
var
  i, sublen: int;
  c: bool;
begin
  for i := start to sonsLen(n)+theEnd do begin
    c := i < sonsLen(n)+theEnd;
    sublen := lsub(n.sons[i])+one(c);
    if not fits(g, sublen) and (ind+sublen < maxLineLen) then optNL(g, ind);
    gsub(g, n.sons[i]);
    if c then begin
      putWithSpace(g, tkComma, ','+'');
      if hasCom(n.sons[i]) then begin
        gcoms(g);
        optNL(g, ind);
      end
    end
  end
end;

procedure gcomma(var g: TSrcGen; n: PNode; const c: TContext;
                 start: int = 0; theEnd: int = -1); overload;
var
  ind: int;
begin
  if rfInConstExpr in c.flags then
    ind := g.indent + indentWidth
  else begin
    ind := g.lineLen;
    if ind > maxLineLen div 2 then ind := g.indent + longIndentWid
  end;
  gcommaAux(g, n, ind, start, theEnd);
end;

procedure gcomma(var g: TSrcGen; n: PNode;
                 start: int = 0; theEnd: int = -1); overload;
var
  ind: int;
begin
  ind := g.lineLen;
  if ind > maxLineLen div 2 then ind := g.indent + longIndentWid;
  gcommaAux(g, n, ind, start, theEnd);
end;

procedure gsons(var g: TSrcGen; n: PNode; const c: TContext;
                start: int = 0; theEnd: int = -1);
var
  i: int;
begin
  for i := start to sonsLen(n)+theEnd do begin
    gsub(g, n.sons[i], c);
  end
end;

procedure gsection(var g: TSrcGen; n: PNode; const c: TContext; kind: TTokType;
                   const k: string);
var
  i: int;
begin
  if sonsLen(n) = 0 then exit; // empty var sections are possible
  putWithSpace(g, kind, k);
  gcoms(g);
  indentNL(g);
  for i := 0 to sonsLen(n)-1 do begin
    optNL(g);
    gsub(g, n.sons[i], c);
    gcoms(g);
  end;
  dedent(g);
end;


function longMode(n: PNode; start: int = 0; theEnd: int = -1): bool;
var
  i: int;
begin
  result := n.comment <> snil;
  if not result then begin
    // check further
    for i := start to sonsLen(n)+theEnd do begin
      if (lsub(n.sons[i]) > maxLineLen) then begin
        result := true; break end;
    end
  end
end;

procedure gstmts(var g: TSrcGen; n: PNode; const c: TContext);
var
  i: int;
begin
  if n = nil then exit;
  if (n.kind = nkStmtList) or (n.kind = nkStmtListExpr) then begin
    indentNL(g);
    for i := 0 to sonsLen(n)-1 do begin
      optNL(g);
      gsub(g, n.sons[i]);
      gcoms(g);
    end;
    dedent(g);
  end
  else begin
    if rfLongMode in c.flags then indentNL(g);
    gsub(g, n);
    gcoms(g);
    optNL(g);
    if rfLongMode in c.flags then dedent(g);
  end
end;

procedure gif(var g: TSrcGen; n: PNode);
var
  c: TContext;
  i, len: int;
begin
  gsub(g, n.sons[0].sons[0]);
  initContext(c);
  putWithSpace(g, tkColon, ':'+'');
  if longMode(n) or (lsub(n.sons[0].sons[1])+g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcoms(g); // a good place for comments
  gstmts(g, n.sons[0].sons[1], c);
  len := sonsLen(n);
  for i := 1 to len-1 do begin
    optNL(g);
    gsub(g, n.sons[i], c)
  end;
end;

procedure gwhile(var g: TSrcGen; n: PNode);
var
  c: TContext;
begin
  putWithSpace(g, tkWhile, 'while');
  gsub(g, n.sons[0]);
  putWithSpace(g, tkColon, ':'+'');
  initContext(c);
  if longMode(n) or (lsub(n.sons[1])+g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcoms(g); // a good place for comments
  gstmts(g, n.sons[1], c);
end;

procedure gtry(var g: TSrcGen; n: PNode);
var
  c: TContext;
begin
  put(g, tkTry, 'try');
  putWithSpace(g, tkColon, ':'+'');
  initContext(c);
  if longMode(n) or (lsub(n.sons[0])+g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcoms(g); // a good place for comments
  gstmts(g, n.sons[0], c);
  gsons(g, n, c, 1);
end;

procedure gfor(var g: TSrcGen; n: PNode);
var
  c: TContext;
  len: int;
begin
  len := sonsLen(n);
  putWithSpace(g, tkFor, 'for');
  initContext(c);
  if longMode(n)
      or (lsub(n.sons[len-1])
        + lsub(n.sons[len-2]) + 6 + g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcomma(g, n, c, 0, -3);
  put(g, tkSpaces, Space);
  putWithSpace(g, tkIn, 'in');
  gsub(g, n.sons[len-2], c);
  putWithSpace(g, tkColon, ':'+'');
  gcoms(g);
  gstmts(g, n.sons[len-1], c);
end;

procedure gmacro(var g: TSrcGen; n: PNode);
var
  c: TContext;
begin
  initContext(c);
  gsub(g, n.sons[0]);
  putWithSpace(g, tkColon, ':'+'');
  if longMode(n) or (lsub(n.sons[1])+g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcoms(g);
  gsons(g, n, c, 1);
end;

procedure gcase(var g: TSrcGen; n: PNode);
var
  c: TContext;
  len, last: int;
begin
  initContext(c);
  len := sonsLen(n);
  if n.sons[len-1].kind = nkElse then last := -2
  else last := -1;
  if longMode(n, 0, last) then include(c.flags, rfLongMode);
  putWithSpace(g, tkCase, 'case');
  gsub(g, n.sons[0]);
  gcoms(g);
  optNL(g);
  gsons(g, n, c, 1, last);
  if last = -2 then begin
    initContext(c);
    if longMode(n.sons[len-1]) then include(c.flags, rfLongMode);
    gsub(g, n.sons[len-1], c);
  end
end;

procedure gproc(var g: TSrcGen; n: PNode);
var
  c: TContext;
begin
  gsub(g, n.sons[0]);
  gsub(g, n.sons[1]);
  gsub(g, n.sons[2]);
  gsub(g, n.sons[3]);
  if not (renderNoBody in g.flags) then begin
    if n.sons[4] <> nil then begin
      put(g, tkSpaces, Space);
      putWithSpace(g, tkEquals, '='+'');
      indentNL(g);
      gcoms(g);
      dedent(g);
      initContext(c);
      gstmts(g, n.sons[4], c);
      putNL(g);
    end
    else begin
      indentNL(g);
      gcoms(g);
      dedent(g);
    end
  end;
end;

procedure gblock(var g: TSrcGen; n: PNode);
var
  c: TContext;
begin
  initContext(c);
  putWithSpace(g, tkBlock, 'block');
  gsub(g, n.sons[0]);
  putWithSpace(g, tkColon, ':'+'');
  if longMode(n) or (lsub(n.sons[1])+g.lineLen > maxLineLen) then
    include(c.flags, rfLongMode);
  gcoms(g);
  gstmts(g, n.sons[1], c);
end;

procedure gasm(var g: TSrcGen; n: PNode);
begin
  putWithSpace(g, tkAsm, 'asm');
  gsub(g, n.sons[0]);
  gcoms(g);
  gsub(g, n.sons[1]);
end;

procedure gident(var g: TSrcGen; n: PNode);
var
  s: string;
  t: TTokType;
begin
  s := atom(n);
  if (s[strStart] in scanner.SymChars) then begin
    if (n.kind = nkIdent) then begin
      if (n.ident.id < ord(tokKeywordLow)-ord(tkSymbol)) or
         (n.ident.id > ord(tokKeywordHigh)-ord(tkSymbol)) then
        t := tkSymbol
      else
        t := TTokType(n.ident.id+ord(tkSymbol))
    end
    else
      t := tkSymbol;
  end
  else
    t := tkOpr;
  put(g, t, s);
  if (n.kind = nkSym) and (renderIds in g.flags) then
    put(g, tkIntLit, toString(n.sym.id));
end;

procedure gsub(var g: TSrcGen; n: PNode; const c: TContext);
var
  L, i: int;
  a: TContext;
begin
  if n = nil then exit;
  if n.comment <> snil then pushCom(g, n);
  case n.kind of
    // atoms:
    nkTripleStrLit: putRawStr(g, tkTripleStrLit, n.strVal);
    nkEmpty, nkType: put(g, tkInvalid, atom(n));
    nkSym, nkIdent: gident(g, n);
    nkIntLit: put(g, tkIntLit, atom(n));
    nkInt8Lit: put(g, tkInt8Lit, atom(n));
    nkInt16Lit: put(g, tkInt16Lit, atom(n));
    nkInt32Lit: put(g, tkInt32Lit, atom(n));
    nkInt64Lit: put(g, tkInt64Lit, atom(n));
    nkFloatLit: put(g, tkFloatLit, atom(n));
    nkFloat32Lit: put(g, tkFloat32Lit, atom(n));
    nkFloat64Lit: put(g, tkFloat64Lit, atom(n));
    nkStrLit: put(g, tkStrLit, atom(n));
    nkRStrLit: put(g, tkRStrLit, atom(n));
    nkCharLit: put(g, tkCharLit, atom(n));
    nkNilLit: put(g, tkNil, atom(n));
    // complex expressions
    nkCall, nkConv, nkDotCall: begin
      if sonsLen(n) >= 1 then
        gsub(g, n.sons[0]);
      put(g, tkParLe, '('+'');
      gcomma(g, n, 1);
      put(g, tkParRi, ')'+'');
    end;
    nkHiddenStdConv, nkHiddenSubConv, nkHiddenCallConv: begin
      gsub(g, n.sons[0]);
    end;
    nkCast: begin
      put(g, tkCast, 'cast');
      put(g, tkBracketLe, '['+'');
      gsub(g, n.sons[0]);
      put(g, tkBracketRi, ']'+'');
      put(g, tkParLe, '('+'');
      gsub(g, n.sons[1]);
      put(g, tkParRi, ')'+'');
    end;
    nkAddr: begin
      put(g, tkAddr, 'addr');
      put(g, tkParLe, '('+'');
      gsub(g, n.sons[0]);
      put(g, tkParRi, ')'+'');
    end;
    nkBracketExpr: begin
      gsub(g, n.sons[0]);
      put(g, tkBracketLe, '['+'');
      gcomma(g, n, 1);
      put(g, tkBracketRi, ']'+'');
    end;
    nkPragmaExpr: begin
      gsub(g, n.sons[0]);
      gcomma(g, n, 1);
    end;
    nkCommand: begin
      gsub(g, n.sons[0]);
      put(g, tkSpaces, space);
      gcomma(g, n, 1);
    end;
    nkExprEqExpr, nkDefaultTypeParam, nkAsgn: begin
      gsub(g, n.sons[0]);
      put(g, tkSpaces, Space);
      putWithSpace(g, tkEquals, '='+'');
      gsub(g, n.sons[1]);
    end;
    nkChckRangeF: begin
      put(g, tkSymbol, 'chckRangeF');
      put(g, tkParLe, '('+'');
      gcomma(g, n);
      put(g, tkParRi, ')'+'');
    end;
    nkChckRange64: begin
      put(g, tkSymbol, 'chckRange64');
      put(g, tkParLe, '('+'');
      gcomma(g, n);
      put(g, tkParRi, ')'+'');    
    end;
    nkChckRange: begin
      put(g, tkSymbol, 'chckRange');
      put(g, tkParLe, '('+'');
      gcomma(g, n);
      put(g, tkParRi, ')'+'');
    end;
    nkObjDownConv, nkObjUpConv, 
    nkStringToCString, nkCStringToString, nkPassAsOpenArray: begin
      if sonsLen(n) >= 1 then
        gsub(g, n.sons[0]);
      put(g, tkParLe, '('+'');
      gcomma(g, n, 1);
      put(g, tkParRi, ')'+'');      
    end;
    nkPar: begin
      put(g, tkParLe, '('+'');
      gcomma(g, n, c);
      put(g, tkParRi, ')'+'');
    end;
    nkCurly: begin
      put(g, tkCurlyLe, '{'+'');
      gcomma(g, n, c);
      put(g, tkCurlyRi, '}'+'');
    end;
    nkBracket: begin
      put(g, tkBracketLe, '['+'');
      gcomma(g, n, c);
      put(g, tkBracketRi, ']'+'');
    end;
    nkQualified, nkDotExpr: begin
      gsub(g, n.sons[0]);
      put(g, tkDot, '.'+'');
      gsub(g, n.sons[1]);
    end;
    nkCheckedFieldExpr, nkHiddenAddr, nkHiddenDeref: gsub(g, n.sons[0]);
    nkLambda: begin
      assert(n.sons[genericParamsPos] = nil);
      putWithSpace(g, tkLambda, 'lambda');
      gsub(g, n.sons[paramsPos]);
      gsub(g, n.sons[pragmasPos]);
      put(g, tkSpaces, Space);
      putWithSpace(g, tkEquals, '='+'');
      gsub(g, n.sons[codePos]);
    end;
    nkConstDef, nkIdentDefs: begin
      gcomma(g, n, 0, -3);
      L := sonsLen(n);
      if n.sons[L-2] <> nil then begin
        putWithSpace(g, tkColon, ':'+'');
        gsub(g, n.sons[L-2])
      end;
      if n.sons[L-1] <> nil then begin
        put(g, tkSpaces, Space);
        putWithSpace(g, tkEquals, '='+'');
        gsub(g, n.sons[L-1], c)
      end;
    end;
    nkExprColonExpr: begin
      gsub(g, n.sons[0]);
      putWithSpace(g, tkColon, ':'+'');
      gsub(g, n.sons[1]);
    end;
    nkInfix: begin
      gsub(g, n.sons[1]);
      put(g, tkSpaces, Space);
      gsub(g, n.sons[0]); // binary operator
      if not fits(g, lsub(n.sons[2])+ lsub(n.sons[0]) + 1) then
        optNL(g, g.indent+longIndentWid)
      else put(g, tkSpaces, Space);
      gsub(g, n.sons[2]);
    end;
    nkPrefix: begin
      gsub(g, n.sons[0]);
      put(g, tkSpaces, space);
      gsub(g, n.sons[1]);
    end;
    nkPostfix: begin
      gsub(g, n.sons[1]);
      gsub(g, n.sons[0]);
    end;
    nkRange: begin
      gsub(g, n.sons[0]);
      put(g, tkDotDot, '..');
      gsub(g, n.sons[1]);
    end;
    nkDerefExpr: begin
      gsub(g, n.sons[0]);
      putWithSpace(g, tkHat, '^'+'');
      // unfortunately this requires a space, because ^. would be
      // only one operator
    end;
    nkImportAs: begin
      gsub(g, n.sons[0]);
      put(g, tkSpaces, Space);
      putWithSpace(g, tkAs, 'as');
      gsub(g, n.sons[1]);
    end;
    nkAccQuoted: begin
      put(g, tkAccent, '`'+'');
      gsub(g, n.sons[0]);
      put(g, tkAccent, '`'+'');
    end;
    nkHeaderQuoted: begin
      put(g, tkAccent, '`'+'');
      gsub(g, n.sons[0]);
      gsub(g, n.sons[1]);
      put(g, tkAccent, '`'+'');
    end;
    nkIfExpr: begin
      putWithSpace(g, tkIf, 'if');
      gsub(g, n.sons[0].sons[0]);
      putWithSpace(g, tkColon, ':'+'');
      gsub(g, n.sons[0].sons[1]);
      gsons(g, n, emptyContext, 1);
    end;
    nkElifExpr: begin
      putWithSpace(g, tkElif, ' elif');
      gsub(g, n.sons[0]);
      putWithSpace(g, tkColon, ':'+'');
      gsub(g, n.sons[1]);
    end;
    nkElseExpr: begin
      put(g, tkElse, ' else');
      putWithSpace(g, tkColon, ':'+'');
      gsub(g, n.sons[0]);
    end;

    nkTypeOfExpr: begin
      putWithSpace(g, tkType, 'type');
      gsub(g, n.sons[0]);
    end;
    nkRefTy: begin
      putWithSpace(g, tkRef, 'ref');
      gsub(g, n.sons[0]);
    end;
    nkPtrTy: begin
      putWithSpace(g, tkPtr, 'ptr');
      gsub(g, n.sons[0]);
    end;
    nkVarTy: begin
      putWithSpace(g, tkVar, 'var');
      gsub(g, n.sons[0]);
    end;
    nkTypeDef: begin
      gsub(g, n.sons[0]);
      gsub(g, n.sons[1]);
      put(g, tkSpaces, Space);
      if n.sons[2] <> nil then begin
        putWithSpace(g, tkEquals, '='+'');
        gsub(g, n.sons[2]);
      end
    end;
    nkObjectTy: begin
      putWithSpace(g, tkObject, 'object');
      gsub(g, n.sons[0]);
      gsub(g, n.sons[1]);
      gcoms(g);
      gsub(g, n.sons[2]);
    end;
    nkRecList: begin
      indentNL(g);
      for i := 0 to sonsLen(n)-1 do begin
        optNL(g);
        gsub(g, n.sons[i], c);
        gcoms(g);
      end;
      dedent(g);
      putNL(g);
    end;
    nkOfInherit: begin
      putWithSpace(g, tkOf, 'of');
      gsub(g, n.sons[0]);
    end;
    nkProcTy: begin
      putWithSpace(g, tkProc, 'proc');
      gsub(g, n.sons[0]);
      gsub(g, n.sons[1]);
    end;
    nkEnumTy: begin
      putWithSpace(g, tkEnum, 'enum');
      gsub(g, n.sons[0]);
      gcoms(g);
      indentNL(g);
      gcommaAux(g, n, g.indent, 1);
      dedent(g);
    end;
    nkEnumFieldDef: begin
      gsub(g, n.sons[0]);
      put(g, tkSpaces, Space);
      putWithSpace(g, tkEquals, '='+'');
      gsub(g, n.sons[1]);
    end;
    nkStmtList, nkStmtListExpr: gstmts(g, n, emptyContext);
    nkIfStmt: begin
      putWithSpace(g, tkIf, 'if');
      gif(g, n);
    end;
    nkWhenStmt, nkRecWhen: begin
      putWithSpace(g, tkWhen, 'when');
      gif(g, n);
    end;
    nkWhileStmt: gwhile(g, n);
    nkCaseStmt, nkRecCase: gcase(g, n);
    nkMacroStmt: gmacro(g, n);
    nkTryStmt: gtry(g, n);
    nkForStmt: gfor(g, n);
    nkBlockStmt, nkBlockExpr: gblock(g, n);
    nkAsmStmt: gasm(g, n);
    nkProcDef: begin
      putWithSpace(g, tkProc, 'proc');
      gproc(g, n);
    end;
    nkIteratorDef: begin
      putWithSpace(g, tkIterator, 'iterator');
      gproc(g, n);
    end;
    nkMacroDef: begin
      putWithSpace(g, tkMacro, 'macro');
      gproc(g, n);
    end;
    nkTemplateDef: begin
      putWithSpace(g, tkTemplate, 'template');
      gproc(g, n);
    end;
    nkTypeSection: gsection(g, n, emptyContext, tkType, 'type');
    nkConstSection: begin
      initContext(a);
      include(a.flags, rfInConstExpr);
      gsection(g, n, a, tkConst, 'const')
    end;
    nkVarSection: begin
      L := sonsLen(n);
      if L = 0 then exit;
      putWithSpace(g, tkVar, 'var');
      if L > 1 then begin
        gcoms(g);
        indentNL(g);
        for i := 0 to L-1 do begin
          optNL(g);
          gsub(g, n.sons[i]);
          gcoms(g);
        end;
        dedent(g);
      end
      else
        gsub(g, n.sons[0]);
    end;
    nkReturnStmt: begin
      putWithSpace(g, tkReturn, 'return');
      gsub(g, n.sons[0]);
    end;
    nkRaiseStmt: begin
      putWithSpace(g, tkRaise, 'raise');
      gsub(g, n.sons[0]);
    end;
    nkYieldStmt: begin
      putWithSpace(g, tkYield, 'yield');
      gsub(g, n.sons[0]);
    end;
    nkDiscardStmt: begin
      putWithSpace(g, tkDiscard, 'discard');
      gsub(g, n.sons[0]);
    end;
    nkBreakStmt: begin
      putWithSpace(g, tkBreak, 'break');
      gsub(g, n.sons[0]);
    end;
    nkContinueStmt: begin
      putWithSpace(g, tkContinue, 'continue');
      gsub(g, n.sons[0]);
    end;
    nkPragma: begin
      if not (renderNoPragmas in g.flags) then begin
        put(g, tkCurlyDotLe, '{.');
        gcomma(g, n, emptyContext);
        put(g, tkCurlyDotRi, '.}')
      end;
    end;
    nkImportStmt: begin
      putWithSpace(g, tkImport, 'import');
      gcoms(g);
      indentNL(g);
      gcommaAux(g, n, g.indent);
      dedent(g);
      putNL(g);
    end;
    nkFromStmt: begin
      putWithSpace(g, tkFrom, 'from');
      gsub(g, n.sons[0]);
      put(g, tkSpaces, Space);
      putWithSpace(g, tkImport, 'import');
      gcomma(g, n, emptyContext, 1);
      putNL(g);
    end;
    nkIncludeStmt: begin
      putWithSpace(g, tkInclude, 'include');
      gcoms(g);
      indentNL(g);
      gcommaAux(g, n, g.indent);
      dedent(g);
      putNL(g);
    end;
    nkCommentStmt: begin
      gcoms(g);
      optNL(g);
    end;
    nkOfBranch: begin
      optNL(g);
      putWithSpace(g, tkOf, 'of');
      gcomma(g, n, c, 0, -2);
      putWithSpace(g, tkColon, ':'+'');
      gcoms(g);
      gstmts(g, lastSon(n), c);
    end;
    nkElifBranch: begin
      optNL(g);
      putWithSpace(g, tkElif, 'elif');
      gsub(g, n.sons[0]);
      putWithSpace(g, tkColon, ':'+'');
      gcoms(g);
      gstmts(g, n.sons[1], c)
    end;
    nkElse: begin
      optNL(g);
      put(g, tkElse, 'else');
      putWithSpace(g, tkColon, ':'+'');
      gcoms(g);
      gstmts(g, n.sons[0], c)
    end;
    nkFinally: begin
      optNL(g);
      put(g, tkFinally, 'finally');
      putWithSpace(g, tkColon, ':'+'');
      gcoms(g);
      gstmts(g, n.sons[0], c)
    end;
    nkExceptBranch: begin
      optNL(g);
      putWithSpace(g, tkExcept, 'except');
      gcomma(g, n, 0, -2);
      putWithSpace(g, tkColon, ':'+'');
      gcoms(g);
      gstmts(g, lastSon(n), c)
    end;
    nkGenericParams: begin
      put(g, tkBracketLe, '['+'');
      gcomma(g, n);
      put(g, tkBracketRi, ']'+'');
    end;
    nkFormalParams: begin
      put(g, tkParLe, '('+'');
      gcomma(g, n, 1);
      put(g, tkParRi, ')'+'');
      if n.sons[0] <> nil then begin
        putWithSpace(g, tkColon, ':'+'');
        gsub(g, n.sons[0]);
      end;
      // XXX: gcomma(g, n, 1, -2);
    end;
    nkTupleTy: begin
      put(g, tkTuple, 'tuple');
      put(g, tkBracketLe, '['+'');
      assert(n.sons[0].kind = nkIdentDefs);
      gcomma(g, n);
      put(g, tkBracketRi, ']'+'');
    end;
    else begin
      InternalError(n.info, 'rnimsyn.gsub(' +{&} nodeKindToStr[n.kind] +{&} ')')
    end
  end
end;

function renderTree(n: PNode; renderFlags: TRenderFlags = {@set}[]): string;
var
  g: TSrcGen;
begin
  initSrcGen(g, renderFlags);
  gsub(g, n);
  result := g.buf
end;

procedure renderModule(n: PNode; const filename: string;
                       renderFlags: TRenderFlags = {@set}[]);
var
  i: int;
  f: tTextFile;
  g: TSrcGen;
begin
  initSrcGen(g, renderFlags);
  for i := 0 to sonsLen(n)-1 do begin
    gsub(g, n.sons[i]);
    optNL(g);
    if n.sons[i] <> nil then
      case n.sons[i].kind of
        nkTypeSection, nkConstSection, nkVarSection, nkCommentStmt:
          putNL(g);
        else begin end
      end
  end;
  gcoms(g);
  if OpenFile(f, filename, fmWrite) then begin
    nimWrite(f, g.buf);
    nimCloseFile(f);
  end;
end;

procedure initTokRender(var r: TSrcGen; n: PNode;
                        renderFlags: TRenderFlags = {@set}[]);
begin
  initSrcGen(r, renderFlags);
  gsub(r, n);
end;

procedure getNextTok(var r: TSrcGen; var kind: TTokType; var literal: string);
var
  len: int;
begin
  if r.idx < length(r.tokens) then begin
    kind := r.tokens[r.idx].kind;
    len := r.tokens[r.idx].len;
    literal := ncopy(r.buf, r.pos+strStart, r.pos+strStart+len-1);
    inc(r.pos, len);
    inc(r.idx);
  end
  else
    kind := tkEof;
end;

end.
