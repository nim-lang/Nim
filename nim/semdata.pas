//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit semdata;

// This module contains the data structures for the semantic checking phase.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils,
  lists, options, scanner, ast, astalgo, trees, treetab, wordrecg,
  ropes, msgs, platform, nos, condsyms, idents, rnimsyn, types,
  extccomp, nmath, magicsys, nversion, nimsets, pnimsyn, ntime, passes,
  rodread;

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

  PContext = ^TContext;
  TContext = object(TPassContext) // a context represents a module
    module: PSym;                 // the module sym belonging to the context
    p: PProcCon;                  // procedure context
    InstCounter: int;             // to prevent endless instantiations
    generics: PNode;              // a list of the things to compile; list of
                                  // nkExprEqExpr nodes which contain the
                                  // generic symbol and the instantiated symbol
    lastGenericIdx: int;          // used for the generics stack
    tab: TSymTab;                 // each module has its own symbol table
    AmbiguousSymbols: TIntSet;    // ids of all ambiguous symbols (cannot
                                  // store this info in the syms themselves!)
    converters: TSymSeq;          // sequence of converters
    optionStack: TLinkedList;
    libs: TLinkedList;            // all libs used by this module
    fromCache: bool;              // is the module read from a cache?
    semConstExpr: function (c: PContext; n: PNode): PNode;
      // for the pragmas module
    includedFiles: TIntSet;       // used to detect recursive include files
    filename: string;             // the module's filename
  end;

var
  gInstTypes: TIdTable; // map PType to PType

function newContext(module: PSym; const nimfile: string): PContext;
function newProcCon(owner: PSym): PProcCon;

function lastOptionEntry(c: PContext): POptionEntry;
function newOptionEntry(): POptionEntry;

procedure addConverter(c: PContext; conv: PSym);

function newLib(kind: TLibKind): PLib;
procedure addToLib(lib: PLib; sym: PSym);

function makePtrType(c: PContext; baseType: PType): PType;
function makeVarType(c: PContext; baseType: PType): PType;

function newTypeS(const kind: TTypeKind; c: PContext): PType;
procedure fillTypeS(dest: PType; const kind: TTypeKind; c: PContext);
function makeRangeType(c: PContext; first, last: biggestInt;
                       const info: TLineInfo): PType;

procedure illFormedAst(n: PNode);
function getSon(n: PNode; indx: int): PNode;
procedure checkSonsLen(n: PNode; len: int);
procedure checkMinSonsLen(n: PNode; len: int);

// owner handling:
function getCurrOwner(): PSym;
procedure PushOwner(owner: PSym);
procedure PopOwner;

implementation

var
  gOwners: array of PSym; // owner stack (used for initializing the
                          // owner field of syms)
                          // the documentation comment always gets
                          // assigned to the current owner
                          // BUGFIX: global array is needed!
{@emit gOwners := @[]; }

function getCurrOwner(): PSym;
begin
  result := gOwners[high(gOwners)];
end;

procedure PushOwner(owner: PSym);
var
  len: int;
begin
  len := length(gOwners);
  setLength(gOwners, len+1);
  gOwners[len] := owner;
end;

procedure PopOwner;
var
  len: int;
begin
  len := length(gOwners);
  if (len <= 0) then InternalError('popOwner');
  setLength(gOwners, len - 1);
end;

function lastOptionEntry(c: PContext): POptionEntry;
begin
  result := POptionEntry(c.optionStack.tail);
end;

function newProcCon(owner: PSym): PProcCon;
begin
  if owner = nil then InternalError('owner is nil');
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

function newContext(module: PSym; const nimfile: string): PContext;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  InitSymTab(result.tab);
  IntSetInit(result.AmbiguousSymbols);
  initLinkedList(result.optionStack);
  initLinkedList(result.libs);
  append(result.optionStack, newOptionEntry());
  result.module := module;
  result.generics := newNode(nkStmtList);
{@emit result.converters := @[];}
  result.filename := nimfile;
  IntSetInit(result.includedFiles);
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


function newLib(kind: TLibKind): PLib;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := kind;
  //initObjectSet(result.syms)
end;

procedure addToLib(lib: PLib; sym: PSym);
begin
  //ObjectSetIncl(lib.syms, sym);
  if sym.annex <> nil then liMessage(sym.info, errInvalidPragma);
  sym.annex := lib
end;

function makePtrType(c: PContext; baseType: PType): PType;
begin
  if (baseType = nil) then InternalError('makePtrType');
  result := newTypeS(tyPtr, c);
  addSon(result, baseType);
end;

function makeVarType(c: PContext; baseType: PType): PType;
begin
  if (baseType = nil) then InternalError('makeVarType');
  result := newTypeS(tyVar, c);
  addSon(result, baseType);
end;

function newTypeS(const kind: TTypeKind; c: PContext): PType;
begin
  result := newType(kind, getCurrOwner())
end;

procedure fillTypeS(dest: PType; const kind: TTypeKind; c: PContext);
begin
  dest.kind := kind;
  dest.owner := getCurrOwner();
  dest.size := -1;
end;

function makeRangeType(c: PContext; first, last: biggestInt;
                       const info: TLineInfo): PType;
var
  n: PNode;
begin
  n := newNodeI(nkRange, info);
  addSon(n, newIntNode(nkIntLit, first));
  addSon(n, newIntNode(nkIntLit, last));
  result := newTypeS(tyRange, c);
  result.n := n;
  addSon(result, getSysType(tyInt)); // basetype of range
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

initialization
  initIdTable(gInstTypes);
end.
