//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit magicsys;

// Built-in types and compilerprocs are registered here.

interface

{$include 'config.inc'}

uses
  nsystem,
  ast, astalgo, nhashes, msgs, platform, nversion, ntime, idents, rodread;

var // magic symbols in the system module:
  SystemModule: PSym;

procedure registerSysType(t: PType);
function getSysType(const kind: TTypeKind): PType;

function getCompilerProc(const name: string): PSym;
procedure registerCompilerProc(s: PSym);

procedure InitSystem(var tab: TSymTab);
procedure FinishSystem(const tab: TStrTable);

implementation

var
  gSysTypes: array [TTypeKind] of PType;
  compilerprocs: TStrTable;

procedure registerSysType(t: PType);
begin
  if gSysTypes[t.kind] = nil then gSysTypes[t.kind] := t;
end;

function newSysType(kind: TTypeKind; size: int): PType;
begin
  result := newType(kind, systemModule);
  result.size := size;
  result.align := size;
end;

function sysTypeFromName(const name: string): PType;
var
  s: PSym;
begin
  s := StrTableGet(systemModule.tab, getIdent(name));
  if s = nil then rawMessage(errSystemNeeds, name);
  if s.kind = skStub then loadStub(s); 
  result := s.typ;
end;

function getSysType(const kind: TTypeKind): PType;
begin
  result := gSysTypes[kind];
  if result = nil then begin
    case kind of
      tyInt:     result := sysTypeFromName('int');
      tyInt8:    result := sysTypeFromName('int8');
      tyInt16:   result := sysTypeFromName('int16');
      tyInt32:   result := sysTypeFromName('int32');
      tyInt64:   result := sysTypeFromName('int64');
      tyFloat:   result := sysTypeFromName('float');
      tyFloat32: result := sysTypeFromName('float32');
      tyFloat64: result := sysTypeFromName('float64');
      tyBool:    result := sysTypeFromName('bool');
      tyChar:    result := sysTypeFromName('char');
      tyString:  result := sysTypeFromName('string');
      tyCstring: result := sysTypeFromName('cstring');
      tyPointer: result := sysTypeFromName('pointer');
      tyNil: result := newSysType(tyNil, ptrSize);
      else InternalError('request for typekind: ' + typeKindToStr[kind]);
    end;  
    gSysTypes[kind] := result;
  end;
  if result.kind <> kind then 
    InternalError('wanted: ' + typeKindToStr[kind] 
      +{&} ' got: ' +{&} typeKindToStr[result.kind]);
  if result = nil then InternalError('type not found: ' + typeKindToStr[kind]);
end;

function getCompilerProc(const name: string): PSym;
var
  ident: PIdent;
begin
  ident := getIdent(name, getNormalizedHash(name));
  result := StrTableGet(compilerprocs, ident);
  if result = nil then begin
    result := StrTableGet(rodCompilerProcs, ident);
    if result <> nil then begin 
      strTableAdd(compilerprocs, result);
      if result.kind = skStub then loadStub(result);
    end;
    // A bit hacky that this code is needed here, but it is the easiest 
    // solution in order to avoid special cases for sfCompilerProc in the
    // rodgen module. Another solution would be to always recompile the system
    // module. But I don't want to do that as that would mean less testing of
    // the new symbol file cache (and worse performance).
  end;
end;

procedure registerCompilerProc(s: PSym);
begin
  strTableAdd(compilerprocs, s);
end;
(*
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
end;

procedure setSize(t: PType; size: int);
begin
  t.align := size;
  t.size := size;
end;

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
*)
procedure InitSystem(var tab: TSymTab);
begin (*
  if SystemModule = nil then InternalError('systemModule == nil');
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
  intSetBaseType.n := newNodeI(nkRange, fakeInfo);
  addSon(intSetBaseType.n, newIntNode(nkIntLit, 0));
  addSon(intSetBaseType.n, newIntNode(nkIntLit, nversion.MaxSetElements-1));
  intSetBaseType.n.sons[0].info := fakeInfo;
  intSetBaseType.n.sons[1].info := fakeInfo;
  intSetBaseType.n.sons[0].typ := gSysTypes[tyInt];
  intSetBaseType.n.sons[1].typ := gSysTypes[tyInt]; *)
end;

procedure FinishSystem(const tab: TStrTable);
begin (*
  notSym := findMagic(tab, mNot, 'not');
  if (notSym = nil) then
    rawMessage(errSystemNeeds, 'not');

  countUpSym := StrTableGet(tab, getIdent('countup'));
  if (countUpSym = nil) then
    rawMessage(errSystemNeeds, 'countup'); *)
end;

initialization
  initStrTable(compilerprocs);
end.
