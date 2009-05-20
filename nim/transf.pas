//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit transf;

// This module implements the transformator. It transforms the syntax tree
// to ease the work of the code generators. Does some transformations:
//
// * inlines iterators
// * inlines constants
// * performes contant folding
// * introduces nkHiddenDeref, nkHiddenSubConv, etc.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils,
  lists, options, ast, astalgo, trees, treetab, 
  msgs, nos, idents, rnimsyn, types, passes, semfold, magicsys;

const
  genPrefix = ':tmp'; // prefix for generated names
  
function transfPass(): TPass;

implementation

type
  PTransCon = ^TTransCon;
  TTransCon = record   // part of TContext; stackable
    mapping: TIdNodeTable; // mapping from symbols to nodes
    owner: PSym;        // current owner
    forStmt: PNode;    // current for stmt
    next: PTransCon;   // for stacking
  end;
  
  TTransfContext = object(passes.TPassContext)
    module: PSym;
    transCon: PTransCon; // top of a TransCon stack
  end;
  PTransf = ^TTransfContext;

function newTransCon(): PTransCon;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  initIdNodeTable(result.mapping);
end;

procedure pushTransCon(c: PTransf; t: PTransCon);
begin
  t.next := c.transCon;
  c.transCon := t;
end;

procedure popTransCon(c: PTransf);
begin
  if (c.transCon = nil) then InternalError('popTransCon');
  c.transCon := c.transCon.next;
end;

// ------------ helpers -----------------------------------------------------

function getCurrOwner(c: PTransf): PSym;
begin
  if c.transCon <> nil then result := c.transCon.owner
  else result := c.module;
end;

function newTemp(c: PTransf; typ: PType; const info: TLineInfo): PSym;
begin
  result := newSym(skTemp, getIdent(genPrefix), getCurrOwner(c));
  result.info := info;
  result.typ := skipGeneric(typ);
  include(result.flags, sfFromGeneric);
end;

// --------------------------------------------------------------------------

function transform(c: PTransf; n: PNode): PNode; forward;

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

function newAsgnStmt(c: PTransf; le, ri: PNode): PNode;
begin
  result := newNodeI(nkFastAsgn, ri.info);
  addSon(result, le);
  addSon(result, ri);
end;

function transformSym(c: PTransf; n: PNode): PNode;
var
  tc: PTransCon;
begin
  if (n.kind <> nkSym) then internalError(n.info, 'transformSym');
  tc := c.transCon;
  //writeln('transformSym', n.sym.id : 5);
  while tc <> nil do begin
    result := IdNodeTableGet(tc.mapping, n.sym);
    if result <> nil then exit;
    //write('not found in: ');
    //writeIdNodeTable(tc.mapping);
    tc := tc.next
  end;
  result := n;
  case n.sym.kind of
    skConst, skEnumField: begin // BUGFIX: skEnumField was missing
      if not (skipGeneric(n.sym.typ).kind in ConstantDataTypes) then begin
        result := getConstExpr(c.module, n);
        if result = nil then InternalError(n.info, 'transformSym: const');
      end
    end
    else begin end
  end
end;

procedure transformContinueAux(c: PTransf; n: PNode; labl: PSym;
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

function transformContinue(c: PTransf; n: PNode): PNode;
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
  labl := newSym(skLabel, nil, getCurrOwner(c));
  labl.name := getIdent(genPrefix +{&} ToString(labl.id));
  labl.info := result.info;
  transformContinueAux(c, result, labl, counter);
  if counter > 0 then begin
    x := newNodeI(nkBlockStmt, result.info);
    addSon(x, newSymNode(labl));
    addSon(x, result);
    result := x
  end
end;

function skipConv(n: PNode): PNode;
begin
  case n.kind of
    nkObjUpConv, nkObjDownConv, nkPassAsOpenArray, nkChckRange,
    nkChckRangeF, nkChckRange64:
      result := n.sons[0];
    nkHiddenStdConv, nkHiddenSubConv, nkConv: result := n.sons[1];
    else result := n
  end
end;

function newTupleAccess(tup: PNode; i: int): PNode;
var
  lit: PNode;
begin
  result := newNodeIT(nkBracketExpr, tup.info, tup.typ.sons[i]);
  addSon(result, copyTree(tup));
  lit := newNodeIT(nkIntLit, tup.info, getSysType(tyInt));
  lit.intVal := i;
  addSon(result, lit);
end;

procedure unpackTuple(c: PTransf; n, father: PNode);
var
  i: int;
begin
  // XXX: BUG: what if `n` is an expression with side-effects?
  for i := 0 to sonsLen(n)-1 do begin
    addSon(father, newAsgnStmt(c, c.transCon.forStmt.sons[i],
           transform(c, newTupleAccess(n, i))));
  end
end;

function transformYield(c: PTransf; n: PNode): PNode;
var
  e: PNode;
  i: int;
begin
  result := newNodeI(nkStmtList, n.info);
  e := n.sons[0];
  if skipGeneric(e.typ).kind = tyTuple then begin
    e := skipConv(e);
    if e.kind = nkPar then begin
      for i := 0 to sonsLen(e)-1 do begin
        addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[i],
               transform(c, copyTree(e.sons[i]))));
      end
    end
    else 
      unpackTuple(c, e, result);
  end
  else begin
    e := transform(c, copyTree(e));
    addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[0], e));
  end;
  // add body of the for loop:
  addSon(result, transform(c, lastSon(c.transCon.forStmt)));
end;

function inlineIter(c: PTransf; n: PNode): PNode;
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
        if it.kind = nkCommentStmt then continue;
        if (it.kind <> nkIdentDefs) or (it.sons[0].kind <> nkSym) then
          InternalError(it.info, 'inlineIter');
        newVar := copySym(it.sons[0].sym);
        include(newVar.flags, sfFromGeneric);
        // fixes a strange bug for rodgen:
        //include(it.sons[0].sym.flags, sfFromGeneric);
        newVar.owner := getCurrOwner(c);
        IdNodeTablePut(c.transCon.mapping, it.sons[0].sym, newSymNode(newVar));
        it.sons[0] := newSymNode(newVar);
        it.sons[2] := transform(c, it.sons[2]);
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

function transformAddrDeref(c: PTransf; n: PNode; a, b: TNodeKind): PNode;
var
  m: PNode;
begin
  case n.sons[0].kind of
    nkObjUpConv, nkObjDownConv, nkPassAsOpenArray, nkChckRange,
    nkChckRangeF, nkChckRange64: begin
      m := n.sons[0].sons[0];
      if (m.kind = a) or (m.kind = b) then begin
        // addr ( nkPassAsOpenArray ( deref ( x ) ) ) --> nkPassAsOpenArray(x)
        n.sons[0].sons[0] := m.sons[0];
        result := transform(c, n.sons[0]);
        exit
      end
    end;
    nkHiddenStdConv, nkHiddenSubConv, nkConv: begin
      m := n.sons[0].sons[1];
      if (m.kind = a) or (m.kind = b) then begin
        // addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
        n.sons[0].sons[1] := m.sons[0];
        result := transform(c, n.sons[0]);
        exit
      end
    end;
    else begin
      if (n.sons[0].kind = a) or (n.sons[0].kind = b) then begin
        // addr ( deref ( x )) --> x
        result := transform(c, n.sons[0].sons[0]);
        exit
      end
    end
  end;
  n.sons[0] := transform(c, n.sons[0]);
  result := n;
end;

function transformConv(c: PTransf; n: PNode): PNode;
var
  source, dest: PType;
  diff: int;
begin
  n.sons[1] := transform(c, n.sons[1]);
  result := n;
  // numeric types need range checks:
  dest := skipVarGenericRange(n.typ);
  source := skipVarGenericRange(n.sons[1].typ);
  case dest.kind of
    tyInt..tyInt64, tyEnum, tyChar, tyBool: begin
      if (firstOrd(dest) <= firstOrd(source)) and
          (lastOrd(source) <= lastOrd(dest)) then begin
        // BUGFIX: simply leave n as it is; we need a nkConv node,
        // but no range check:
        result := n;
      end
      else begin // generate a range check:
        if (dest.kind = tyInt64) or (source.kind = tyInt64) then
          result := newNodeIT(nkChckRange64, n.info, n.typ)
        else
          result := newNodeIT(nkChckRange, n.info, n.typ);
        dest := skipVarGeneric(n.typ);
        addSon(result, n.sons[1]);
        addSon(result, newIntTypeNode(nkIntLit, firstOrd(dest), source));
        addSon(result, newIntTypeNode(nkIntLit,  lastOrd(dest), source));
      end
    end;
    tyFloat..tyFloat128: begin
      if skipVarGeneric(n.typ).kind = tyRange then begin
        result := newNodeIT(nkChckRangeF, n.info, n.typ);
        dest := skipVarGeneric(n.typ);
        addSon(result, n.sons[1]);
        addSon(result, copyTree(dest.n.sons[0]));
        addSon(result, copyTree(dest.n.sons[1]));
      end
    end;
    tyOpenArray: begin
      result := newNodeIT(nkPassAsOpenArray, n.info, n.typ);
      addSon(result, n.sons[1]);
    end;
    tyCString: begin
      if source.kind = tyString then begin
        result := newNodeIT(nkStringToCString, n.info, n.typ);
        addSon(result, n.sons[1]);
      end;
    end;
    tyString: begin
      if source.kind = tyCString then begin
        result := newNodeIT(nkCStringToString, n.info, n.typ);
        addSon(result, n.sons[1]);
      end;
    end;
    tyRef, tyPtr: begin
      dest := skipPtrsGeneric(dest);
      source := skipPtrsGeneric(source);
      if source.kind = tyObject then begin
        diff := inheritanceDiff(dest, source);
        if diff < 0 then begin
          result := newNodeIT(nkObjUpConv, n.info, n.typ);
          addSon(result, n.sons[1]);
        end
        else if diff > 0 then begin
          result := newNodeIT(nkObjDownConv, n.info, n.typ);
          addSon(result, n.sons[1]);
        end
        else result := n.sons[1];
      end
    end;
    // conversions between different object types:
    tyObject: begin
      diff := inheritanceDiff(dest, source);
      if diff < 0 then begin
        result := newNodeIT(nkObjUpConv, n.info, n.typ);
        addSon(result, n.sons[1]);
      end
      else if diff > 0 then begin
        result := newNodeIT(nkObjDownConv, n.info, n.typ);
        addSon(result, n.sons[1]);
      end
      else result := n.sons[1];
    end; (*
    tyArray, tySeq: begin
      if skipGeneric(dest
    end; *)
    tyGenericParam, tyAnyEnum: result := n.sons[1];
      // happens sometimes for generated assignments, etc.
    else begin end
  end;
end;

function skipPassAsOpenArray(n: PNode): PNode;
begin
  result := n;
  while result.kind = nkPassAsOpenArray do result := result.sons[0]
end;

type 
  TPutArgInto = (paDirectMapping, paFastAsgn, paVarAsgn);

function putArgInto(arg: PNode; formal: PType): TPutArgInto;
// This analyses how to treat the mapping "formal <-> arg" in an
// inline context.
var
  i: int;
begin
  if skipGeneric(formal).kind = tyOpenArray then begin
    result := paDirectMapping; // XXX really correct?
    // what if ``arg`` has side-effects?
    exit
  end;
  case arg.kind of
    nkEmpty..nkNilLit: result := paDirectMapping;
    nkPar, nkCurly, nkBracket: begin
      result := paFastAsgn;
      for i := 0 to sonsLen(arg)-1 do 
        if putArgInto(arg.sons[i], formal) <> paDirectMapping then
          exit;
      result := paDirectMapping;
    end;
    else begin
      if skipGeneric(formal).kind = tyVar then
        result := paVarAsgn
      else
        result := paFastAsgn
    end
  end
end;

function transformFor(c: PTransf; n: PNode): PNode;
// generate access statements for the parameters (unless they are constant)
// put mapping from formal parameters to actual parameters
var
  i, len: int;
  call, v, body, arg: PNode;
  newC: PTransCon;
  temp, formal: PSym;
begin
  if (n.kind <> nkForStmt) then InternalError(n.info, 'transformFor');
  result := newNodeI(nkStmtList, n.info);
  len := sonsLen(n);
  n.sons[len-1] := transformContinue(c, n.sons[len-1]);
  v := newNodeI(nkVarSection, n.info);
  for i := 0 to len-3 do addVar(v, copyTree(n.sons[i])); // declare new vars
  addSon(result, v);
  newC := newTransCon();
  call := n.sons[len-2];
  if (call.kind <> nkCall) or (call.sons[0].kind <> nkSym) then
    InternalError(call.info, 'transformFor');
  newC.owner := call.sons[0].sym;
  newC.forStmt := n;
  if (newC.owner.kind <> skIterator) then 
    InternalError(call.info, 'transformFor');
  // generate access statements for the parameters (unless they are constant)
  pushTransCon(c, newC);
  for i := 1 to sonsLen(call)-1 do begin
    arg := skipPassAsOpenArray(transform(c, call.sons[i]));
    formal := skipGeneric(newC.owner.typ).n.sons[i].sym;
    //if IdentEq(newc.Owner.name, 'items') then 
    //  liMessage(arg.info, warnUser, 'items: ' + nodeKindToStr[arg.kind]);
    case putArgInto(arg, formal.typ) of
      paDirectMapping: IdNodeTablePut(newC.mapping, formal, arg);
      paFastAsgn: begin
        // generate a temporary and produce an assignment statement:
        temp := newTemp(c, formal.typ, formal.info);
        addVar(v, newSymNode(temp));
        addSon(result, newAsgnStmt(c, newSymNode(temp), arg));
        IdNodeTablePut(newC.mapping, formal, newSymNode(temp));
      end;
      paVarAsgn: begin
        assert(skipGeneric(formal.typ).kind = tyVar);
        InternalError(arg.info, 'not implemented: pass to var parameter');
      end;
    end;
  end;
  body := newC.owner.ast.sons[codePos];
  pushInfoContext(n.info);
  addSon(result, inlineIter(c, body));
  popInfoContext();
  popTransCon(c);
end;

function getMagicOp(call: PNode): TMagic;
begin
  if (call.sons[0].kind = nkSym)
  and (call.sons[0].sym.kind in [skProc, skConverter]) then
    result := call.sons[0].sym.magic
  else
    result := mNone
end;

procedure gatherVars(c: PTransf; n: PNode; var marked: TIntSet;
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
    result = @[]
    for elem in a:
      add result, f(a)

  proc addList(a: seq[int], y: int): seq[int] =
    result = map(lambda (x: int): int = return x + y, a)

  should generate -->

  proc map(f: proc(x: int): int, closure: pointer,
           a: seq[int]): seq[int] =
    result = @[]
    for elem in a:
      add result, f(a, closure)

  type
    PMyClosure = ref object
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

function transformLambda(c: PTransf; n: PNode): PNode;
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
  if (n.sons[namePos].kind <> nkSym) then
    InternalError(n.info, 'transformLambda');
  s := n.sons[namePos].sym;
  closure := newNodeI(nkRecList, n.sons[codePos].info);
  gatherVars(c, n.sons[codePos], marked, s, closure);
  // add closure type to the param list (even if closure is empty!):
  cl := newType(tyObject, s);
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

function transformCase(c: PTransf; n: PNode): PNode;
// removes `elif` branches of a case stmt
var
  len, i, j: int;
  ifs, elsen: PNode;
begin
  len := sonsLen(n);
  i := len-1;
  if n.sons[i].kind = nkElse then dec(i);
  if n.sons[i].kind = nkElifBranch then begin
    while n.sons[i].kind = nkElifBranch do dec(i);
    if (n.sons[i].kind <> nkOfBranch) then 
      InternalError(n.sons[i].info, 'transformCase');
    ifs := newNodeI(nkIfStmt, n.sons[i+1].info);
    elsen := newNodeI(nkElse, ifs.info);
    for j := i+1 to len-1 do addSon(ifs, n.sons[j]);
    setLength(n.sons, i+2);
    addSon(elsen, ifs);
    n.sons[i+1] := elsen;
  end;
  result := n;
  for j := 0 to sonsLen(n)-1 do result.sons[j] := transform(c, n.sons[j]);
end;

function transformArrayAccess(c: PTransf; n: PNode): PNode;
var
  i: int;
begin
  result := copyTree(n);
  result.sons[0] := skipConv(result.sons[0]);
  result.sons[1] := skipConv(result.sons[1]);
  for i := 0 to sonsLen(result)-1 do
    result.sons[i] := transform(c, result.sons[i]);
end;

function getMergeOp(n: PNode): PSym;
begin
  result := nil;
  case n.kind of
    nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix: begin
      if (n.sons[0].Kind = nkSym) and (n.sons[0].sym.kind = skProc) 
      and (sfMerge in n.sons[0].sym.flags) then 
        result := n.sons[0].sym;
    end
    else begin end
  end
end;

procedure flattenTreeAux(d, a: PNode; op: PSym);
var
  i: int;
  op2: PSym;
begin
  op2 := getMergeOp(a);
  if (op2 <> nil) and ((op2.id = op.id) 
                   or (op.magic <> mNone) and (op2.magic = op.magic)) then
    for i := 1 to sonsLen(a)-1 do
      flattenTreeAux(d, a.sons[i], op)
  else
    // a is a "leaf", so add it:
    addSon(d, copyTree(a))
end;

function flattenTree(root: PNode): PNode;
var
  op: PSym;
begin
  op := getMergeOp(root);
  if op <> nil then begin
    result := copyNode(root);
    addSon(result, copyTree(root.sons[0]));
    flattenTreeAux(result, root, op)
  end
  else 
    result := root
end;

function transformCall(c: PTransf; n: PNode): PNode;
var
  i, j: int;
  m, a: PNode;
  op: PSym;
begin
  result := flattenTree(n);
  for i := 0 to sonsLen(result)-1 do
    result.sons[i] := transform(c, result.sons[i]);
  op := getMergeOp(result);
  if (op <> nil) and (op.magic <> mNone) and (sonsLen(result) >= 3) then begin
    m := result;
    result := newNodeIT(nkCall, m.info, m.typ);
    addSon(result, copyTree(m.sons[0]));
    j := 1;
    while j < sonsLen(m) do begin
      a := m.sons[j];
      inc(j);
      if isConstExpr(a) then 
        while (j < sonsLen(m)) and isConstExpr(m.sons[j]) do begin
          a := evalOp(op.magic, m, a, m.sons[j], nil);
          inc(j)
        end;
      addSon(result, a);
    end;
    if sonsLen(result) = 2 then
      result := result.sons[1];
  end;
end;

function transform(c: PTransf; n: PNode): PNode;
var
  i: int;
  cnst: PNode;
begin
  result := n;
  if n = nil then exit;
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
    nkProcDef, nkIteratorDef, nkMacroDef: begin
      if n.sons[genericParamsPos] = nil then
        n.sons[codePos] := transform(c, n.sons[codePos]);
    end;
    nkWhileStmt: begin
      if (sonsLen(n) <> 2) then InternalError(n.info, 'transform');
      n.sons[0] := transform(c, n.sons[0]);
      n.sons[1] := transformContinue(c, n.sons[1]);
    end;
    nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix:
      result := transformCall(c, result);
    nkAddr, nkHiddenAddr:
      result := transformAddrDeref(c, n, nkDerefExpr, nkHiddenDeref);
    nkDerefExpr, nkHiddenDeref:
      result := transformAddrDeref(c, n, nkAddr, nkHiddenAddr);
    nkHiddenStdConv, nkHiddenSubConv, nkConv:
      result := transformConv(c, n);
    nkCommentStmt, nkTemplateDef: exit;
    nkConstSection: exit; // do not replace ``const c = 3`` with ``const 3 = 3``
    else begin
      for i := 0 to sonsLen(n)-1 do
        result.sons[i] := transform(c, n.sons[i]);
    end
  end;
  cnst := getConstExpr(c.module, result);
  if cnst <> nil then result := cnst; // do not miss an optimization  
end;

function processTransf(context: PPassContext; n: PNode): PNode;
var
  c: PTransf;
begin
  c := PTransf(context);
  result := transform(c, n);
end;

function openTransf(module: PSym; const filename: string): PPassContext;
var
  n: PTransf;
begin
  new(n);
{@ignore}
  fillChar(n^, sizeof(n^), 0);
{@emit}
  n.module := module;
  result := n;
end;

function transfPass(): TPass;
begin
  initPass(result);
  result.open := openTransf;
  result.process := processTransf;
  result.close := processTransf; // we need to process generics too!
end;

end.
