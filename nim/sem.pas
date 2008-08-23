//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit sem;

// This module implements the semantic checking.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils,
  lists, options, scanner, ast, astalgo, trees, treetab, wordrecg,
  ropes, msgs, platform, nos, condsyms, idents, rnimsyn, types,
  extccomp, nmath, magicsys, nversion, nimsets, pnimsyn, ntime, backends;

const
  genPrefix = '::'; // prefix for generated names

type
  TOptionEntry = object(lists.TListEntry)
    // entries to put on a stack for pragma parsing
    options: TOptions;
    defaultCC: TCallingConvention;
    dynlib: PLib;
    Notes: TNoteKinds;
  end;
  POptionEntry = ^TOptionEntry;

  TProcCon = record          // procedure context; also used for top-level
                             // statements
    owner: PSym;             // the symbol this context belongs to
    resultSym: PSym;         // the result symbol (if we are in a proc)
    nestedLoopCounter: int;  // whether we are in a loop or not
    nestedBlockCounter: int; // whether we are in a block or not
  end;
  PProcCon = ^TProcCon;

  PTransCon = ^TTransCon;
  TTransCon = record   // part of TContext; stackable
    mapping: TIdNodeTable; // mapping from symbols to nodes
    owner: PSym;        // current owner
    forStmt: PNode;    // current for stmt
    next: PTransCon;
    params: TNodeSeq;  // parameters passed to the proc
  end;

  PContext = ^TContext;
  TContext = object(NObject) // a context represents a module
    module: PSym;            // the module sym belonging to the context
    tab: TSymTab;            // each module has its own symbol table
    AmbigiousSymbols: TStrTable; // contains all ambigious symbols (we cannot
                                 // store this info in the syms themselves!)
    generics: PNode;         // a list of the things to compile; list of
                             // nkExprEqExpr nodes which contain the generic
                             // symbol and the instantiated symbol
    converters: TSymSeq;     // sequence of converters
    optionStack: TLinkedList;
    libs: TLinkedList;       // all libs used by this module
    b: PBackend;
    p: PProcCon; // procedure context
    transCon: PTransCon; // top of a TransCon stack
    lastException: PNode; // last exception
    importModule: function (const filename: string; backend: PBackend): PSym;
    includeFile: function (const filename: string): PNode;
  end;

function newContext(const nimfile: string): PContext;
function newProcCon(owner: PSym): PProcCon;

function semModule(c: PContext; n: PNode): PNode;
  // Does the semantic pass for node n. The new node is returned and
  // n shall not be used after this call!

procedure importAllSymbols(c: PContext; fromMod: PSym);

implementation

function newTransCon(): PTransCon;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  initIdNodeTable(result.mapping);
{@emit result.params := [];}
end;

procedure pushTransCon(c: PContext; t: PTransCon);
begin
  t.next := c.transCon;
  c.transCon := t;
end;

procedure popTransCon(c: PContext);
begin
  assert(c.transCon <> nil);
  c.transCon := c.transCon.next;
end;

function lastOptionEntry(c: PContext): POptionEntry;
begin
  result := POptionEntry(c.optionStack.tail);
end;

function newProcCon(owner: PSym): PProcCon;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.owner := owner;
end;

function newOptionEntry(): POptionEntry;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.options := gOptions;
  result.defaultCC := ccDefault;
  result.dynlib := nil;
  result.notes := gNotes;
end;

function newContext(const nimfile: string): PContext;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  InitSymTab(result.tab);
  initStrTable(result.AmbigiousSymbols);
  initLinkedList(result.optionStack);
  initLinkedList(result.libs);
  append(result.optionStack, newOptionEntry());
  result.module := nil;
  result.generics := newNode(nkStmtList);
{@emit result.converters := [];}
end;

procedure addConverter(c: PContext; conv: PSym);
var
  i, L: int;
begin
  L := length(c.converters);
  for i := 0 to L-1 do
    if c.converters[i].id = conv.id then exit;
  setLength(c.converters, L+1);
  c.converters[L] := conv;
end;

// -------------------- embedded debugger ------------------------------------

procedure embeddedDbg(c: PContext; n: PNode);
begin
  if optVerbose in gGlobalOptions then liMessage(n.info, hintProcessing);
  //{@discard} inCheckpoint(n.info)
end;

// ---------------------------------------------------------------------------

function newLib(kind: TLibKind): PLib;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := kind;
  initObjectSet(result.syms)
end;

procedure addToLib(lib: PLib; sym: PSym);
begin
  ObjectSetIncl(lib.syms, sym);
  assert(sym.annex = nil);
  sym.annex := lib
end;

function semp(c: PContext; n: PNode): PNode; forward;

var
  gOwners: array of PSym; // owner stack (used for initializing the
                          // owner field of syms)
                          // the documentation comment always gets
                          // assigned to the current owner
                          // BUGFIX: global array is needed!
{@emit gOwners := []; }

function getCurrOwner(c: PContext): PSym;
begin
  result := gOwners[high(gOwners)];
end;

procedure PushOwner(c: PContext; owner: PSym);
var
  len: int;
begin
  len := length(gOwners);
  setLength(gOwners, len+1);
  gOwners[len] := owner;
end;

procedure PopOwner(c: PContext);
var
  len: int;
begin
  len := length(gOwners);
  assert(len > 0);
  setLength(gOwners, len - 1);
end;

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
  result := newSym(kind, considerAcc(n), getCurrOwner(c));
  result.info := n.info;
end;

function newTypeS(const kind: TTypeKind; c: PContext): PType;
begin
  result := newType(kind, getCurrOwner(c))
end;

procedure fillTypeS(dest: PType; const kind: TTypeKind; c: PContext);
begin
  dest.kind := kind;
  dest.owner := getCurrOwner(c);
  dest.size := -1;
end;

function makeRangeType(c: PContext; first, last: biggestInt): PType;
var
  n: PNode;
begin
  n := newNode(nkRange);
  addSon(n, newIntNode(nkIntLit, first));
  addSon(n, newIntNode(nkIntLit, last));
  result := newTypeS(tyRange, c);
  result.n := n;
  addSon(result, getSysType(tyInt)); // basetype of range
end;

function makePtrType(c: PContext; baseType: PType): PType;
begin
  assert(baseType <> nil);
  result := newTypeS(tyPtr, c);
  addSon(result, baseType);
end;

function makeVarType(c: PContext; baseType: PType): PType;
begin
  assert(baseType <> nil);
  result := newTypeS(tyVar, c);
  addSon(result, baseType);
end;

{$include 'lookup.pas'}

function semIdentVis(c: PContext; kind: TSymKind; n: PNode;
                     const allowed: TSymFlags): PSym; forward;
// identifier with visability
function semIdentWithPragma(c: PContext; kind: TSymKind;
                            n: PNode; const allowed: TSymFlags): PSym; forward;

function semStmt(c: PContext; n: PNode): PNode; forward;
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

function semConstExpr(c: PContext; n: PNode): PNode; forward;
  // evaluates the const

function getConstExpr(c: PContext; n: PNode): PNode; forward;
  // evaluates the constant expression or returns nil if it is no constant
  // expression

function eval(c: PContext; n: PNode): PNode; forward;
// eval never returns nil! This simplifies the code a lot and
// makes it faster too.


{$include 'semtempl.pas'}
{$include 'instgen.pas'}
{$include 'sigmatch.pas'}

{$include 'pragmas.pas'}

procedure CheckBool(t: PNode);
begin
  if (t.Typ = nil) or (skipVarGeneric(t.Typ).kind <> tyBool) then
    liMessage(t.Info, errExprMustBeBool);
end;

procedure illFormedAst(n: PNode);
begin
  liMessage(n.info, errIllFormedAstX, renderTree(n, {@set}[renderNoComments]));
end;

function getSon(n: PNode; indx: int): PNode;
begin
  if (n <> nil) and (indx < sonsLen(n)) then result := n.sons[indx]
  else begin illFormedAst(n); result := nil end;
end;

procedure checkSonsLen(n: PNode; len: int);
begin
  if (n = nil) or (sonsLen(n) <> len) then illFormedAst(n);
end;

procedure checkMinSonsLen(n: PNode; len: int);
begin
  if (n = nil) or (sonsLen(n) < len) then illFormedAst(n);
end;

procedure typeMismatch(n: PNode; formal, actual: PType);
begin
  liMessage(n.Info, errGenerated,
         msgKindToString(errTypeMismatch) +{&} typeToString(actual) +{&} ') '
       +{&} format(msgKindToString(errButExpectedX), [typeToString(formal)]));
end;

{$include 'semtypes.pas'}
{$include 'semexprs.pas'}
{$include 'transf.pas'}
{$include 'semstmts.pas'}
{$include 'semfold.pas'}
{$include 'eval.pas'}

function semp(c: PContext; n: PNode): PNode;
begin
  result := semStmt(c, n);
end;

procedure addCodeForGenerics(c: PContext; n: PNode);
var
  i: int;
  prc: PSym;
begin
  for i := 0 to sonsLen(c.generics)-1 do begin
    assert(c.generics.sons[i].sons[1].kind = nkSym);
    prc := c.generics.sons[i].sons[1].sym;
    if (prc.kind in [skProc, skConverter]) and (prc.magic = mNone) then begin
      addSon(n, prc.ast);
    end
  end
end;

function semModule(c: PContext; n: PNode): PNode;
begin
  assert(c.p = nil);
  c.p := newProcCon(nil);
  pushOwner(c, c.module);
  result := semStmtScope(c, n);
  if eAfterModule in c.b.eventMask then begin
    addCodeForGenerics(c, result);
    result := transform(c, result);
    c.b.afterModuleEvent(c.b, result);
  end;
  popOwner(c);
  c.p := nil;
end;

initialization
  new(emptyNode);
  emptyNode.kind := nkEmpty;
end.
