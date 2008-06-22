//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This file implements the evaluator for Nimrod code.
// The evaluator is very slow, but simple. Since this
// is used mainly for evaluating macros and some other
// stuff at compile time, performance is not that
// important. Later a real interpreter may get out of this...

type
  PBinding = ^TBinding;
  TBinding = record
    up: PBinding; // call stack
    tab: TIdNodeTable; // maps syms to nodes
    procname: PIdent;
    info: TLineInfo;
  end;

var
  emptyNode: PNode;
  
procedure stackTraceAux(x: PBinding);
begin
  if x <> nil then begin
    stackTraceAux(x.up);
    messageOut(format('$1 called at line $2 file $3',
                      [x.procname.s, toLinenumber(info), ToFilename(info)]));
  end
end;

procedure stackTrace(c: PBinding; n: PNode; msg: TMsgKind;
                     const arg: string = '');
var
  x: PBinding;
begin
  x := c;
  messageOut('stack trace: (most recent call last)') 
  stackTraceAux(c);
  liMessage(n.info, msg, arg);
end;

function eval(c: PBinding; n: PNode): PNode; forward;
// eval never returns nil! This simplifies the code a lot and
// makes it faster too.

function evalSym(c: PBinding; sym: PSym): PNode;
// We need to return a node to the actual value,
// which can be modified.
var
  x: PBinding;
begin
  x := c;
  while x <> nil do begin
    result := IdNodeTableGet(x.tab, sym);
    if result <> nil then exit;
    x := x.up
  end;
  result := emptyNode;
end;

function evalIf(c: PBinding; n: PNode): PNode;
var
  i: int;
  res: PNode;
begin
  i := 0;
  len := sonsLen(n);
  while (i < len) and (sonsLen(n.sons[i]) >= 2) do begin
    res := eval(c, n.sons[i].sons[0]);
    if (res.kind = nkIntLit) and (res.intVal <> 0) then begin
      result := eval(c, n.sons[i].sons[1]); exit
    end;
    inc(i)
  end;
  if (i < len) and (sonsLen(n.sons[i]) < 2) then // eval else-part
    result := eval(c, n.sons[0])
  else
    result := emptyNode
end;

var 
  gWhileCounter: int;  // Use a counter to prevend endless loops!
                       // We make this counter global, because otherwise
                       // nested loops could make the compiler extremely slow.

function evalWhile(c: PBinding; n: PNode): PNode;
var
  res: PNode;
begin
  result := emptyNode;
  while true do begin
    res := eval(c, n.sons[0]);
    if getOrdValue(res) = 0 then break;
    result := eval(c, n.sons[1]);
    inc(gWhileCounter);
    if gWhileCounter > 10000000 then begin
      stackTrace(c, n, errTooManyIterations);
      break;
    end
  end
end;

function evalCall(c: PBinding; n: PNode): PNode;
var
  d: PBinding;
  prc: PNode;
  op: PSym
begin
  prc := eval(c, n.sons[0]);
  assert(prc.kind = nkSym);
  assert(prc.sym.kind in [skIterator, skProc, skConverter]);
  op := prc.sym;
  // bind the actual params to the local parameter
  // of a new binding
  d := newBinding(c, n.info);
  for i := 0 to sonsLen(op.typ.n)-1 do
    addSym(d.tab, op.typ.n.sons[i].sym, n.sons[i+1]);
  result := eval(d, op.ast[codePos]);
end;

function evalAsgn(c: PBinding; n: PNode): PNode;
var
  x, y: PNode;
begin
  x := eval(c, n.sons[0]);
  y := eval(c, n.sons[1]);
  if (x.kind <> y.kind) then
    stackTrace(c, n, errInvalidAsgn)
  else begin
    case x.kind of
      nkCharLit..nkInt64Lit: x.intVal := y.intVal;
      nkFloatLit..nkFloat64Lit: x.floatVal := y.floatVal;
      nkStrLit..nkTripleStrLit: x.strVal := y.strVal;
      else begin
        discardSons(x);
        for i := 0 to sonsLen(y)-1 do
          addSon(x, y.sons[i]);
      end
    end
  end;
  result := y
end;

function evalArrayAccess(c: PBinding; n: PNode): PNode;
var
  x: PNode;
  idx: biggestInt;
begin
  x := eval(c, n.sons[0]);
  idx := getOrdValue(eval(c, n.sons[1]));
  result := emptyNode;
  case x.kind of 
    nkArrayConstr, nkPar: begin
      if (idx >= 0) and (idx < sonsLen(x)) then
        result := x.sons[indx]
      else
        stackTrace(c, n, errInvalidIndex);
    end;
    nkStrLit..nkTripleStrLit: begin
      if (idx >= 0) and (idx < length(x.strLit)) then
        result := newCharNode(x.strLit[indx+strStart])
      else if idx = length(x.strLit) then
        result := newCharNode(#0)
      else
        stackTrace(c, n, errInvalidIndex);
    end
    else
      stackTrace(c, n, errInvalidOp);
  end
end;

function evalFieldAccess(c: PBinding; n: PNode): PNode;
// a real field access; proc calls have already been
// transformed
var
  x: PNode;
  field: PSym;
begin
  x := eval(c, n.sons[0]);
  field := n.sons[1].sym;
  for i := 0 to sonsLen(n)-1 do
    if x.sons[i].sons[0].sym.name.id = field.id then begin
      result := x.sons[i].sons[1]; exit
    end;
  stackTrace(c, n, errFieldNotFound, field.name.s);
  result := emptyNode;
end;

function eval(c: PBinding; n: PNode): PNode;
var
  m: TMagic;
  b: PNode;
  i: int;
begin
  case n.kind of // atoms:
    nkEmpty: result := n; // do not produce further error messages!
    nkSym: result := evalSym(c, n.sym);
    nkType..pred(nkNilLit): result := copyNode(n);
    nkNilLit: result := n; // end of atoms

    nkCall: begin
      m := getMagic(n);
      case m of
        mNone: result := evalCall(b, n);
        mSizeOf: internalError(n.info, 'sizeof() should have been evaluated');
        mHigh: begin end;
        mLow: begin end;
        else begin
          if sonsLen(n) > 2 then b := eval(c, n.sons[2])
          else b := nil;
          result := evalOp(m, n, eval(c, n.sons[1]), b);
        end
      end
    end;
    nkIdentDefs: begin end;

    nkPar: begin
      // tuple constructor, already in the right format
      result := copyTree(n)
    end;
    nkCurly, nkBracket: result := copyTree(n);
    nkBracketExpr:begin end;
    nkPragmaExpr:begin end;
    nkRange:begin end;
    nkDotExpr:begin end;
    nkDerefExpr:begin end;
    nkIfExpr:begin end;
    nkElifExpr:begin end;
    nkElseExpr:begin end;
    nkLambda:begin end;

    nkSetConstr:begin end;
    nkConstSetConstr:begin end;
    nkArrayConstr:begin end;
    nkConstArrayConstr:begin end;
    nkRecordConstr:begin end;
    nkConstRecordConstr:begin end;
    nkTableConstr:begin end;
    nkConstTableConstr:begin end;
    nkQualified:begin end;
    nkImplicitConv, nkConv: result := evalConv(c, n);
    nkCast: result := evalCast(c, n); // this is hard!
    nkAsgn: result := evalAsgn(c, n);
    nkDefaultTypeParam:begin end;
    nkGenericParams:begin end;
    nkFormalParams:begin end;
    nkOfInherit:begin end;
    nkOfBranch: begin end;
    nkElifBranch: begin end;
    nkExceptBranch: begin end;
    nkElse: begin end;
    nkMacroStmt: begin end;
    nkAsmStmt: begin end;
    nkPragma: begin end;
    nkIfStmt: begin end;
    nkWhenStmt: begin end;
    nkForStmt: begin end;
    nkWhileStmt: begin end;
    nkCaseStmt: begin end;
    nkVarSection: begin end;
    nkConstSection, nkConstDef, nkTypeDef, nkTypeSection, nkProcDef,
    nkConverterDef, nkMacroDef, nkTemplateDef, nkIteratorDef:
      result := emptyNode;
    nkYieldStmt: begin end;
    nkTryStmt: begin end;
    nkFinally: begin end;
    nkRaiseStmt: begin end;
    nkReturnStmt: begin end;
    nkBreakStmt: begin end;
    nkContinueStmt: begin end;
    nkBlockStmt: begin end;
    nkDiscardStmt: begin end;
    nkStmtList, nkModule: begin 
      for i := 0 to sonsLen(n)-1 do 
        result := eval(c, n.sons[i]);
    end;
    //nkImportStmt: begin end;
    //nkFromStmt: begin end;
    //nkImportAs: begin end;
    //nkIncludeStmt: begin end;
    nkCommentStmt: result := emptyNode; // do nothing
    else
      stackTrace(c, n, errCannotInterpretNode);
  end
end;
