//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit rodgen;

// This module is responsible for loading and storing of rod files.
(*
  Reading and writing binary files are really hard to debug. Therefore we use
  a special text format. ROD-files only describe the interface of a module.
  Thus they are smaller than the source files most of the time. Even if they
  are bigger, they are more efficient to process because symbols are only
  loaded on demand.
  It consists of:

  - a header:
    NIM:$fileversion\n
  - the module's id (even if the module changed, its ID will not!):
    ID:Ax3\n
  - CRC value of this module:
    CRC:CRC-val\n
  - a section containing the compiler options and defines this
    module has been compiled with:
    OPTIONS:options\n
    DEFINES:defines\n
  - FILES(
    myfile.inc
    lib/mymodA
    )
  - a include file dependency section:
    INCLUDES(
    <fileidx> <CRC of myfile.inc>\n # fileidx is the LINE in the file section!
    )
  - a module dependency section:
    DEPS: <fileidx> <fileidx>\n
  - an interface section:
    INTERF(
    identifier1 id\n # id is the symbol's id
    identifier2 id\n
    )
  - a compiler proc section:
    COMPILERPROCS(
    identifier1 id\n # id is the symbol's id    
    )
  - an index consisting of (ID, linenumber)-pairs:
    INDEX(
    id-diff idx-diff\n
    id-diff idx-diff\n
    )
  - an import index consisting of (ID, moduleID)-pairs:
    IMPORTS(
    id-diff moduleID-diff\n
    id-diff moduleID-diff\n
    )
  - a list of all exported type converters because they are needed for correct
    semantic checking:
    CONVERTERS:id id\n   # position of the symbol in the DATA section
  - an AST section that contains the module's AST:
    INIT(
    idx\n  # position of the node in the DATA section
    idx\n
    )
  - a data section, where each type, symbol or AST is stored.
    DATA(
    type
    (node)
    sym
    )

  We now also do index compression, because an index always needs to be read.
*)

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, nos, options, strutils, nversion, ast, astalgo, msgs,
  platform, condsyms, ropes, idents, crc;

type
  TReasonForRecompile = (
    rrEmpty,     // used by moddeps module
    rrNone,      // no need to recompile
    rrRodDoesNotExist, // rod file does not exist
    rrRodInvalid, // rod file is invalid
    rrCrcChange, // file has been edited since last recompilation
    rrDefines,   // defines have changed
    rrOptions,   // options have changed
    rrInclDeps,  // an include has changed
    rrModDeps    // a module this module depends on has been changed
  );
const
  reasonToFrmt: array [TReasonForRecompile] of string = (
    '',
    'no need to recompile: $1',
    'symbol file for $1 does not exist',
    'symbol file for $1 has the wrong version',
    'file edited since last compilation: $1',
    'list of conditional symbols changed for: $1',
    'list of options changed for: $1',
    'an include file edited: $1',
    'a module $1 depends on has changed'
  );

type
  TIndex = record // an index with compression
    lastIdxKey, lastIdxVal: int;
    tab: TIITable;
    r: PRope;     // writers use this
    offset: int;  // readers use this
  end;
  TRodWriter = object(NObject)
    module: PSym;
    crc: TCrc32;
    options: TOptions;
    defines: PRope;
    inclDeps: PRope;
    modDeps: PRope;
    interf: PRope;
    compilerProcs: PRope;
    index, imports: TIndex;
    converters: PRope;
    init: PRope;
    data: PRope;
    filename: string;
    sstack: TSymSeq;  // a stack of symbols to process
    tstack: TTypeSeq; // a stack of types to process
    files: TStringSeq;
    moduleID: int;
  end;
  PRodWriter = ^TRodWriter;

  TRodReader = object(NObject)
    pos: int;    // position; used for parsing
    s: string;   // the whole file in memory
    options: TOptions;
    reason: TReasonForRecompile;
    modDeps: TStringSeq;
    files: TStringSeq;
    dataIdx: int;       // offset of start of data section
    convertersIdx: int; // offset of start of converters section
    initIdx, interfIdx, compilerProcsIdx: int;
    filename: string;
    index, imports: TIndex;
    readerIndex: int;
    line: int;          // only used for debugging, but is always in the code
    moduleID: int;
    syms: TIdTable;     // already processed symbols
  end;
  PRodReader = ^TRodReader;

const
  FileVersion = '1000'; // modify this if the rod-format changes!

var
  rodCompilerprocs: TStrTable; // global because this is needed by magicsys

function newRodWriter(const modfilename: string; crc: TCrc32;
                      moduleID: int): PRodWriter;
procedure addModDep(w: PRodWriter; const dep: string);
procedure addInclDep(w: PRodWriter; const dep: string);
procedure addInterfaceSym(w: PRodWriter; s: PSym);
procedure addPragma(w: PRodWriter; n: PNode);
procedure writeRod(w: PRodWriter);

function newRodReader(const modfilename: string; crc: TCrc32;
                      readerIndex: int): PRodReader;

procedure handleSymbolFile(const filename: string; module: PSym;
                           var rd: PRodReader;
                           var wr: PRodWriter);
function loadInitSection(r: PRodReader): PNode;

procedure loadStub(s: PSym);


implementation

var
  gTypeTable: TIdTable;

function rrGetSym(r: PRodReader; id: int; const info: TLineInfo): PSym; forward;
  // `info` is only used for debugging purposes

function rrGetType(r: PRodReader; id: int; const info: TLineInfo): PType; forward;
procedure processStacks(w: PRodWriter); forward;

function getDefines: PRope;
var
  it: TTabIter;
  s: PSym;
begin
  s := InitTabIter(it, gSymbols);
  result := nil;
  while s <> nil do begin
    if s.position = 1 then begin
      if result <> nil then app(result, ' '+'');
      app(result, s.name.s);
    end;
    s := nextIter(it, gSymbols);
  end
end;

function fileIdx(w: PRodWriter; const filename: string): int;
var
  i: int;
begin
  for i := 0 to high(w.files) do begin
    if w.files[i] = filename then begin result := i; exit end;
  end;
  result := length(w.files);
  setLength(w.files, result+1);
  w.files[result] := filename;
end;

function newRodWriter(const modfilename: string; crc: TCrc32;
                      moduleID: int): PRodWriter;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit
  result.sstack := [];}
{@emit
  result.tstack := [];}
  InitIITable(result.index.tab);
  InitIITable(result.imports.tab);
  result.filename := modfilename;
  result.crc := crc;
  result.moduleID := moduleID;
  result.defines := getDefines();
  result.options := options.gOptions;
  {@emit result.files := [];}
end;

function toBase62(x: BiggestInt): PRope; forward;
function encodeStr(w: PRodWriter; const s: string): PRope; forward;
function encode(const s: string): PRope; forward;
function decode(r: PRodReader): string; forward;
function rdBase62i(r: PRodReader): int; forward;
function rdBase62b(r: PRodReader): biggestInt; forward;

procedure addModDep(w: PRodWriter; const dep: string);
begin
  if w.modDeps <> nil then app(w.modDeps, ' '+'');
  app(w.modDeps, toBase62(fileIdx(w, dep)));
end;

const
  rodNL = #10+'';

procedure addInclDep(w: PRodWriter; const dep: string);
begin
  app(w.inclDeps, toBase62(fileIdx(w, dep)));
  app(w.inclDeps, ' '+'');
  app(w.inclDeps, toBase62(crcFromFile(dep)));
  app(w.inclDeps, rodNL);
end;

procedure pushType(w: PRodWriter; t: PType);
var
  L: int;
begin
  // check so that the stack does not grow too large:
  if IiTableGet(w.index.tab, t.id) = invalidKey then begin
    L := length(w.tstack);
    setLength(w.tstack, L+1);
    w.tstack[L] := t;
  end
end;

procedure pushSym(w: PRodWriter; s: PSym);
var
  L: int;
begin
  // check so that the stack does not grow too large:
  if IiTableGet(w.index.tab, s.id) = invalidKey then begin
    L := length(w.sstack);
    setLength(w.sstack, L+1);
    w.sstack[L] := s;
  end
end;

function encodeNode(w: PRodWriter; const fInfo: TLineInfo; n: PNode): PRope;
var
  i: int;
begin
  if n = nil then begin
    // nil nodes have to be stored too:
    result := toRope('()'); exit
  end;
  result := toRope('('+'');
  app(result, toBase62(ord(n.kind)));
  // we do not write comments for now
  // Line information takes easily 20% or more of the filesize! Therefore we
  // omit line information if it is the same as the father's line information:
  if (finfo.fileIndex <> n.info.fileIndex) then
    appf(result, '?$1,$2,$3', [toBase62(n.info.col), toBase62(n.info.line),
                               toBase62(fileIdx(w, toFilename(n.info)))])
  else if (finfo.line <> n.info.line) then
    appf(result, '?$1,$2', [toBase62(n.info.col), toBase62(n.info.line)])
  else if (finfo.col <> n.info.col) then
    appf(result, '?$1', [toBase62(n.info.col)]);
    // No need to output the file index, as this is the serialization of one
    // file.
  if n.flags <> {@set}[] then
    appf(result, '$$$1', [toBase62({@cast}int(n.flags))]);
  if n.typ <> nil then begin
    appf(result, '^$1', [toBase62(n.typ.id)]);
    pushType(w, n.typ);
  end;
  case n.kind of
    nkCharLit..nkInt64Lit: begin
      if n.intVal <> 0 then
        appf(result, '!$1', [toBase62(n.intVal)]);
    end;
    nkFloatLit..nkFloat64Lit: begin
      if n.floatVal <> 0.0 then
        appf(result, '!$1', [encodeStr(w, toStringF(n.floatVal))]);
    end;
    nkStrLit..nkTripleStrLit: begin
      if n.strVal <> '' then
        appf(result, '!$1', [encodeStr(w, n.strVal)]);
    end;
    nkIdent:
      appf(result, '!$1', [encodeStr(w, n.ident.s)]);
    nkSym: begin
      appf(result, '!$1', [toBase62(n.sym.id)]);
      pushSym(w, n.sym);
    end;
    else begin
      for i := 0 to sonsLen(n)-1 do
        app(result, encodeNode(w, n.info, n.sons[i]));
    end
  end;
  app(result, ')'+'');
end;

procedure writeRod(w: PRodWriter);
var
  content: PRope;
  i: int;
begin
  processStacks(w);
  // write header:
  content := toRope('NIM:');
  app(content, toRope(FileVersion));
  app(content, rodNL);
  app(content, toRope('ID:'));
  app(content, toBase62(w.moduleID));
  app(content, rodNL);
  app(content, toRope('CRC:'));
  app(content, toBase62(w.crc));
  app(content, rodNL);
  app(content, toRope('OPTIONS:'));
  app(content, toBase62({@cast}int(w.options)));
  app(content, rodNL);
  app(content, toRope('DEFINES:'));
  app(content, w.defines);
  app(content, rodNL);
  app(content, toRope('FILES('+rodNL));
  for i := 0 to high(w.files) do begin
    app(content, encode(w.files[i]));
    app(content, rodNL);
  end;
  app(content, toRope(')'+rodNL));
  app(content, toRope('INCLUDES('+rodNL));
  app(content, w.inclDeps);
  app(content, toRope(')'+rodNL));
  app(content, toRope('DEPS:'));
  app(content, w.modDeps);
  app(content, rodNL);
  app(content, toRope('INTERF('+rodNL));
  app(content, w.interf);
  app(content, toRope(')'+rodNL));
  app(content, toRope('COMPILERPROCS('+rodNL));
  app(content, w.compilerProcs);
  app(content, toRope(')'+rodNL));
  app(content, toRope('INDEX('+rodNL));
  app(content, w.index.r);
  app(content, toRope(')'+rodNL));
  app(content, toRope('IMPORTS('+rodNL));
  app(content, w.imports.r);
  app(content, toRope(')'+rodNL));
  app(content, toRope('CONVERTERS:'));
  app(content, w.converters);
  app(content, toRope(rodNL));
  app(content, toRope('INIT('+rodNL));
  app(content, w.init);
  app(content, toRope(')'+rodNL));
  app(content, toRope('DATA('+rodNL));
  app(content, w.data);
  app(content, toRope(')'+rodNL));

  //MessageOut('interf ' + ToString(ropeLen(w.interf)));
  //MessageOut('index ' + ToString(ropeLen(w.indexRope)));
  //MessageOut('init ' + ToString(ropeLen(w.init)));
  //MessageOut('data ' + ToString(ropeLen(w.data)));

  writeRope(content,
            completeGeneratedFilePath(changeFileExt(w.filename, 'rod')));
end;

procedure decodeLineInfo(r: PRodReader; var info: TLineInfo);
begin
  if r.s[r.pos] = '?' then begin
    inc(r.pos);
    if r.s[r.pos] = ',' then
      info.col := -1
    else
      info.col := rdBase62i(r);
    if r.s[r.pos] = ',' then begin
      inc(r.pos);
      if r.s[r.pos] = ',' then info.line := -1
      else info.line := rdBase62i(r);
      if r.s[r.pos] = ',' then begin
        inc(r.pos);
        info := newLineInfo(r.files[rdBase62i(r)], info.line, info.col);
      end
    end
  end
end;

function decodeNode(r: PRodReader; const fInfo: TLineInfo): PNode;
var
  id: int;
  fl: string;
begin
  result := nil;
  if r.s[r.pos] = '(' then begin
    inc(r.pos);
    if r.s[r.pos] = ')' then begin
      inc(r.pos); exit; // nil node
    end;
    result := newNodeI(TNodeKind(rdBase62i(r)), fInfo);
    decodeLineInfo(r, result.info);
    if r.s[r.pos] = '$' then begin
      inc(r.pos);
      result.flags := {@cast}TNodeFlags(rdBase62i(r));
    end;
    if r.s[r.pos] = '^' then begin
      inc(r.pos);
      id := rdBase62i(r);
      result.typ := rrGetType(r, id, result.info);
    end;
    case result.kind of
      nkCharLit..nkInt64Lit: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          result.intVal := rdBase62b(r);
        end
      end;
      nkFloatLit..nkFloat64Lit: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          fl := decode(r);
          result.floatVal := parseFloat(fl);
        end
      end;
      nkStrLit..nkTripleStrLit: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          result.strVal := decode(r);
        end
        else
          result.strVal := ''; // BUGFIX
      end;
      nkIdent: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          fl := decode(r);
          result.ident := getIdent(fl);
        end
        else
          internalError(result.info, 'decodeNode: nkIdent');
      end;
      nkSym: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          id := rdBase62i(r);
          result.sym := rrGetSym(r, id, result.info);
        end
        else
          internalError(result.info, 'decodeNode: nkSym');
      end;
      else begin
        while r.s[r.pos] <> ')' do
          addSon(result, decodeNode(r, result.info));
      end
    end;
    if r.s[r.pos] = ')' then inc(r.pos)
    else internalError(result.info, 'decodeNode');
  end
  else InternalError(result.info, 'decodeNode ' + r.s[r.pos])
end;

function encodeLoc(w: PRodWriter; const loc: TLoc): PRope;
begin
  result := nil;
  if loc.k <> low(loc.k) then
    app(result, toBase62(ord(loc.k)));
  if loc.s <> low(loc.s) then
    appf(result, '*$1', [toBase62(ord(loc.s))]);
  if loc.flags <> {@set}[] then
    appf(result, '$$$1', [toBase62({@cast}int(loc.flags))]);
  if loc.t <> nil then begin
    appf(result, '^$1', [toBase62(loc.t.id)]);
    pushType(w, loc.t);
  end;
  if loc.r <> nil then
    appf(result, '!$1', [encodeStr(w, ropeToStr(loc.r))]);
  if loc.a <> 0 then
    appf(result, '?$1', [toBase62(loc.a)]);
  if result <> nil then
    result := ropef('<$1>', [result]);
end;

procedure decodeLoc(r: PRodReader; var loc: TLoc; const info: TLineInfo);
begin
  if r.s[r.pos] = '<' then begin
    inc(r.pos);
    if r.s[r.pos] in ['0'..'9', 'a'..'z', 'A'..'Z'] then
      loc.k := TLocKind(rdBase62i(r))
    else
      loc.k := low(loc.k);
    if r.s[r.pos] = '*' then begin
      inc(r.pos);
      loc.s := TStorageLoc(rdBase62i(r));
    end
    else
      loc.s := low(loc.s);
    if r.s[r.pos] = '$' then begin
      inc(r.pos);
      loc.flags := {@cast}TLocFlags(rdBase62i(r));
    end
    else
      loc.flags := {@set}[];
    if r.s[r.pos] = '^' then begin
      inc(r.pos);
      loc.t := rrGetType(r, rdBase62i(r), info);
    end
    else
      loc.t := nil;
    if r.s[r.pos] = '!' then begin
      inc(r.pos);
      loc.r := toRope(decode(r));
    end
    else
      loc.r := nil;
    if r.s[r.pos] = '?' then begin
      inc(r.pos);
      loc.a := rdBase62i(r);
    end
    else
      loc.a := 0;
    if r.s[r.pos] = '>' then inc(r.pos)
    else InternalError(info, 'decodeLoc ' + r.s[r.pos]);
  end
end;

function encodeType(w: PRodWriter; t: PType): PRope;
var
  i: int;
begin
  if t = nil then begin
    // nil nodes have to be stored too:
    result := toRope('[]'); exit
  end;
  result := nil;
  if t.kind = tyForward then InternalError('encodeType: tyForward');
  app(result, toBase62(ord(t.kind)));
  appf(result, '+$1', [toBase62(t.id)]);
  if t.n <> nil then
    app(result, encodeNode(w, UnknownLineInfo(), t.n));
  if t.flags <> {@set}[] then
    appf(result, '$$$1', [toBase62({@cast}int(t.flags))]);
  if t.callConv <> low(t.callConv) then
    appf(result, '?$1', [toBase62(ord(t.callConv))]);
  if t.owner <> nil then begin
    appf(result, '*$1', [toBase62(t.owner.id)]);
    pushSym(w, t.owner);
  end;
  if t.sym <> nil then begin
    appf(result, '&$1', [toBase62(t.sym.id)]);
    pushSym(w, t.sym);
  end;
  if t.size <> -1 then appf(result, '/$1', [toBase62(t.size)]);
  if t.align <> 2 then appf(result, '=$1', [toBase62(t.align)]);
  if t.containerID <> 0 then
    appf(result, '@$1', [toBase62(t.containerID)]);
  app(result, encodeLoc(w, t.loc));
  for i := 0 to sonsLen(t)-1 do begin
    if t.sons[i] = nil then
      app(result, '^()')
    else begin
      appf(result, '^$1', [toBase62(t.sons[i].id)]);
      pushType(w, t.sons[i]);
    end
  end;
end;

function decodeType(r: PRodReader; const info: TLineInfo): PType;
var
  d: int;
begin
  result := nil;
  if r.s[r.pos] = '[' then begin
    inc(r.pos);
    if r.s[r.pos] = ']' then begin
      inc(r.pos); exit; // nil type
    end;
  end;
  new(result);
{@ignore}
  FillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := TTypeKind(rdBase62i(r));
  if r.s[r.pos] = '+' then begin
    inc(r.pos);
    result.id := rdBase62i(r);
    setId(result.id);
    if debugIds then registerID(result);
  end
  else
    InternalError(info, 'decodeType: no id');
  IdTablePut(gTypeTable, result, result); // here this also
  // avoids endless recursion for recursive type
  if r.s[r.pos] = '(' then
    result.n := decodeNode(r, UnknownLineInfo());
  if r.s[r.pos] = '$' then begin
    inc(r.pos);
    result.flags := {@cast}TTypeFlags(rdBase62i(r));
  end;
  if r.s[r.pos] = '?' then begin
    inc(r.pos);
    result.callConv := TCallingConvention(rdBase62i(r));
  end;
  if r.s[r.pos] = '*' then begin
    inc(r.pos);
    result.owner := rrGetSym(r, rdBase62i(r), info);
  end;
  if r.s[r.pos] = '&' then begin
    inc(r.pos);
    result.sym := rrGetSym(r, rdBase62i(r), info);
  end;
  if r.s[r.pos] = '/' then begin
    inc(r.pos);
    result.size := rdBase62i(r);
  end
  else result.size := -1;
  if r.s[r.pos] = '=' then begin
    inc(r.pos);
    result.align := rdBase62i(r);
  end
  else result.align := 2;
  if r.s[r.pos] = '@' then begin
    inc(r.pos);
    result.containerID := rdBase62i(r);
  end;
  decodeLoc(r, result.loc, info);
  while r.s[r.pos] = '^' do begin
    inc(r.pos);
    if r.s[r.pos] = '(' then begin
      inc(r.pos);
      if r.s[r.pos] = ')' then inc(r.pos)
      else InternalError(info, 'decodeType ^(' + r.s[r.pos]);
      addSon(result, nil);
    end
    else begin
      d := rdBase62i(r);
      addSon(result, rrGetType(r, d, info));
    end;
  end
end;

function encodeLib(w: PRodWriter; lib: PLib): PRope;
begin
  result := nil;
  appf(result, '|$1', [toBase62(ord(lib.kind))]);
  appf(result, '|$1', [encodeStr(w, ropeToStr(lib.name))]);
  appf(result, '|$1', [encodeStr(w, lib.path)]);
end;

function decodeLib(r: PRodReader): PLib;
begin
  result := nil;
  if r.s[r.pos] = '|' then begin
    new(result);
  {@ignore}
    fillChar(result^, sizeof(result^), 0);
  {@emit}
    inc(r.pos);
    result.kind := TLibKind(rdBase62i(r));
    if r.s[r.pos] <> '|' then InternalError('decodeLib: 1');
    inc(r.pos);
    result.name := toRope(decode(r));
    if r.s[r.pos] <> '|' then InternalError('decodeLib: 2');
    inc(r.pos);
    result.path := decode(r);
  end
end;

function astNeeded(w: PRodWriter; s: PSym): bool;
begin
  if (s.kind = skProc)
  and ([sfCompilerProc, sfCompileTime] * s.flags = [])
  and (s.typ.callConv <> ccInline)
  and (s.ast.sons[genericParamsPos] = nil) then
    result := false
  else
    result := true
end;

function encodeSym(w: PRodWriter; s: PSym): PRope;
var
  codeAst: PNode;
  col, line: PRope;
begin
  codeAst := nil;
  if s = nil then begin
    // nil nodes have to be stored too:
    result := toRope('{}'); exit
  end;
  result := nil;
  app(result, toBase62(ord(s.kind)));
  appf(result, '+$1', [toBase62(s.id)]);
  appf(result, '&$1', [encodeStr(w, s.name.s)]);
  if s.typ <> nil then begin
    appf(result, '^$1', [toBase62(s.typ.id)]);
    pushType(w, s.typ);
  end;
  if s.info.col = int16(-1) then col := nil
  else col := toBase62(s.info.col);
  if s.info.line = int16(-1) then line := nil
  else line := toBase62(s.info.line);
  appf(result, '?$1,$2,$3', [col, line,
       toBase62(fileIdx(w, toFilename(s.info)))]);
  if s.owner <> nil then begin
    appf(result, '*$1', [toBase62(s.owner.id)]);
    pushSym(w, s.owner);
  end;
  if s.flags <> {@set}[] then
    appf(result, '$$$1', [toBase62({@cast}int(s.flags))]);
  if s.magic <> mNone then
    appf(result, '@$1', [toBase62(ord(s.magic))]);
  if (s.ast <> nil) then begin
    if not astNeeded(w, s) then begin
      codeAst := s.ast.sons[codePos];
      s.ast.sons[codePos] := nil;
    end;
    app(result, encodeNode(w, s.info, s.ast));
    if codeAst <> nil then // restore code ast
      s.ast.sons[codePos] := codeAst;
  end;
  if s.options <> w.options then
    appf(result, '!$1', [toBase62({@cast}int(s.options))]);
  if s.position <> 0 then
    appf(result, '%$1', [toBase62(s.position)]);
  if s.offset <> -1 then
    appf(result, '`$1', [toBase62(s.offset)]);
  app(result, encodeLoc(w, s.loc));
  if s.annex <> nil then
    app(result, encodeLib(w, s.annex));
end;

function decodeSym(r: PRodReader; const info: TLineInfo): PSym;
var
  k: TSymKind;
  id: int;
  ident: PIdent;
begin
  result := nil;
  if r.s[r.pos] = '{' then begin
    inc(r.pos);
    if r.s[r.pos] = '}' then begin
      inc(r.pos); exit; // nil sym
    end
  end;
  k := TSymKind(rdBase62i(r));
  if r.s[r.pos] = '+' then begin
    inc(r.pos);
    id := rdBase62i(r);
    setId(id);
  end
  else
    InternalError(info, 'decodeSym: no id');
  if r.s[r.pos] = '&' then begin
    inc(r.pos);
    ident := getIdent(decode(r));
  end
  else
    InternalError(info, 'decodeSym: no ident');
  result := PSym(IdTableGet(r.syms, id));
  if result = nil then begin
    new(result);
  {@ignore}
    FillChar(result^, sizeof(result^), 0);
  {@emit}
    result.id := id;
    IdTablePut(r.syms, result, result);
    if debugIds then registerID(result);
  end
  else if (result.id <> id) then
    InternalError(info, 'decodeSym: wrong id');
  result.kind := k;
  result.name := ident;
  // read the rest of the symbol description:
  if r.s[r.pos] = '^' then begin
    inc(r.pos);
    result.typ := rrGetType(r, rdBase62i(r), info);
  end;
  decodeLineInfo(r, result.info);
  if r.s[r.pos] = '*' then begin
    inc(r.pos);
    result.owner := rrGetSym(r, rdBase62i(r), result.info);
  end;
  if r.s[r.pos] = '$' then begin
    inc(r.pos);
    result.flags := {@cast}TSymFlags(rdBase62i(r));
  end;
  if r.s[r.pos] = '@' then begin
    inc(r.pos);
    result.magic := TMagic(rdBase62i(r));
  end;
  if r.s[r.pos] = '(' then
    result.ast := decodeNode(r, result.info);
  if r.s[r.pos] = '!' then begin
    inc(r.pos);
    result.options := {@cast}TOptions(rdBase62i(r));
  end
  else
    result.options := r.options;
  if r.s[r.pos] = '%' then begin
    inc(r.pos);
    result.position := rdBase62i(r);
  end
  else
    result.position := 0; // BUGFIX: this may have been misused as reader index!
  if r.s[r.pos] = '`' then begin
    inc(r.pos);
    result.offset := rdBase62i(r);
  end
  else
    result.offset := -1;
  decodeLoc(r, result.loc, result.info);
  result.annex := decodeLib(r);
end;

procedure addToIndex(var w: TIndex; key, val: int);
begin
  if key - w.lastIdxKey = 1 then begin
    // we do not store a key-diff of 1 to safe space
    app(w.r, toBase62(val - w.lastIdxVal));
    app(w.r, rodNL);
  end
  else
    appf(w.r, '$1 $2'+rodNL, [toBase62(key - w.lastIdxKey),
                              toBase62(val - w.lastIdxVal)]);
  w.lastIdxKey := key;
  w.lastIdxVal := val;
  IiTablePut(w.tab, key, val);
end;

var
  debugWritten: TIntSet;

procedure symStack(w: PRodWriter);
var
  i, L: int;
  s, m: PSym;
begin
  i := 0;
  while i < length(w.sstack) do begin
    s := w.sstack[i];
    if IiTableGet(w.index.tab, s.id) = invalidKey then begin
      m := getModule(s);
      if m = nil then InternalError('symStack: module nil: ' + s.name.s);
      if (m.id = w.module.id) or (sfFromGeneric in s.flags)
      or (s.kind in [skParam, skForVar, skTemp]) then begin
        // put definition in here
        L := ropeLen(w.data);
        addToIndex(w.index, s.id, L);
        //intSetIncl(debugWritten, s.id);
        app(w.data, encodeSym(w, s));
        app(w.data, rodNL);
      end
      else if IiTableGet(w.imports.tab, s.id) = invalidKey then begin
        addToIndex(w.imports, s.id, m.id);
        //if not IntSetContains(debugWritten, s.id) then begin 
        //  MessageOut(w.filename);
        //  debug(s.owner);
        //  debug(s);
        //  InternalError('BUG!!!!');
        //end
      end
    end;
    inc(i);
  end;
  setLength(w.sstack, 0);
end;

procedure typeStack(w: PRodWriter);
var
  i, L: int;
begin
  i := 0;
  while i < length(w.tstack) do begin
    if IiTableGet(w.index.tab, w.tstack[i].id) = invalidKey then begin
      L := ropeLen(w.data);
      addToIndex(w.index, w.tstack[i].id, L);
      app(w.data, encodeType(w, w.tstack[i]));
      app(w.data, rodNL);
    end;
    inc(i);
  end;
  setLength(w.tstack, 0);
end;

procedure processStacks(w: PRodWriter);
begin
  while (length(w.tstack) > 0) or (length(w.sstack) > 0) do begin
    symStack(w);
    typeStack(w);
  end
end;

procedure rawAddInterfaceSym(w: PRodWriter; s: PSym);
begin
  pushSym(w, s);
  processStacks(w);
  if sfInInterface in s.flags then
    appf(w.interf, '$1 $2'+rodNL, [encode(s.name.s), toBase62(s.id)]);
  if sfCompilerProc in s.flags then
    appf(w.compilerProcs, '$1 $2'+rodNL, [encode(s.name.s), toBase62(s.id)]);
  if s.kind = skConverter then begin
    if w.converters <> nil then app(w.converters, ' '+'');
    app(w.converters, toBase62(s.id))
  end
end;

procedure addInterfaceSym(w: PRodWriter; s: PSym);
begin
  if w = nil then exit;
  if [sfInInterface, sfCompilerProc] * s.flags <> [] then begin
    rawAddInterfaceSym(w, s);
  end
end;

procedure addPragma(w: PRodWriter; n: PNode);
begin
  app(w.init, toBase62(ropeLen(w.data)));
  app(w.init, rodNL);
  app(w.data, encodeNode(w, UnknownLineInfo(), n));
  app(w.data, rodNL);
  processStacks(w);
end;

procedure toBase62Aux(var str: string; x: BiggestInt);
const
  chars: string =
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  v, rem: biggestInt;
  d: char;
begin
  v := x;
  rem := v mod 62;
  if (rem < 0) then begin
    str := str + '-';
    v := -(v div 62);
    rem := -rem;
  end
  else
    v := v div 62;
  d := chars[int(rem)+strStart];
  if (v <> 0) then toBase62Aux(str, v);
  addChar(str, d);
end;

function toBase62(x: BiggestInt): PRope;
var
  res: string;
begin
  res := '';
  toBase62Aux(res, x);
  result := toRope(res);
end;

function rdBase62i(r: PRodReader): int;
var
  i: int;
  sign: int;
begin
  i := r.pos;
  sign := -1;
  assert(r.s[i] in ['0'..'9', 'a'..'z', 'A'..'Z', '-']);
  if r.s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  result := 0;
  while true do begin
    case r.s[i] of
      '0'..'9': result := result * 62 - (ord(r.s[i]) - ord('0'));
      'a'..'z': result := result * 62 - (ord(r.s[i]) - ord('a') + 10);
      'A'..'Z': result := result * 62 - (ord(r.s[i]) - ord('A') + 36);
      else break;
    end;
    inc(i)
  end;
  result := result * sign;
  r.pos := i
end;

function rdBase62b(r: PRodReader): biggestInt;
var
  i: int;
  sign: biggestInt;
begin
  i := r.pos;
  sign := -1;
  assert(r.s[i] in ['0'..'9', 'a'..'z', 'A'..'Z', '-']);
  if r.s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  result := 0;
  while true do begin
    case r.s[i] of
      '0'..'9': result := result * 62 - (ord(r.s[i]) - ord('0'));
      'a'..'z': result := result * 62 - (ord(r.s[i]) - ord('a') + 10);
      'A'..'Z': result := result * 62 - (ord(r.s[i]) - ord('A') + 36);
      else break;
    end;
    inc(i)
  end;
  result := result * sign;
  r.pos := i
end;

function encode(const s: string): PRope;
var
  i: int;
  res: string;
begin
  res := '';
  for i := strStart to length(s)+strStart-1 do begin
    case s[i] of
      '0'..'9', 'a'..'z', 'A'..'Z', '_':
        addChar(res, s[i]);
      else
        res := res +{&} '\' +{&} toHex(ord(s[i]), 2)
    end
  end;
  result := toRope(res);
end;

function encodeStr(w: PRodWriter; const s: string): PRope;
begin
  result := encode(s)
end;

procedure hexChar(c: char; var xi: int);
begin
  case c of
    '0'..'9': xi := (xi shl 4) or (ord(c) - ord('0'));
    'a'..'f': xi := (xi shl 4) or (ord(c) - ord('a') + 10);
    'A'..'F': xi := (xi shl 4) or (ord(c) - ord('A') + 10);
    else begin end
  end
end;

function decode(r: PRodReader): string;
var
  i, xi: int;
begin
  i := r.pos;
  result := '';
  while true do begin
    case r.s[i] of
      '\': begin
        inc(i, 3); xi := 0;
        hexChar(r.s[i-2], xi);
        hexChar(r.s[i-1], xi);
        addChar(result, chr(xi));
      end;
      'a'..'z', '0'..'9', 'A'..'Z', '_': begin
        addChar(result, r.s[i]);
        inc(i);
      end
      else break
    end
  end;
  r.pos := i;
end;

procedure skipSection(r: PRodReader);
var
  c: int;
begin
  if r.s[r.pos] = ':' then begin
    while r.s[r.pos] > #10 do inc(r.pos);
  end
  else if r.s[r.pos] = '(' then begin
    c := 0; // count () pairs
    inc(r.pos);
    while true do begin
      case r.s[r.pos] of
        #10: inc(r.line);
        '(': inc(c);
        ')': begin
          if c = 0 then begin inc(r.pos); break end
          else if c > 0 then dec(c);
        end;
        #0: break; // end of file
        else begin end;
      end;
      inc(r.pos);
    end
  end
  else
    InternalError('skipSection ' + toString(r.line));
end;

function rdWord(r: PRodReader): string;
begin
  result := '';
  while r.s[r.pos] in ['A'..'Z', '_', 'a'..'z', '0'..'9'] do begin
    addChar(result, r.s[r.pos]);
    inc(r.pos);
  end;
end;

function newStub(r: PRodReader; const name: string; id: int): PSym;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := skStub;
  result.id := id;
  result.name := getIdent(name);
  result.position := r.readerIndex;
  setID(id);
  if debugIds then registerID(result);
end;

procedure processInterf(r: PRodReader; module: PSym);
var
  s: PSym;
  w: string;
  key: int;
begin
  if r.interfIdx = 0 then InternalError('processInterf');
  r.pos := r.interfIdx;
  while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
    w := decode(r);
    inc(r.pos);
    key := rdBase62i(r);
    inc(r.pos); // #10
    s := newStub(r, w, key);
    s.owner := module;
    StrTableAdd(module.tab, s);
    IdTablePut(r.syms, s, s);
  end;
end;

procedure processCompilerProcs(r: PRodReader; module: PSym);
var
  s: PSym;
  w: string;
  key: int;
begin
  if r.compilerProcsIdx = 0 then InternalError('processCompilerProcs');
  r.pos := r.compilerProcsIdx;
  while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
    w := decode(r);
    inc(r.pos);
    key := rdBase62i(r);
    inc(r.pos); // #10
    s := PSym(IdTableGet(r.syms, key));
    if s = nil then begin
      s := newStub(r, w, key);
      s.owner := module;
      IdTablePut(r.syms, s, s);
    end;
    StrTableAdd(rodCompilerProcs, s);
  end;
end;

procedure processIndex(r: PRodReader; var idx: TIndex);
var
  key, val, tmp: int;
begin
  inc(r.pos, 2); // skip "(\10"
  inc(r.line);
  while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
    tmp := rdBase62i(r);
    if r.s[r.pos] = ' ' then begin
      inc(r.pos);
      key := idx.lastIdxKey + tmp;
      val := rdBase62i(r) + idx.lastIdxVal;
    end
    else begin
      key := idx.lastIdxKey + 1;
      val := tmp + idx.lastIdxVal;
    end;
    IITablePut(idx.tab, key, val);
    idx.lastIdxKey := key;
    idx.lastIdxVal := val;
    setID(key); // ensure that this id will not be used
    if r.s[r.pos] = #10 then begin inc(r.pos); inc(r.line) end;
  end;
  if r.s[r.pos] = ')' then inc(r.pos);
end;

procedure processRodFile(r: PRodReader; crc: TCrc32);
var
  section, w: string;
  d, L, inclCrc: int;
begin
  while r.s[r.pos] <> #0 do begin
    section := rdWord(r);
    if r.reason <> rrNone then break; // no need to process this file further
    if section = 'CRC' then begin
      inc(r.pos); // skip ':'
      if int(crc) <> rdBase62i(r) then
        r.reason := rrCrcChange
    end
    else if section = 'ID' then begin
      inc(r.pos); // skip ':'
      r.moduleID := rdBase62i(r);
      setID(r.moduleID);
    end
    else if section = 'OPTIONS' then begin
      inc(r.pos); // skip ':'
      r.options := {@cast}TOptions(rdBase62i(r));
      if options.gOptions <> r.options then r.reason := rrOptions
    end
    else if section = 'DEFINES' then begin
      inc(r.pos); // skip ':'
      d := 0;
      while r.s[r.pos] > #10 do begin
        w := decode(r);
        inc(d);
        if not condsyms.isDefined(getIdent(w)) then begin
          r.reason := rrDefines;
          //MessageOut('not defined, but should: ' + w);
        end;
        if r.s[r.pos] = ' ' then inc(r.pos);
      end;
      if (d <> countDefinedSymbols()) then
        r.reason := rrDefines
    end
    else if section = 'FILES' then begin
      inc(r.pos, 2); // skip "(\10"
      inc(r.line);
      L := 0;
      while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
        setLength(r.files, L+1);
        r.files[L] := decode(r);
        inc(r.pos); // skip #10
        inc(r.line);
        inc(L);
      end;
      if r.s[r.pos] = ')' then inc(r.pos);
    end
    else if section = 'INCLUDES' then begin
      inc(r.pos, 2); // skip "(\10"
      inc(r.line);
      while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
        w := r.files[rdBase62i(r)];
        inc(r.pos); // skip ' '
        inclCrc := rdBase62i(r);
        if r.reason = rrNone then begin
          if not ExistsFile(w) or (inclCrc <> int(crcFromFile(w))) then
            r.reason := rrInclDeps
        end;
        if r.s[r.pos] = #10 then begin inc(r.pos); inc(r.line) end;
      end;
      if r.s[r.pos] = ')' then inc(r.pos);
    end
    else if section = 'DEPS' then begin
      inc(r.pos); // skip ':'
      L := 0;
      while (r.s[r.pos] > #10) do begin
        setLength(r.modDeps, L+1);
        r.modDeps[L] := r.files[rdBase62i(r)];
        inc(L);
        if r.s[r.pos] = ' ' then inc(r.pos);
      end;
    end
    else if section = 'INTERF' then begin
      r.interfIdx := r.pos+2;
      skipSection(r);
    end
    else if section = 'COMPILERPROCS' then begin
      r.compilerProcsIdx := r.pos+2;
      skipSection(r);
    end
    else if section = 'INDEX' then begin
      processIndex(r, r.index);
    end
    else if section = 'IMPORTS' then begin
      processIndex(r, r.imports);
    end
    else if section = 'CONVERTERS' then begin
      r.convertersIdx := r.pos+1;
      skipSection(r);
    end
    else if section = 'DATA' then begin
      r.dataIdx := r.pos+2; // "(\10"
      // We do not read the DATA section here! We read the needed objects on
      // demand.
      skipSection(r);
    end
    else if section = 'INIT' then begin
      r.initIdx := r.pos+2; // "(\10"
      skipSection(r);
    end
    else begin
      MessageOut('skipping section: ' + toString(r.pos));
      skipSection(r);
    end;
    if r.s[r.pos] = #10 then begin inc(r.pos); inc(r.line) end;
  end
end;

function newRodReader(const modfilename: string; crc: TCrc32;
                      readerIndex: int): PRodReader;
var
  version: string;
  r: PRodReader;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit result.files := [];}
{@emit result.modDeps := [];}
  r := result;
  r.reason := rrNone;
  r.pos := strStart;
  r.line := 1;
  r.readerIndex := readerIndex;
  r.filename := modfilename;    
  InitIdTable(r.syms);
  r.s := readFile(modfilename) {@ignore} + #0 {@emit};
  if startsWith(r.s, 'NIM:') then begin
    initIITable(r.index.tab);
    initIITable(r.imports.tab);
    // looks like a ROD file
    inc(r.pos, 4);
    version := '';
    while not (r.s[r.pos] in [#0,#10]) do begin
      addChar(version, r.s[r.pos]);
      inc(r.pos);
    end;
    if r.s[r.pos] = #10 then inc(r.pos);
    if version = FileVersion then begin
      // since ROD files are only for caching, no backwarts compability is
      // needed
      processRodFile(r, crc);
    end
    else
      result := nil
  end
  else
    result := nil;
end;

function rrGetType(r: PRodReader; id: int; const info: TLineInfo): PType;
var
  oldPos, d: int;
begin
  result := PType(IdTableGet(gTypeTable, id));
  if result = nil then begin
    // load the type:
    oldPos := r.pos;
    d := IITableGet(r.index.tab, id);
    if d = invalidKey then InternalError(info, 'rrGetType');
    r.pos := d + r.dataIdx;
    result := decodeType(r, info);
    r.pos := oldPos;
  end;
end;

type
  TFileModuleRec = record
    filename: string;
    reason: TReasonForRecompile;
    rd: PRodReader;
    wr: PRodWriter;
  end;
  TFileModuleMap = array of TFileModuleRec;
var
  gMods: TFileModuleMap = {@ignore} nil {@emit []}; // all compiled modules

function decodeSymSafePos(rd: PRodReader; offset: int;
                          const info: TLineInfo): PSym;
var
  oldPos: int;
begin
  if rd.dataIdx = 0 then InternalError(info, 'dataIdx == 0');
  oldPos := rd.pos;
  rd.pos := offset + rd.dataIdx;
  result := decodeSym(rd, info);
  rd.pos := oldPos;
end;

function rrGetSym(r: PRodReader; id: int; const info: TLineInfo): PSym;
var
  d, i, moduleID: int;
  rd: PRodReader;
begin
  result := PSym(IdTableGet(r.syms, id));
  if result = nil then begin
    // load the symbol:
    d := IITableGet(r.index.tab, id);
    if d = invalidKey then begin
      moduleID := IiTableGet(r.imports.tab, id);
      if moduleID < 0 then
        InternalError(info,
          'missing from both indexes: +' + ropeToStr(toBase62(id)));
      // find the reader with the correct moduleID:
      for i := 0 to high(gMods) do begin
        rd := gMods[i].rd;
        if (rd <> nil) then begin
          if (rd.moduleID = moduleID) then begin
            d := IITableGet(rd.index.tab, id);
            if d <> invalidKey then begin
              result := decodeSymSafePos(rd, d, info);
              break
            end
            else
              InternalError(info,
                'rrGetSym: no reader found: +' + ropeToStr(toBase62(id)));
          end
          else begin
            //if IiTableGet(rd.index.tab, id) <> invalidKey then
            // XXX expensive check!
              //InternalError(info,
              //'id found in other module: +' + ropeToStr(toBase62(id)))
          end
        end
      end;
    end
    else begin
      // own symbol:
      result := decodeSymSafePos(r, d, info);
    end;
  end;
  if (result <> nil) and (result.kind = skStub) then loadStub(result);
end;

function loadInitSection(r: PRodReader): PNode;
var
  d, oldPos, p: int;
begin
  if (r.initIdx = 0) or (r.dataIdx = 0) then InternalError('loadInitSection');
  oldPos := r.pos;
  r.pos := r.initIdx;
  result := newNode(nkStmtList);
  while (r.s[r.pos] > #10) and (r.s[r.pos] <> ')') do begin
    d := rdBase62i(r);
    inc(r.pos); // #10
    p := r.pos;
    r.pos := d + r.dataIdx;
    addSon(result, decodeNode(r, UnknownLineInfo()));
    r.pos := p;
  end;
  r.pos := oldPos;
end;

procedure loadConverters(r: PRodReader);
var
  d: int;
begin
  // We have to ensure that no exported converter is a stub anymore.
  if (r.convertersIdx = 0) or (r.dataIdx = 0) then
    InternalError('importConverters');
  r.pos := r.convertersIdx;
  while (r.s[r.pos] > #10) do begin
    d := rdBase62i(r);
    {@discard} rrGetSym(r, d, UnknownLineInfo());
    if r.s[r.pos] = ' ' then inc(r.pos)
  end;
end;

function getModuleIdx(const filename: string): int;
var
  i: int;
begin
  for i := 0 to high(gMods) do
    if sameFile(gMods[i].filename, filename) then begin
      result := i; exit
    end;
  // not found, reserve space:
  result := length(gMods);
  setLength(gMods, result+1);
end;

function checkDep(const filename: string): TReasonForRecompile;
var
  crc: TCrc32;
  r: PRodReader;
  w: PRodWriter;
  rodfile: string;
  idx, i: int;
  res: TReasonForRecompile;
begin
  idx := getModuleIdx(filename);
  if gMods[idx].reason <> rrEmpty then begin
    // reason has already been computed for this module:
    result := gMods[idx].reason; exit
  end;
  gMods[idx].reason := rrNone; // we need to set it here to avoid cycles
  gMods[idx].filename := filename;
  result := rrNone;
  r := nil;
  w := nil;
  crc := crcFromFile(filename);
  rodfile := toGeneratedFile(filename, RodExt);
  if ExistsFile(rodfile) then begin
    r := newRodReader(rodfile, crc, idx);
    if r = nil then
      result := rrRodInvalid
    else begin
      result := r.reason;
      if result = rrNone then begin
        // check modules it depends on
        // NOTE: we need to process the entire module graph so that no ID will
        // be used twice! However, compilation speed does not suffer much from
        // this, since results are cached.
        res := checkDep(JoinPath(options.libpath, 
                        appendFileExt('system', nimExt)));
        if res <> rrNone then result := rrModDeps;
        for i := 0 to high(r.modDeps) do begin
          res := checkDep(r.modDeps[i]);
          if res <> rrNone then begin
            result := rrModDeps;
            //break // BUGFIX: cannot break here!
          end
        end
      end
    end
  end
  else
    result := rrRodDoesNotExist;
  if (result <> rrNone) and (gVerbosity > 0) then
    MessageOut(format(reasonToFrmt[result], [filename]));
  if (result <> rrNone) or (optForceFullMake in gGlobalOptions) then begin
    // recompilation is necessary:
    if r <> nil then
      w := newRodWriter(filename, crc, r.moduleID)
    else
      w := newRodWriter(filename, crc, getID());
    r := nil;
  end;
  gMods[idx].rd := r;
  gMods[idx].wr := w;
  gMods[idx].reason := result; // now we know better
end;

procedure handleSymbolFile(const filename: string; module: PSym;
                           var rd: PRodReader; var wr: PRodWriter);
var
  idx: int;
begin
  if not (optSymbolFiles in gGlobalOptions) then begin
    module.id := getID();
    exit
  end;
  {@discard} checkDep(filename);
  idx := getModuleIdx(filename);
  if gMods[idx].reason = rrEmpty then InternalError('handleSymbolFile');
  rd := gMods[idx].rd;
  wr := gMods[idx].wr;
  if rd <> nil then begin
    module.id := rd.moduleID;
    IdTablePut(rd.syms, module, module);
    processInterf(rd, module);
    processCompilerProcs(rd, module);
    loadConverters(rd);
  end
  else if wr <> nil then begin
    wr.module := module;
    module.id := wr.moduleID;
    rawAddInterfaceSym(wr, module)
  end
  else
    module.id := getID();
end;

procedure loadStub(s: PSym);
var
  rd: PRodReader;
  d, theId: int;
  rs: PSym;
begin
  if s.kind <> skStub then InternalError('loadStub');
  //MessageOut('loading stub: ' + s.name.s);
  rd := gMods[s.position].rd;
  theId := s.id; // used for later check
  d := IITableGet(rd.index.tab, s.id);
  if d = invalidKey then InternalError('loadStub: invalid key');
  rs := decodeSymSafePos(rd, d, UnknownLineInfo());
  if rs <> s then InternalError(rs.info, 'loadStub: wrong symbol')
  else if rs.id <> theId then InternalError(rs.info, 'loadStub: wrong ID');
  //MessageOut('loaded stub: ' + s.name.s);
end;

initialization
  InitIdTable(gTypeTable);
  InitStrTable(rodCompilerProcs);
  IntSetInit(debugWritten);
end.
