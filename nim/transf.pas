//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module implements the transformator. It transforms the syntax tree
// to ease the work of the code generators. Does some transformations:
//
// * inlines iterators
// * looks up constants
// * transforms lambdas and makes closures explicit
// * transforms `&`(a, `&` (b, c)) to `&`(a, b, c)
// * generates type information

// ------------ helpers -----------------------------------------------------

var
  gTmpId: int;

function newTemp(c: PContext; typ: PType; const info: TLineInfo): PSym;
begin
  inc(gTmpId);
  result := newSym(skTemp, getIdent(genPrefix +{&} ToString(gTmpId)),
                   c.transCon.owner);
  result.info := info;
  result.typ := typ;
end;

// --------------------------------------------------------------------------

(*

Transforming iterators into non-inlined versions is pretty hard, but
unavoidable for not bloating the code too much. If we had direct access to
the program counter, things'd be much easier.
::

  iterator items(a: string): char =
    var i = 0
    while i < length(a):
      yield a[i]
      inc(i)

  for ch in items("hello world"): # `ch` is an iteration variable
    echo(ch)

Should be transformed into::

  type
    TItemsClosure = record
      i: int
      state: int
  proc items(a: string, c: var TItemsClosure): char =
    case c.state
    of 0: goto L0 # very difficult without goto!
    of 1: goto L1 # can be implemented by GCC's computed gotos

    block L0:
      c.i = 0
      while c.i < length(a):
        c.state = 1
        return a[i]
        block L1: inc(c.i)

More efficient, but not implementable:

  type
    TItemsClosure = record
      i: int
      pc: pointer

  proc items(a: string, c: var TItemsClosure): char =
    goto c.pc
    c.i = 0
    while c.i < length(a):
      c.pc = label1
      return a[i]
      label1: inc(c.i)
*)


function transform(c: PContext; n: PNode): PNode; forward;

function newAsgnStmt(c: PContext; le, ri: PNode): PNode;
begin
  result := newNodeI(nkAsgn, ri.info);
  addSon(result, le);
  addSon(result, ri);
end;

function transformSym(c: PContext; n: PNode): PNode;
var
  tc: PTransCon;
begin
  assert(n.kind = nkSym);
  tc := c.transCon;
  //writeln('transformSym', n.sym.id : 5);
  while tc <> nil do begin
    result := IdNodeTableGet(tc.mapping, n.sym);
    if result <> nil then exit;
    //write('not found in: ');
    //writeIdNodeTable(tc.mapping);
    tc := tc.next
  end;
  if (n.sym.kind = skConst) and not (n.sym.typ.kind in ConstantDataTypes) then begin
    result := getConstExpr(c, n);
    assert(result <> nil);
  end
  else
    result := n;
end;

procedure transformContinueAux(c: PContext; n: PNode; labl: PSym; 
                               var counter: int);
var
  i: int;
begin
  if n = nil then exit;
  case n.kind of
    nkEmpty..nkNilLit, nkForStmt, nkWhileStmt: begin end;
    nkContinueStmt: begin
      n.kind := nkBreakStmt;
      addSon(n, newSymNode(labl));
      inc(counter);
    end;
    else begin
      for i := 0 to sonsLen(n)-1 do 
        transformContinueAux(c, n.sons[i], labl, counter);
    end
  end
end;

function transformContinue(c: PContext; n: PNode): PNode;
// we transform the continue statement into a block statement
var 
  i, counter: int;
  x: PNode;
  labl: PSym;
begin
  result := n;
  for i := 0 to sonsLen(n)-1 do
    result.sons[i] := transform(c, n.sons[i]);
  counter := 0;
  inc(gTmpId);
  labl := newSym(skLabel, getIdent(genPrefix +{&} ToString(gTmpId)),
                 getCurrOwner(c));
  labl.info := result.info;
  transformContinueAux(c, result, labl, counter);
  if counter > 0 then begin
    x := newNodeI(nkBlockStmt, result.info); 
    addSon(x, newSymNode(labl));
    addSon(x, result);
    result := x
  end
end;

function transformYield(c: PContext; n: PNode): PNode;
var
  e: PNode;
  i: int;
begin
  result := newNodeI(nkStmtList, n.info);
  e := n.sons[0];
  if e.typ.kind = tyTuple then begin
    if e.kind = nkPar then begin
      for i := 0 to sonsLen(e)-1 do begin
        addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[i],
               transform(c, copyTree(e.sons[i]))));
      end
    end
    else begin
      // XXX: tuple unpacking:
      internalError(n.info, 'tuple unpacking is not implemented');
    end
  end
  else begin
    e := transform(c, copyTree(e));
    addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[0], e));
  end;
  // add body of the for loop:
  addSon(result, transform(c, lastSon(c.transCon.forStmt)));
end;

function inlineIter(c: PContext; n: PNode): PNode;
var
  i: int;
  it: PNode;
  newVar: PSym;
begin
  result := n;
  if n = nil then exit;
  case n.kind of
    nkEmpty..nkNilLit: begin
      result := transform(c, copyTree(n));
    end;
    nkYieldStmt: result := transformYield(c, n);
    nkVarSection: begin
      result := copyTree(n);
      for i := 0 to sonsLen(result)-1 do begin
        it := result.sons[i];
        assert(it.kind = nkIdentDefs);
        assert(it.sons[0].kind = nkSym);
        if it.sons[0].sym.kind <> skTemp then begin
          newVar := copySym(it.sons[0].sym, getCurrOwner(c));
          IdNodeTablePut(c.transCon.mapping, it.sons[0].sym,
                         newSymNode(newVar));
          it.sons[0] := newSymNode(newVar);
        end;
        it.sons[2] := transform(c, it.sons[2]);
        //writeIdNodeTable(c.transCon.mapping);
      end
    end
    else begin
      result := copyNode(n);
      for i := 0 to sonsLen(n)-1 do addSon(result, inlineIter(c, n.sons[i]));
      result := transform(c, result);
    end
  end
end;

procedure addVar(father, v: PNode);
var
  vpart: PNode;
begin
  vpart := newNodeI(nkIdentDefs, v.info);
  addSon(vpart, v);
  addSon(vpart, nil);
  addSon(vpart, nil);
  addSon(father, vpart);
end;

function transformFor(c: PContext; n: PNode): PNode;
// generate access statements for the parameters (unless they are constant)
// put mapping from formal parameters to actual parameters
var
  i, len: int;
  call, e, v, body: PNode;
  newC: PTransCon;
  temp, formal: PSym;
begin
  assert(n.kind = nkForStmt);
  result := newNodeI(nkStmtList, n.info);
  len := sonsLen(n);
  n.sons[len-1] := transformContinue(c, n.sons[len-1]);
  v := newNodeI(nkVarSection, n.info);
  for i := 0 to len-3 do
    addVar(v, copyTree(n.sons[i])); // declare new variables
  addSon(result, v);
  newC := newTransCon();
  call := n.sons[len-2];
  assert(call.kind = nkCall);
  assert(call.sons[0].kind = nkSym);
  newC.owner := call.sons[0].sym;
  newC.forStmt := n;
  assert(newC.owner.kind = skIterator);
  // generate access statements for the parameters (unless they are constant)
  pushTransCon(c, newC);
  for i := 1 to sonsLen(call)-1 do begin
    e := getConstExpr(c, call.sons[i]);
    formal := newC.owner.typ.n.sons[i].sym;
    if e <> nil then
      IdNodeTablePut(newC.mapping, formal, e)
    else if (call.sons[i].kind = nkSym) then begin
      // since parameters cannot be modified, we can identify the formal and
      // the actual params
      IdNodeTablePut(newC.mapping, formal, call.sons[i]);
    end
    else begin
      // generate a temporary and produce an assignment statement:
      temp := newTemp(c, formal.typ, formal.info);
      addVar(v, newSymNode(temp));
      addSon(result, newAsgnStmt(c, newSymNode(temp), copyTree(call.sons[i])));
      IdNodeTablePut(newC.mapping, formal, newSymNode(temp)); // BUGFIX
    end
  end;
  body := newC.owner.ast.sons[codePos];
  //writeln(renderTree(body, {@set}[renderIds]));
  addSon(result, inlineIter(c, body));
  popTransCon(c);
end;

function getMagicOp(call: PNode): TMagic;
begin
  if (call.sons[0].kind = nkSym) and (call.sons[0].sym.kind = skProc) then
    result := call.sons[0].sym.magic
  else
    result := mNone
end;

procedure gatherVars(c: PContext; n: PNode; var marked: TIntSet;
                     owner: PSym; container: PNode);
// gather used vars for closure generation
var
  i: int;
  s: PSym;
  found: bool;
begin
  if n = nil then exit;
  case n.kind of
    nkSym: begin
      s := n.sym;
      found := false;
      case s.kind of
        skVar: found := not (sfGlobal in s.flags);
        skTemp, skForVar, skParam: found := true;
        else begin end;
      end;
      if found and (owner.id <> s.owner.id)
      and not IntSetContainsOrIncl(marked, s.id) then begin
        include(s.flags, sfInClosure);
        addSon(container, copyNode(n)); // DON'T make a copy of the symbol!
      end
    end;
    nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: begin end;
    else begin
      for i := 0 to sonsLen(n)-1 do
        gatherVars(c, n.sons[i], marked, owner, container);
    end
  end
end;

(*
  # example:
  proc map(f: proc (x: int): int {.closure}, a: seq[int]): seq[int] =
    result = []
    for elem in a:
      add result, f(a)

  proc addList(a: seq[int], y: int): seq[int] =
    result = map(lambda (x: int): int = return x + y, a)

  should generate -->

  proc map(f: proc(x: int): int, closure: pointer,
           a: seq[int]): seq[int] =
    result = []
    for elem in a:
      add result, f(a, closure)

  type
    PMyClosure = ref record
      y: var int

  proc myLambda(x: int, closure: pointer) =
    var cl = cast[PMyClosure](closure)
    return x + cl.y

  proc addList(a: seq[int], y: int): seq[int] =
    var
      cl: PMyClosure
    new(cl)
    cl.y = y
    result = map(myLambda, cast[pointer](cl), a)


  or (but this is not easier and not binary compatible with C!) -->

  type
    PClosure = ref object of TObject
      f: proc (x: int, c: PClosure): int

  proc map(f: PClosure, a: seq[int]): seq[int] =
    result = []
    for elem in a:
      add result, f.f(a, f)

  type
    PMyClosure = ref object of PClosure
      y: var int

  proc myLambda(x: int, cl: PMyClosure) =
    return x + cl.y

  proc addList(a: seq[int], y: int): seq[int] =
    var
      cl: PMyClosure
    new(cl)
    cl.y = y
    cl.f = myLambda
    result = map(cl, a)
*)

procedure addFormalParam(routine: PSym; param: PSym);
begin
  addSon(routine.typ, param.typ);
  addSon(routine.ast.sons[paramsPos], newSymNode(param));
end;

function indirectAccess(a, b: PSym): PNode;
// returns a^ .b as a node
var
  x, y, deref: PNode;
begin
  x := newSymNode(a);
  y := newSymNode(b);
  deref := newNodeI(nkDerefExpr, x.info);
  deref.typ := x.typ.sons[0];
  addSon(deref, x);
  result := newNodeI(nkDotExpr, x.info);
  addSon(result, deref);
  addSon(result, y);
  result.typ := y.typ;
end;

function transformLambda(c: PContext; n: PNode): PNode;
var
  marked: TIntSet;
  closure: PNode;
  s, param: PSym;
  cl, p: PType;
  i: int;
  newC: PTransCon;
begin
  result := n;
  IntSetInit(marked);
  assert(n.sons[namePos].kind = nkSym);
  s := n.sons[namePos].sym;
  closure := newNodeI(nkRecList, n.sons[codePos].info);
  gatherVars(c, n.sons[codePos], marked, s, closure);
  // add closure type to the param list (even if closure is empty!):
  cl := newType(tyRecord, s);
  cl.n := closure;
  addSon(cl, nil); // no super class
  p := newType(tyRef, s);
  addSon(p, cl);
  param := newSym(skParam, getIdent(genPrefix + 'Cl'), s);
  param.typ := p;
  addFormalParam(s, param);
  // all variables that are accessed should be accessed by the new closure
  // parameter:
  if sonsLen(closure) > 0 then begin
    newC := newTransCon();
    for i := 0 to sonsLen(closure)-1 do begin
      IdNodeTablePut(newC.mapping, closure.sons[i].sym,
                     indirectAccess(param, closure.sons[i].sym))
    end;
    pushTransCon(c, newC);
    n.sons[codePos] := transform(c, n.sons[codePos]);
    popTransCon(c);
  end;
  // Generate code to allocate and fill the closure. This has to be done in
  // the outer routine!
end;

function transformCase(c: PContext; n: PNode): PNode;
// removes `elif` branches of a case stmt
var
  len, i, j: int;
  ifs: PNode;
begin
  len := sonsLen(n);
  i := len-1;
  if n.sons[i].kind = nkElse then dec(i);
  if n.sons[i].kind = nkElifBranch then begin
    while n.sons[i].kind = nkElifBranch do dec(i);
    assert(n.sons[i].kind = nkOfBranch);
    ifs := newNodeI(nkIfStmt, n.sons[i+1].info);
    for j := i+1 to len-1 do addSon(ifs, n.sons[j]);
    setLength(n.sons, i+2);
    n.sons[i+1] := ifs;
  end;
  result := n;
  for j := 0 to sonsLen(n)-1 do
    result.sons[j] := transform(c, n.sons[j]);
end;

function transformArrayAccess(c: PContext; n: PNode): PNode;
var
  j: int;
begin
  result := copyTree(n);
  if result.sons[1].kind in [nkHiddenSubConv, nkHiddenStdConv] then
    result.sons[1] := result.sons[1].sons[0];
  for j := 0 to sonsLen(result)-1 do
    result.sons[j] := transform(c, result.sons[j]);
end;

function transform(c: PContext; n: PNode): PNode;
var
  i: int;
  cnst: PNode;
begin
  result := n;
  if n = nil then exit;
  //result := getConstExpr(c, n); // try to evaluate the expressions
  //if result <> nil then exit;
  //result := n; // reset the result node
  case n.kind of
    nkSym: begin
      result := transformSym(c, n);
      exit
    end;
    nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: begin
      // nothing to be done for leafs
    end;
    nkBracketExpr: result := transformArrayAccess(c, n);
    nkLambda: result := transformLambda(c, n);
    nkForStmt: result := transformFor(c, n);
    nkCaseStmt: result := transformCase(c, n);
    nkProcDef, nkIteratorDef: begin
      if n.sons[genericParamsPos] = nil then
        n.sons[codePos] := transform(c, n.sons[codePos]);
    end;
    nkWhileStmt: begin
      assert(sonsLen(n) = 2);
      n.sons[0] := transform(c, n.sons[0]);
      n.sons[1] := transformContinue(c, n.sons[1]);
    end;
    nkCommentStmt, nkTemplateDef, nkMacroDef: exit;
    nkConstSection: exit; // do not replace ``const c = 3`` with ``const 3 = 3``
    else begin
      for i := 0 to sonsLen(n)-1 do
        result.sons[i] := transform(c, n.sons[i]);
    end
  end;
  cnst := getConstExpr(c, result);
  if cnst <> nil then result := cnst; // do not miss an optimization
end;
