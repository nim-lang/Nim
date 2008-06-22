//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit magicsys;

// This module declares built-in System types like int or string in the
// system module.

interface

{$include 'config.inc'}

uses
  nsystem,
  ast, astalgo, hashes, msgs, platform, nversion, ntime, idents;

var // magic symbols in the system module:
  notSym: PSym;              // 'not' operator (for bool)
  countUpSym: PSym;          // countup iterator

  SystemModule: PSym;
  intSetBaseType: PType;

  compilerprocs: TStrTable;

function getSysType(const kind: TTypeKind): PType;
function getMatic(m: TMagic; const name: string): PSym;
function getCompilerProc(const name: string): PSym;

procedure InitSystem(var tab: TSymTab);
procedure FinishSystem(const tab: TStrTable);

procedure setSize(t: PType; size: int);

implementation

var
  gSysTypes: array [TTypeKind] of PType;

function getSysType(const kind: TTypeKind): PType;
begin
  result := gSysTypes[kind];
  assert(result <> nil);
end;


function getCompilerProc(const name: string): PSym;
begin
  result := StrTableGet(compilerprocs, getIdent(name, getNormalizedHash(name)));
  if result = nil then rawMessage(errSystemNeeds, name)
end;

function FindMagic(const tab: TStrTable; m: TMagic; const s: string): PSym;
var
  ti: TIdentIter;
begin
  result := InitIdentIter(ti, tab, getIdent(s));
  while result <> nil do begin
    if (result.magic = m) then exit;
    result := NextIdentIter(ti, tab)
  end
end;

function getMatic(m: TMagic; const name: string): PSym;
begin
  result := findMagic(systemModule.tab, m, name);
end;

function NewMagic(kind: TSymKind; const name: string;
  const info: TLineInfo): PSym;
begin
  result := newSym(kind, getIdent(name), SystemModule);
  Include(result.loc.Flags, lfNoDecl);
  result.info := info;
end;

function newMagicType(const info: TLineInfo; kind: TTypeKind;
  magicSym: PSym): PType;
begin
  result := newType(kind, SystemModule);
  result.sym := magicSym;
  assert(SystemModule <> nil);
end;

procedure setSize(t: PType; size: int);
begin
  t.align := size;
  t.size := size;
end;


//     not   -(unary)                         700
//     *   /    div   mod                     600
//     +   -                                  500
//     &   ..                                 400
//     ==   <=  <  >=  >  !=   in    not_in   300
//     and                                    200
//     or   xor                               100

procedure addMagicSym(var tab: TSymTab; sym: PSym; sys: PSym);
begin
  SymTabAdd(tab, sym);
  StrTableAdd(sys.tab, sym); // add to interface
  include(sym.flags, sfInInterface);
end;

var
  fakeInfo: TLineInfo;

procedure addIntegral(var tab: TSymTab; kind: TTypeKind; const name: string;
                      size: int);
var
  t: PSym;
begin
  t := newMagic(skType, name, fakeInfo);
  t.typ := newMagicType(fakeInfo, kind, t);
  setSize(t.typ, size);
  addMagicSym(tab, t, SystemModule);
  gSysTypes[kind] := t.typ;
end;

procedure addMagicTAnyEnum(var tab: TSymTab);
var
  s: PSym;
begin
  s := newMagic(skType, 'TAnyEnum', fakeInfo);
  s.typ := newMagicType(fakeInfo, tyAnyEnum, s);
  SymTabAdd(tab, s);
end;

procedure InitSystem(var tab: TSymTab);
var
  c: PSym;
  typ: PType;
begin
  initStrTable(compilerprocs);
  fakeInfo := newLineInfo('system.nim', 1, 1);
  // symbols with compiler magic are pretended to be in system at line 1

  // TAnyEnum:
  addMagicTAnyEnum(tab);

  // nil:
  gSysTypes[tyNil] := newMagicType(fakeInfo, tyNil, nil);
  SetSize(gSysTypes[tyNil], ptrSize);
  // no need to add it to symbol table since it is a reserved word

  // boolean type:
  addIntegral(tab, tyBool, 'bool', 1);

  // false:
  c := NewMagic(skConst, 'false', fakeInfo);
  c.typ := gSysTypes[tyBool];
  c.ast := newIntNode(nkIntLit, ord(false));
  c.ast.typ := gSysTypes[tyBool];
  addMagicSym(tab, c, systemModule);

  // true:
  c := NewMagic(skConst, 'true', fakeInfo);
  c.typ := gSysTypes[tyBool];
  c.ast := newIntNode(nkIntLit, ord(true));
  c.ast.typ := gSysTypes[tyBool];
  addMagicSym(tab, c, systemModule);

  addIntegral(tab, tyFloat32, 'float32', 4);
  addIntegral(tab, tyFloat64, 'float64', 8);
  addIntegral(tab, tyInt8,    'int8',    1);
  addIntegral(tab, tyInt16,   'int16',   2);
  addIntegral(tab, tyInt32,   'int32',   4);
  addIntegral(tab, tyInt64,   'int64',   8);

  if cpu[targetCPU].bit = 64 then begin
    addIntegral(tab, tyFloat128, 'float128', 16);
    addIntegral(tab, tyInt, 'int', 8);
    addIntegral(tab, tyFloat, 'float', 8);
  end
  else if cpu[targetCPU].bit = 32 then begin
    addIntegral(tab, tyInt, 'int', 4);
    addIntegral(tab, tyFloat, 'float', 8);
  end
  else begin // 16 bit cpu:
    addIntegral(tab, tyInt, 'int', 2);
    addIntegral(tab, tyFloat, 'float', 4);
  end;

  // char type:
  addIntegral(tab, tyChar, 'char', 1);

  // string type:
  addIntegral(tab, tyString, 'string', ptrSize);
  typ := gSysTypes[tyString];
  addSon(typ, gSysTypes[tyChar]);
  
  // pointer type:
  addIntegral(tab, tyPointer, 'pointer', ptrSize);


  addIntegral(tab, tyCString, 'cstring', ptrSize);
  typ := gSysTypes[tyCString];
  addSon(typ, gSysTypes[tyChar]);

  gSysTypes[tyEmptySet] := newMagicType(fakeInfo, tyEmptySet, nil);

  intSetBaseType := newMagicType(fakeInfo, tyRange, nil);
  addSon(intSetBaseType, gSysTypes[tyInt]); // base type
  setSize(intSetBaseType, int(gSysTypes[tyInt].size));
  intSetBaseType.n := newNode(nkRange);
  intSetBaseType.n.info := fakeInfo;
  addSon(intSetBaseType.n, newIntNode(nkIntLit, 0));
  addSon(intSetBaseType.n, newIntNode(nkIntLit, nversion.MaxSetElements-1));
  intSetBaseType.n.sons[0].info := fakeInfo;
  intSetBaseType.n.sons[1].info := fakeInfo;
  intSetBaseType.n.sons[0].typ := gSysTypes[tyInt];
  intSetBaseType.n.sons[1].typ := gSysTypes[tyInt];
end;

procedure FinishSystem(const tab: TStrTable);
begin
  notSym := findMagic(tab, mNot, 'not');
  if (notSym = nil) then
    rawMessage(errSystemNeeds, 'not');

  countUpSym := StrTableGet(tab, getIdent('countup'));
  if (countUpSym = nil) then
    rawMessage(errSystemNeeds, 'countup');
end;

end.
