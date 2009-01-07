//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit evals;

// This file implements the evaluator for Nimrod code.
// The evaluator is very slow, but simple. Since this
// is used mainly for evaluating macros and some other
// stuff at compile time, performance is not that
// important.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils, magicsys,
  lists, options, ast, astalgo, trees, treetab, nimsets,
  msgs, nos, condsyms, idents, rnimsyn, types, passes, semfold;

type
  PStackFrame = ^TStackFrame;
  TStackFrame = record
    mapping: TIdNodeTable; // mapping from symbols to nodes
    prc: PSym;        // current prc; proc that is evaluated
    call: PNode;
    next: PStackFrame;   // for stacking
    params: TNodeSeq;  // parameters passed to the proc
  end;
  
  TEvalContext = object(passes.TPassContext)
    module: PSym;
    tos: PStackFrame; // top of a tos tos
    lastException: PNode;
  end;
  PEvalContext = ^TEvalContext;

function newStackFrame(): PStackFrame;
procedure pushStackFrame(c: PEvalContext; t: PStackFrame);
procedure popStackFrame(c: PEvalContext);

function newEvalContext(module: PSym; const filename: string): PEvalContext;

function eval(c: PEvalContext; n: PNode): PNode; 
// eval never returns nil! This simplifies the code a lot and
// makes it faster too.

function evalPass(): TPass;

implementation

const
  evalMaxIterations = 10000000; // max iterations of all loops
  evalMaxRecDepth = 100000;     // max recursion depth for evaluation

var
  emptyNode: PNode;

function newStackFrame(): PStackFrame;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  initIdNodeTable(result.mapping);
{@emit result.params := @[];}
end;

function newEvalContext(module: PSym; const filename: string): PEvalContext;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.module := module;
end;

procedure pushStackFrame(c: PEvalContext; t: PStackFrame);
begin
  t.next := c.tos;
  c.tos := t;
end;

procedure popStackFrame(c: PEvalContext);
begin
  if (c.tos = nil) then InternalError('popStackFrame');
  c.tos := c.tos.next;
end;

function evalAux(c: PEvalContext; n: PNode): PNode; forward;

procedure stackTraceAux(x: PStackFrame);
begin
  if x <> nil then begin
    stackTraceAux(x.next);
    messageOut(format('file: $1, line: $2', [toFilename(x.call.info),
                    toString(toLineNumber(x.call.info))]));
  end
end;

procedure stackTrace(c: PEvalContext; n: PNode; msg: TMsgKind;
                     const arg: string = '');
begin
  messageOut('stack trace: (most recent call last)');
  stackTraceAux(c.tos);
  liMessage(n.info, msg, arg);
end;

function evalIf(c: PEvalContext; n: PNode): PNode;
var
  i, len: int;
begin
  i := 0;
  len := sonsLen(n);
  while (i < len) and (sonsLen(n.sons[i]) >= 2) do begin
    result := evalAux(c, n.sons[i].sons[0]);
    if result.kind = nkExceptBranch then exit;
    if (result.kind = nkIntLit) and (result.intVal <> 0) then begin
      result := evalAux(c, n.sons[i].sons[1]);
      exit
    end;
    inc(i)
  end;
  if (i < len) and (sonsLen(n.sons[i]) < 2) then // eval else-part
    result := evalAux(c, n.sons[i].sons[0])
  else
    result := emptyNode
end;

function evalCase(c: PEvalContext; n: PNode): PNode;
var
  i, j: int;
  res: PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  res := result;
  result := emptyNode;
  for i := 1 to sonsLen(n)-1 do begin
    if n.sons[i].kind = nkOfBranch then begin
      for j := 0 to sonsLen(n.sons[i])-2 do begin
        if overlap(res, n.sons[i].sons[j]) then begin
          result := evalAux(c, lastSon(n.sons[i]));
          exit
        end
      end
    end
    else begin
      result := evalAux(c, lastSon(n.sons[i]));
    end
  end;
end;

var
  gWhileCounter: int;  // Use a counter to prevend endless loops!
                       // We make this counter global, because otherwise
                       // nested loops could make the compiler extremely slow.
  gNestedEvals: int;   // count the recursive calls to ``evalAux`` to prevent
                       // endless recursion

function evalWhile(c: PEvalContext; n: PNode): PNode;
begin
  while true do begin
    result := evalAux(c, n.sons[0]);
    if result.kind = nkExceptBranch then exit;
    if getOrdValue(result) = 0 then break;
    result := evalAux(c, n.sons[1]);
    case result.kind of
      nkBreakStmt: begin
        if result.sons[0] = nil then begin
          result := emptyNode; // consume ``break`` token
          break
        end
      end;
      nkExceptBranch, nkReturnToken: break;
      else begin end
    end;
    dec(gWhileCounter);
    if gWhileCounter <= 0 then begin
      stackTrace(c, n, errTooManyIterations);
      break;
    end
  end
end;

function evalBlock(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkBreakStmt then begin
    if result.sons[0] <> nil then begin
      assert(result.sons[0].kind = nkSym);
      if n.sons[0] <> nil then begin
        assert(n.sons[0].kind = nkSym);
        if result.sons[0].sym.id = n.sons[0].sym.id then
          result := emptyNode
      end
    end
    else
      result := emptyNode // consume ``break`` token
  end
end;

function evalFinally(c: PEvalContext; n, exc: PNode): PNode;
var
  finallyNode: PNode;
begin
  finallyNode := lastSon(n);
  if finallyNode.kind = nkFinally then begin
    result := evalAux(c, finallyNode);
    if result.kind <> nkExceptBranch then
      result := exc
  end
  else
    result := exc
end;

function evalTry(c: PEvalContext; n: PNode): PNode;
var
  exc: PNode;
  i, j, len, blen: int;
begin
  result := evalAux(c, n.sons[0]);
  case result.kind of
    nkBreakStmt, nkReturnToken: begin end;
    nkExceptBranch: begin
      // exception token!
      exc := result;
      i := 1;
      len := sonsLen(n);
      while (i < len) and (n.sons[i].kind = nkExceptBranch) do begin
        blen := sonsLen(n.sons[i]);
        if blen = 1 then begin
          // general except section:
          result := evalAux(c, n.sons[i].sons[0]);
          exc := result;
          break
        end
        else begin
          for j := 0 to blen-2 do begin
            assert(n.sons[i].sons[j].kind = nkType);
            if exc.typ.id = n.sons[i].sons[j].typ.id then begin
              result := evalAux(c, n.sons[i].sons[blen-1]);
              exc := result;
              break
            end
          end
        end;
        inc(i);
      end;
      result := evalFinally(c, n, exc);
    end;
    else
      result := evalFinally(c, n, emptyNode);
  end
end;

function getNullValue(typ: PType; const info: TLineInfo): PNode;
var
  i: int;
  t: PType;
begin
  t := skipGenericRange(typ);
  result := emptyNode;
  case t.kind of
    tyBool, tyChar, tyInt..tyInt64: result := newNodeIT(nkIntLit, info, t);
    tyFloat..tyFloat128: result := newNodeIt(nkFloatLit, info, t);
    tyVar, tyPointer, tyPtr, tyRef, tyCString, tySequence, tyString:
      result := newNodeIT(nkNilLit, info, t);
    tyObject: begin
      result := newNodeIT(nkPar, info, t);
      internalError(info, 'init to implement');
    end;
    tyArray, tyArrayConstr: begin
      result := newNodeIT(nkBracket, info, t);
      for i := 0 to int(lengthOrd(t))-1 do
        addSon(result, getNullValue(elemType(t), info));
    end;
    tyTuple: begin
      result := newNodeIT(nkPar, info, t);
      for i := 0 to sonsLen(t)-1 do
        addSon(result, getNullValue(t.sons[i], info));
    end;
    else InternalError('getNullValue')
  end
end;

function evalVar(c: PEvalContext; n: PNode): PNode;
var
  i: int;
  v: PSym;
  a: PNode;
begin
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkIdentDefs);
    assert(a.sons[0].kind = nkSym);
    v := a.sons[0].sym;
    if a.sons[2] <> nil then begin
      result := evalAux(c, a.sons[2]);
      if result.kind = nkExceptBranch then exit;
    end
    else
      result := getNullValue(a.sons[0].typ, a.sons[0].info);
    IdNodeTablePut(c.tos.mapping, v, result);
  end;
  result := emptyNode;
end;

function evalCall(c: PEvalContext; n: PNode): PNode;
var
  d: PStackFrame;
  prc: PNode;
  i: int;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  prc := result;
  // bind the actual params to the local parameter
  // of a new binding
  d := newStackFrame();
  d.call := n;
  if prc.kind = nkSym then begin
    d.prc := prc.sym;
    if not (prc.sym.kind in [skProc, skConverter]) then
      InternalError(n.info, 'evalCall');
  end;
  setLength(d.params, sonsLen(n));
  for i := 1 to sonsLen(n)-1 do begin
    result := evalAux(c, n.sons[i]);
    if result.kind = nkExceptBranch then exit;
    d.params[i] := result;
  end;
  if n.typ <> nil then d.params[0] := getNullValue(n.typ, n.info);
  pushStackFrame(c, d);
  result := evalAux(c, prc);
  if n.typ <> nil then result := d.params[0];
  popStackFrame(c);
end;

function evalVariable(c: PStackFrame; sym: PSym): PNode;
// We need to return a node to the actual value,
// which can be modified.
var
  x: PStackFrame;
begin
  x := c;
  while x <> nil do begin
    if sfResult in sym.flags then begin
      result := x.params[0];
      exit
    end;
    result := IdNodeTableGet(x.mapping, sym);
    if result <> nil then exit;
    x := x.next
  end;
  result := emptyNode;
end;

function evalArrayAccess(c: PEvalContext; n: PNode): PNode;
var
  x: PNode;
  idx: biggestInt;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  x := result;
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  idx := getOrdValue(result);
  result := emptyNode;
  case x.kind of
    nkBracket, nkPar, nkMetaNode: begin
      if (idx >= 0) and (idx < sonsLen(x)) then
        result := x.sons[int(idx)]
      else
        stackTrace(c, n, errIndexOutOfBounds);
    end;
    nkStrLit..nkTripleStrLit: begin
      result := newNodeIT(nkCharLit, x.info, getSysType(tyChar));
      if (idx >= 0) and (idx < length(x.strVal)) then
        result.intVal := ord(x.strVal[int(idx)+strStart])
      else if idx = length(x.strVal) then begin end
      else
        stackTrace(c, n, errIndexOutOfBounds);
    end;
    else
      stackTrace(c, n, errIndexNoIntType);
  end
end;

function evalFieldAccess(c: PEvalContext; n: PNode): PNode;
// a real field access; proc calls have already been
// transformed
// XXX: field checks!
var
  x: PNode;
  field: PSym;
  i: int;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  x := result;
  if x.kind <> nkPar then InternalError(n.info, 'evalFieldAccess');
  field := n.sons[1].sym;
  for i := 0 to sonsLen(n)-1 do begin
    if x.sons[i].kind <> nkExprColonExpr then
      InternalError(n.info, 'evalFieldAccess');
    if x.sons[i].sons[0].sym.name.id = field.id then begin
      result := x.sons[i].sons[1]; exit
    end
  end;
  stackTrace(c, n, errFieldXNotFound, field.name.s);
  result := emptyNode;
end;

function evalAsgn(c: PEvalContext; n: PNode): PNode;
var
  x: PNode;
  i: int;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  x := result;
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  x.kind := result.kind;
  x.typ := result.typ;
  case x.kind of
    nkCharLit..nkInt64Lit: x.intVal := result.intVal;
    nkFloatLit..nkFloat64Lit: x.floatVal := result.floatVal;
    nkStrLit..nkTripleStrLit: begin
      x.strVal := result.strVal;
    end
    else begin
      if not (x.kind in [nkEmpty..nkNilLit]) then begin
        discardSons(x);
        for i := 0 to sonsLen(result)-1 do addSon(x, result.sons[i]);
      end
    end
  end;
  result := emptyNode
end;

function evalSwap(c: PEvalContext; n: PNode): PNode;
var
  x: PNode;
  i: int;
  tmpi: biggestInt;
  tmpf: biggestFloat;
  tmps: string;
  tmpn: PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  x := result;
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  if (x.kind <> result.kind) then
    stackTrace(c, n, errCannotInterpretNodeX, nodeKindToStr[n.kind])
  else begin
    case x.kind of
      nkCharLit..nkInt64Lit: begin
        tmpi := x.intVal;
        x.intVal := result.intVal;
        result.intVal := tmpi
      end;
      nkFloatLit..nkFloat64Lit: begin
        tmpf := x.floatVal;
        x.floatVal := result.floatVal;
        result.floatVal := tmpf;
      end;
      nkStrLit..nkTripleStrLit: begin
        tmps := x.strVal;
        x.strVal := result.strVal;
        result.strVal := tmps;
      end
      else begin
        tmpn := copyTree(x);
        discardSons(x);
        for i := 0 to sonsLen(result)-1 do
          addSon(x, result.sons[i]);
        discardSons(result);
        for i := 0 to sonsLen(tmpn)-1 do
          addSon(result, tmpn.sons[i]);
      end
    end
  end;
  result := emptyNode
end;

function evalSym(c: PEvalContext; n: PNode): PNode;
begin
  case n.sym.kind of
    skProc, skConverter, skMacro: result := n.sym.ast.sons[codePos];
    skVar, skForVar, skTemp: result := evalVariable(c.tos, n.sym);
    skParam: result := c.tos.params[n.sym.position+1];
    skConst: result := n.sym.ast;
    else begin
      stackTrace(c, n, errCannotInterpretNodeX, symKindToStr[n.sym.kind]);
      result := emptyNode
    end
  end;
  if result = nil then InternalError(n.info, 'evalSym: ' + n.sym.name.s);
end;

function evalIncDec(c: PEvalContext; n: PNode; sign: biggestInt): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  case a.kind of
    nkCharLit..nkInt64Lit: a.intval := a.intVal + sign * getOrdValue(b);
    else internalError(n.info, 'evalIncDec');
  end;
  result := emptyNode
end;

function evalExit(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  liMessage(n.info, hintQuitCalled);
  halt(int(getOrdValue(result)));
end;

function evalOr(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  if result.kind <> nkIntLit then InternalError(n.info, 'evalOr');
  if result.intVal = 0 then result := evalAux(c, n.sons[2])
end;

function evalAnd(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  if result.kind <> nkIntLit then InternalError(n.info, 'evalAnd');
  if result.intVal <> 0 then result := evalAux(c, n.sons[2])
end;

function evalNew(c: PEvalContext; n: PNode): PNode;
var
  t: PType;
begin
  t := skipVarGeneric(n.sons[1].typ);
  result := newNodeIT(nkRefTy, n.info, t);
  addSon(result, getNullValue(t.sons[0], n.info));
end;

function evalDeref(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  if result.kind <> nkRefTy then InternalError(n.info, 'evalDeref');
  result := result.sons[0];
end;

function evalAddr(c: PEvalContext; n: PNode): PNode;
var
  a: PNode;
  t: PType;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  if result.kind <> nkRefTy then InternalError(n.info, 'evalDeref');
  a := result;
  t := newType(tyPtr, c.module);
  addSon(t, a.typ);
  result := newNodeIT(nkRefTy, n.info, t);
  addSon(result, a);
end;

function evalConv(c: PEvalContext; n: PNode): PNode;
begin
  // hm, I cannot think of any conversions that need to be handled here...
  result := evalAux(c, n.sons[1]);
  result.typ := n.typ;
end;

function evalCheckedFieldAccess(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[0]);
end;

function evalUpConv(c: PEvalContext; n: PNode): PNode;
var
  dest, src: PType;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  dest := skipPtrsGeneric(n.typ);
  src := skipPtrsGeneric(result.typ);
  if inheritanceDiff(src, dest) > 0 then
    stackTrace(c, n, errInvalidConversionFromTypeX, typeToString(src));
end;

function evalRangeChck(c: PEvalContext; n: PNode): PNode;
var
  x, a, b: PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  x := result;
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;

  if leValueConv(a, x) and leValueConv(x, b) then begin
    result := x; // a <= x and x <= b
    result.typ := n.typ
  end
  else
    stackTrace(c, n, errGenerated,
      format(msgKindToString(errIllegalConvFromXtoY),
        [typeToString(n.sons[0].typ), typeToString(n.typ)]));
end;

function evalConvStrToCStr(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  result.typ := n.typ;
end;

function evalConvCStrToStr(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[0]);
  if result.kind = nkExceptBranch then exit;
  result.typ := n.typ;
end;

function evalRaise(c: PEvalContext; n: PNode): PNode;
var
  a: PNode;
begin
  if n.sons[0] <> nil then begin
    result := evalAux(c, n.sons[0]);
    if result.kind = nkExceptBranch then exit;
    a := result;
    result := newNodeIT(nkExceptBranch, n.info, a.typ);
    addSon(result, a);
    c.lastException := result;
  end
  else if c.lastException <> nil then
    result := c.lastException
  else begin
    stackTrace(c, n, errExceptionAlreadyHandled);
    result := newNodeIT(nkExceptBranch, n.info, nil);
    addSon(result, nil);
  end
end;

function evalReturn(c: PEvalContext; n: PNode): PNode;
begin
  if n.sons[0] <> nil then begin
    result := evalAsgn(c, n.sons[0]);
    if result.kind = nkExceptBranch then exit;
  end;
  result := newNodeIT(nkReturnToken, n.info, nil);
end;

function evalProc(c: PEvalContext; n: PNode): PNode;
var
  v: PSym;
begin
  if n.sons[genericParamsPos] = nil then begin
    if (resultPos < sonsLen(n)) and (n.sons[resultPos] <> nil) then begin
      v := n.sons[resultPos].sym;
      result := getNullValue(v.typ, n.info);
      IdNodeTablePut(c.tos.mapping, v, result);
    end;
    result := evalAux(c, n.sons[codePos]);
    if result.kind = nkReturnToken then
      result := IdNodeTableGet(c.tos.mapping, v);
  end
  else
    result := emptyNode
end;

function evalHigh(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  case skipVarGeneric(n.sons[1].typ).kind of
    tyOpenArray, tySequence:
      result := newIntNodeT(sonsLen(result), n);
    tyString:
      result := newIntNodeT(length(result.strVal)-1, n);
    else InternalError(n.info, 'evalHigh')
  end
end;

function evalIs(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  result := newIntNodeT(ord(inheritanceDiff(result.typ, n.sons[2].typ) >= 0), n)
end;

function evalSetLengthStr(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  case a.kind of
    nkStrLit..nkTripleStrLit: setLength(a.strVal, int(getOrdValue(b)));
    else InternalError(n.info, 'evalSetLengthStr')
  end;
  result := emptyNode
end;

function evalSetLengthSeq(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  if a.kind = nkBracket then setLength(a.sons, int(getOrdValue(b)))
  else InternalError(n.info, 'evalSetLengthSeq');
  result := emptyNode
end;

function evalNewSeq(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
  t: PType;
  i: int;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;

  t := skipVarGeneric(n.sons[1].typ);
  result := newNodeIT(nkBracket, n.info, t);
  for i := 0 to int(getOrdValue(b))-1 do
    addSon(result, getNullValue(t.sons[0], n.info));
  // XXX: assign to `a`? result := emptyNode
end;

function evalAssert(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  if getOrdValue(result) <> 0 then
    result := emptyNode
  else
    stackTrace(c, n, errAssertionFailed)
end;

function evalIncl(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  if not inSet(a, b) then addSon(a, copyTree(b));
  result := emptyNode;
end;

function evalExcl(c: PEvalContext; n: PNode): PNode;
var
  a, b, r: PNode;
  i: int;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := newNodeIT(nkCurly, n.info, n.sons[1].typ);
  addSon(b, result);
  r := diffSets(a, b);
  discardSons(a);
  for i := 0 to sonsLen(r)-1 do addSon(a, r.sons[i]);
  result := emptyNode;
end;

function evalAppendStrCh(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  case a.kind of
    nkStrLit..nkTripleStrLit: addChar(a.strVal, chr(int(getOrdValue(b))));
    else InternalError(n.info, 'evalAppendStrCh');
  end;
  result := emptyNode;
end;

function getStrValue(n: PNode): string;
begin
  case n.kind of
    nkStrLit..nkTripleStrLit: result := n.strVal;
    else begin InternalError(n.info, 'getStrValue'); result := '' end;
  end
end;

function evalConStrStr(c: PEvalContext; n: PNode): PNode;
// we cannot use ``evalOp`` for this as we can here have more than 2 arguments
var
  a: PNode;
  i: int;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  for i := 2 to sonsLen(n)-1 do begin
    result := evalAux(c, n.sons[i]);
    if result.kind = nkExceptBranch then exit;
    a.strVal := getStrValue(a) +{&} getStrValue(result);
  end;
  result := a;
end;

function evalAppendStrStr(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  case a.kind of
    nkStrLit..nkTripleStrLit: a.strVal := a.strVal +{&} getStrValue(b);
    else InternalError(n.info, 'evalAppendStrStr');
  end;
  result := emptyNode;
end;

function evalAppendSeqElem(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  if a.kind = nkBracket then addSon(a, copyTree(b))
  else InternalError(n.info, 'evalAppendSeqElem');
  result := emptyNode;
end;

function evalAppendSeqSeq(c: PEvalContext; n: PNode): PNode;
var
  a, b: PNode;
  i: int;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  a := result;
  result := evalAux(c, n.sons[2]);
  if result.kind = nkExceptBranch then exit;
  b := result;
  if a.kind = nkBracket then
    for i := 0 to sonsLen(b)-1 do addSon(a, copyTree(b.sons[i]))
  else InternalError(n.info, 'evalAppendSeqSeq');
  result := emptyNode;
end;

function evalRepr(c: PEvalContext; n: PNode): PNode;
begin
  result := evalAux(c, n.sons[1]);
  if result.kind = nkExceptBranch then exit;
  result := newStrNodeT(renderTree(result, {@set}[renderNoComments]), n);
end;

function evalMagicOrCall(c: PEvalContext; n: PNode): PNode;
var
  m: TMagic;
  a, b: PNode;
  k: biggestInt;
  i: int;
begin
  m := getMagic(n);
  case m of
    mNone: result := evalCall(c, n);
    mIs: result := evalIs(c, n);
    mSizeOf: internalError(n.info, 'sizeof() should have been evaluated');
    mHigh: result := evalHigh(c, n);
    mAssert: result := evalAssert(c, n);
    mExit: result := evalExit(c, n);
    mNew, mNewFinalize: result := evalNew(c, n);
    mNewSeq: result := evalNewSeq(c, n);
    mSwap: result := evalSwap(c, n);
    mInc: result := evalIncDec(c, n, 1);
    ast.mDec: result := evalIncDec(c, n, -1);
    mSetLengthStr: result := evalSetLengthStr(c, n);
    mSetLengthSeq: result := evalSetLengthSeq(c, n);
    mIncl: result := evalIncl(c, n);
    mExcl: result := evalExcl(c, n);
    mAnd: result := evalAnd(c, n);
    mOr: result := evalOr(c, n);

    mAppendStrCh: result := evalAppendStrCh(c, n);
    mAppendStrStr: result := evalAppendStrStr(c, n);
    mAppendSeqElem: result := evalAppendSeqElem(c, n);
    mAppendSeqSeq: result := evalAppendSeqSeq(c, n);

    mNLen: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := newNodeIT(nkIntLit, n.info, n.typ);
      case a.kind of
        nkEmpty..nkNilLit: begin end;
        else result.intVal := sonsLen(a);
      end
    end;
    mNChild: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      k := getOrdValue(result);
      if (k >= 0) and (k < sonsLen(a))
      and not (a.kind in [nkEmpty..nkNilLit]) then
        result := a.sons[int(k)]
      else begin
        stackTrace(c, n, errIndexOutOfBounds);
        result := emptyNode
      end;
    end;
    mNSetChild: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      b := result;
      result := evalAux(c, n.sons[3]);
      if result.kind = nkExceptBranch then exit;
      k := getOrdValue(b);
      if (k >= 0) and (k < sonsLen(a))
      and not (a.kind in [nkEmpty..nkNilLit]) then
        a.sons[int(k)] := result
      else
        stackTrace(c, n, errIndexOutOfBounds);
      result := emptyNode;
    end;
    mNAdd: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      addSon(a, result);
      result := emptyNode
    end;
    mNAddMultiple: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      for i := 0 to sonsLen(result)-1 do addSon(a, result.sons[i]);
      result := emptyNode
    end;
    mNDel: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      b := result;
      result := evalAux(c, n.sons[3]);
      if result.kind = nkExceptBranch then exit;
      for i := 0 to int(getOrdValue(result))-1 do
        delSon(a, int(getOrdValue(b)));
      result := emptyNode;
    end;
    mNKind: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := newNodeIT(nkIntLit, n.info, n.typ);
      result.intVal := ord(a.kind);
    end;
    mNIntVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := newNodeIT(nkIntLit, n.info, n.typ);
      case a.kind of
        nkCharLit..nkInt64Lit: result.intVal := a.intVal;
        else InternalError(n.info, 'no int value')
      end
    end;
    mNFloatVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := newNodeIT(nkFloatLit, n.info, n.typ);
      case a.kind of
        nkFloatLit..nkFloat64Lit: result.floatVal := a.floatVal;
        else InternalError(n.info, 'no float value')
      end
    end;
    mNSymbol: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      if result.kind <> nkSym then InternalError(n.info, 'no symbol')
    end;
    mNIdent: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      if result.kind <> nkIdent then InternalError(n.info, 'no symbol')
    end;
    mNGetType: result := evalAux(c, n.sons[1]);
    mNStrVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := newNodeIT(nkStrLit, n.info, n.typ);
      case a.kind of
        nkStrLit..nkTripleStrLit: result.strVal := a.strVal;
        else InternalError(n.info, 'no string value')
      end
    end;
    mNSetIntVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.intVal := result.intVal; // XXX: exception handling?
      result := emptyNode
    end;
    mNSetFloatVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.floatVal := result.floatVal; // XXX: exception handling?
      result := emptyNode
    end;
    mNSetSymbol: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.sym := result.sym; // XXX: exception handling?
      result := emptyNode
    end;
    mNSetIdent: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.ident := result.ident; // XXX: exception handling?
      result := emptyNode
    end;
    mNSetType: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.typ := result.typ; // XXX: exception handling?
      result := emptyNode
    end;
    mNSetStrVal: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a.strVal := result.strVal; // XXX: exception handling?
      result := emptyNode
    end;
    mNNewNimNode: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      k := getOrdValue(result);
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      if (k < 0) or (k > ord(high(TNodeKind))) then
        internalError(n.info, 'request to create a NimNode with invalid kind');
      if a.kind = nkNilLit then
        result := newNodeI(TNodeKind(int(k)), n.info)
      else
        result := newNodeI(TNodeKind(int(k)), a.info)
    end;
    mNCopyNimNode: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      result := copyNode(result);
    end;
    mNCopyNimTree: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      result := copyTree(result);
    end;
    mStrToIdent: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      if not (result.kind in [nkStrLit..nkTripleStrLit]) then
        InternalError(n.info, 'no string node');
      a := result;
      result := newNodeIT(nkIdent, n.info, n.typ);
      result.ident := getIdent(a.strVal);
    end;
    mIdentToStr: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      if result.kind <> nkIdent then
        InternalError(n.info, 'no ident node');
      a := result;
      result := newNodeIT(nkStrLit, n.info, n.typ);
      result.strVal := a.ident.s;
    end;
    mEqIdent: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      result := evalAux(c, n.sons[2]);
      if result.kind = nkExceptBranch then exit;
      b := result;
      result := newNodeIT(nkIntLit, n.info, n.typ);
      if (a.kind = nkIdent) and (b.kind = nkIdent) then
        if a.ident.id = b.ident.id then result.intVal := 1
    end;
    mNHint: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      liMessage(n.info, hintUser, getStrValue(result));
      result := emptyNode
    end;
    mNWarning: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      liMessage(n.info, warnUser, getStrValue(result));
      result := emptyNode
    end;
    mNError: begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      liMessage(n.info, errUser, getStrValue(result));
      result := emptyNode
    end;
    mConStrStr: result := evalConStrStr(c, n);
    mRepr: result := evalRepr(c, n);
    else begin
      result := evalAux(c, n.sons[1]);
      if result.kind = nkExceptBranch then exit;
      a := result;
      if sonsLen(n) > 2 then begin
        result := evalAux(c, n.sons[2]);
        if result.kind = nkExceptBranch then exit;
      end
      else
        result := nil;
      result := evalOp(m, n, a, result);
    end
  end
end;

function evalAux(c: PEvalContext; n: PNode): PNode;
var
  i: int;
begin
  result := emptyNode;
  dec(gNestedEvals);
  if gNestedEvals <= 0 then stackTrace(c, n, errTooManyIterations);
  case n.kind of // atoms:
    nkEmpty: result := n;
    nkSym: result := evalSym(c, n);
    nkType..pred(nkNilLit): result := copyNode(n);
    nkNilLit: result := n; // end of atoms

    nkCall, nkHiddenCallConv, nkMacroStmt: result := evalMagicOrCall(c, n);
    nkCurly, nkBracket: begin
      result := copyNode(n);
      for i := 0 to sonsLen(n)-1 do addSon(result, evalAux(c, n.sons[i]));
    end;
    nkPar: begin
      result := copyTree(n);
      for i := 0 to sonsLen(n)-1 do
        result.sons[i].sons[1] := evalAux(c, n.sons[i].sons[1]);
    end;
    nkBracketExpr: result := evalArrayAccess(c, n);
    nkDotExpr: result := evalFieldAccess(c, n);
    nkDerefExpr, nkHiddenDeref: result := evalDeref(c, n);
    nkAddr, nkHiddenAddr: result := evalAddr(c, n);
    nkHiddenStdConv, nkHiddenSubConv, nkConv: result := evalConv(c, n);
    nkAsgn, nkFastAsgn: result := evalAsgn(c, n);
    nkWhenStmt, nkIfStmt, nkIfExpr: result := evalIf(c, n);
    nkWhileStmt: result := evalWhile(c, n);
    nkCaseStmt: result := evalCase(c, n);
    nkVarSection: result := evalVar(c, n);
    nkTryStmt: result := evalTry(c, n);
    nkRaiseStmt: result := evalRaise(c, n);
    nkReturnStmt: result := evalReturn(c, n);
    nkBreakStmt, nkReturnToken: result := n;
    nkBlockExpr, nkBlockStmt: result := evalBlock(c, n);
    nkDiscardStmt: result := evalAux(c, n.sons[0]);
    nkCheckedFieldExpr: result := evalCheckedFieldAccess(c, n);
    nkObjDownConv: result := evalAux(c, n.sons[0]);
    nkObjUpConv: result := evalUpConv(c, n);
    nkChckRangeF, nkChckRange64, nkChckRange: result := evalRangeChck(c, n);
    nkStringToCString: result := evalConvStrToCStr(c, n);
    nkCStringToString: result := evalConvCStrToStr(c, n);
    nkPassAsOpenArray: result := evalAux(c, n.sons[0]);

    nkStmtListExpr, nkStmtList, nkModule: begin
      for i := 0 to sonsLen(n)-1 do begin
        result := evalAux(c, n.sons[i]);
        case result.kind of
          nkExceptBranch, nkReturnToken, nkBreakStmt: break;
          else begin end
        end
      end
    end;
    nkProcDef, nkMacroDef, nkCommentStmt, nkPragma, nkTypeSection,
    nkTemplateDef, nkConstSection, nkIteratorDef, nkConverterDef,
    nkIncludeStmt, nkImportStmt, nkFromStmt: begin end;
    nkIdentDefs, nkCast, nkYieldStmt, nkAsmStmt, nkForStmt, nkPragmaExpr,
    nkQualified, nkLambda, nkContinueStmt, nkIdent:
      stackTrace(c, n, errCannotInterpretNodeX, nodeKindToStr[n.kind]);
    else InternalError(n.info, 'evalAux: ' + nodekindToStr[n.kind]);
  end;
  if result = nil then
    InternalError(n.info, 'evalAux: returned nil ' + nodekindToStr[n.kind]);
  inc(gNestedEvals);
end;

function eval(c: PEvalContext; n: PNode): PNode;
begin
  gWhileCounter := evalMaxIterations;
  gNestedEvals := evalMaxRecDepth;
  result := evalAux(c, n);
  if result.kind = nkExceptBranch then
    stackTrace(c, n, errUnhandledExceptionX, typeToString(result.typ));
end;

function myOpen(module: PSym; const filename: string): PPassContext;
var
  c: PEvalContext;
begin
  c := newEvalContext(module, filename);
  pushStackFrame(c, newStackFrame());
  result := c;
end;

function myProcess(c: PPassContext; n: PNode): PNode;
begin
  result := eval(PEvalContext(c), n);
end;

function evalPass(): TPass;
begin
  initPass(result);
  result.open := myOpen;
  result.close := myProcess;
  result.process := myProcess;
end;

initialization
  new(emptyNode);
{@ignore}
  fillChar(emptyNode^, sizeof(emptyNode^), 0);
{@emit}
  emptyNode.kind := nkEmpty;
end.
