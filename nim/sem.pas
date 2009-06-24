//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit sem;

// This module implements the semantic checking pass.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils,
  lists, options, scanner, ast, astalgo, trees, treetab, wordrecg,
  ropes, msgs, nos, condsyms, idents, rnimsyn, types, platform,
  nmath, magicsys, pnimsyn, nversion, nimsets,
  semdata, evals, semfold, importer, procfind, lookups, rodread,
  pragmas, passes;
  
//var
//  point: array [0..3] of int;

function semPass(): TPass;

implementation

function semp(c: PContext; n: PNode): PNode; forward;

function considerAcc(n: PNode): PIdent;
var
  x: PNode;
begin
  x := n;
  if x.kind = nkAccQuoted then x := x.sons[0];
  case x.kind of
    nkIdent: result := x.ident;
    nkSym: result := x.sym.name;
    else begin
      liMessage(n.info, errIdentifierExpected, renderTree(n));
      result := nil
    end
  end
end;

function newSymS(const kind: TSymKind; n: PNode; c: PContext): PSym;
begin
  result := newSym(kind, considerAcc(n), getCurrOwner());
  result.info := n.info;
end;

function semIdentVis(c: PContext; kind: TSymKind; n: PNode;
                     const allowed: TSymFlags): PSym; forward;
// identifier with visability
function semIdentWithPragma(c: PContext; kind: TSymKind;
                            n: PNode; const allowed: TSymFlags): PSym; forward;

function semStmtScope(c: PContext; n: PNode): PNode; forward;

type
  TExprFlag = (efAllowType, efLValue);
  TExprFlags = set of TExprFlag;

function semExpr(c: PContext; n: PNode;
                 flags: TExprFlags = {@set}[]): PNode; forward;
function semExprWithType(c: PContext; n: PNode;
                         flags: TExprFlags = {@set}[]): PNode; forward;
function semLambda(c: PContext; n: PNode): PNode; forward;
function semTypeNode(c: PContext; n: PNode; prev: PType): PType; forward;
function semStmt(c: PContext; n: PNode): PNode; forward;

function semConstExpr(c: PContext; n: PNode): PNode;
var
  e: PNode;
begin
  e := semExprWithType(c, n);
  if e = nil then begin
    liMessage(n.info, errConstExprExpected);
    result := nil; exit
  end;
  result := getConstExpr(c.module, e);
  if result = nil then 
    liMessage(n.info, errConstExprExpected);
end;

function semAndEvalConstExpr(c: PContext; n: PNode): PNode;
var
  e: PNode;
begin
  e := semExprWithType(c, n);
  if e = nil then begin
    liMessage(n.info, errConstExprExpected);
    result := nil; exit
  end;
  result := getConstExpr(c.module, e);
  if result = nil then begin
    //writeln(output, renderTree(n));
    result := evalConstExpr(c.module, e);
    if (result = nil) or (result.kind = nkEmpty) then
      liMessage(n.info, errConstExprExpected);
  end
end;

function semAfterMacroCall(c: PContext; n, p: PNode): PNode;
begin
  result := n;
  if (p = nil) or (p.kind <> nkIdent) then
    liMessage(n.info, errInvalidParamKindX, renderTree(p))
  else begin
    case p.ident.id of
      ord(wExpr): result := semExprWithType(c, result);
      ord(wStmt): result := semStmt(c, result);
      ord(wTypeDesc): 
        result.typ := semTypeNode(c, result, nil);
      else
        liMessage(p.info, errInvalidParamKindX, p.ident.s)
    end
  end
end;

function semMacroExpr(c: PContext; n: PNode; sym: PSym): PNode;
var
  p: PEvalContext;
  s: PStackFrame;
begin
  include(sym.flags, sfUsed);
  p := newEvalContext(c.module, '', false);
  s := newStackFrame();
  s.call := n;
  setLength(s.params, 2);
  s.params[0] := newNodeIT(nkNilLit, n.info, sym.typ.sons[0]);
  s.params[1] := n;
  pushStackFrame(p, s);
  {@discard} eval(p, sym.ast.sons[codePos]);
  result := s.params[0];
  popStackFrame(p);
  if cyclicTree(result) then liMessage(n.info, errCyclicTree);
  result := semAfterMacroCall(c, result, sym.ast.sons[paramsPos].sons[0]);
  // now, that was easy ...
  // and we get more flexibility than in any other programming language
end;

{$include 'semtempl.pas'}
{$include 'seminst.pas'}
{$include 'sigmatch.pas'}

procedure CheckBool(t: PNode);
begin
  if (t.Typ = nil) or (skipTypes(t.Typ, {@set}[tyGenericInst, 
      tyVar, tyOrdinal]).kind <> tyBool) then
    liMessage(t.Info, errExprMustBeBool);
end;

procedure typeMismatch(n: PNode; formal, actual: PType);
begin
  liMessage(n.Info, errGenerated,
         msgKindToString(errTypeMismatch) +{&} typeToString(actual) +{&} ') '
       +{&} format(msgKindToString(errButExpectedX), [typeToString(formal)]));
end;

{$include 'semtypes.pas'}
{$include 'semexprs.pas'}
{$include 'semstmts.pas'}

function semp(c: PContext; n: PNode): PNode;
begin
  result := semStmt(c, n);
end;

procedure addCodeForGenerics(c: PContext; n: PNode);
var
  i: int;
  prc: PSym;
  it: PNode;
begin
  for i := c.lastGenericIdx to sonsLen(c.generics)-1 do begin
    it := c.generics.sons[i].sons[1];
    if it.kind <> nkSym then InternalError('addCodeForGenerics');
    prc := it.sym;
    if (prc.kind in [skProc, skConverter]) and (prc.magic = mNone) then begin
      if (prc.ast = nil) or (prc.ast.sons[codePos] = nil) then 
        InternalError(prc.info, 'no code for ' + prc.name.s);
      addSon(n, prc.ast);
    end
  end;
  c.lastGenericIdx := sonsLen(c.generics);
end;

function myOpen(module: PSym; const filename: string): PPassContext;
var
  c: PContext;
begin
  c := newContext(module, filename);
  if (c.p <> nil) then InternalError(module.info, 'sem.myOpen');
  c.semConstExpr := semConstExpr;
  c.p := newProcCon(module);
  pushOwner(c.module);
  openScope(c.tab); // scope for imported symbols
  SymTabAdd(c.tab, module); // a module knows itself
  if sfSystemModule in module.flags then begin
    magicsys.SystemModule := module; // set global variable!
    InitSystem(c.tab); // currently does nothing
  end
  else begin
    SymTabAdd(c.tab, magicsys.SystemModule); // import the "System" identifier
    importAllSymbols(c, magicsys.SystemModule);
  end;
  openScope(c.tab); // scope for the module's symbols  
  result := c
end;

function myOpenCached(module: PSym; const filename: string;
                      rd: PRodReader): PPassContext;
var
  c: PContext;
begin
  c := PContext(myOpen(module, filename));
  c.fromCache := true;
  result := c
end;

function myProcess(context: PPassContext; n: PNode): PNode;
var
  c: PContext;
  a: PNode;
begin
  result := nil;
  c := PContext(context);
  result := semStmt(c, n);
  // BUGFIX: process newly generated generics here, not at the end!
  if sonsLen(c.generics) > 0 then begin
    a := newNodeI(nkStmtList, n.info);
    addCodeForGenerics(c, a);
    if sonsLen(a) > 0 then begin
      // a generic has been added to `a`:
      addSonIfNotNil(a, result);
      result := a
    end
  end
end;

function myClose(context: PPassContext; n: PNode): PNode;
var
  c: PContext;
begin
  c := PContext(context);
  closeScope(c.tab);    // close module's scope
  rawCloseScope(c.tab); // imported symbols; don't check for unused ones!
  if n = nil then result := newNode(nkStmtList)
  else InternalError(n.info, 'n is not nil');
  //result := n;
  addCodeForGenerics(c, result);
  popOwner();
  c.p := nil;
end;

function semPass(): TPass;
begin
  initPass(result);
  result.open := myOpen;
  result.openCached := myOpenCached;
  result.close := myClose;
  result.process := myProcess;
end;

end.
