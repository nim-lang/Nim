//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit rodwrite;

// This module is responsible for writing of rod files. Note that writing of
// rod files is a pass, reading of rod files is not! This is why reading and
// writing of rod files is split into two different modules.

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, nos, options, strutils, nversion, ast, astalgo, msgs,
  platform, condsyms, ropes, idents, crc, rodread, passes, importer;

function rodwritePass(): TPass;

implementation

type
  TRodWriter = object(TPassContext)
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
  end;
  PRodWriter = ^TRodWriter;

function newRodWriter(const modfilename: string; crc: TCrc32;
                      module: PSym): PRodWriter; forward;
procedure addModDep(w: PRodWriter; const dep: string); forward;
procedure addInclDep(w: PRodWriter; const dep: string); forward;
procedure addInterfaceSym(w: PRodWriter; s: PSym); forward;
procedure addStmt(w: PRodWriter; n: PNode); forward;
procedure writeRod(w: PRodWriter); forward;

function encodeStr(w: PRodWriter; const s: string): PRope;
begin
  result := encode(s)
end;

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
                      module: PSym): PRodWriter;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit
  result.sstack := @[];}
{@emit
  result.tstack := @[];}
  InitIITable(result.index.tab);
  InitIITable(result.imports.tab);
  result.filename := modfilename;
  result.crc := crc;
  result.module := module;
  result.defines := getDefines();
  result.options := options.gOptions;
  {@emit result.files := @[];}
end;

procedure addModDep(w: PRodWriter; const dep: string);
begin
  if w.modDeps <> nil then app(w.modDeps, ' '+'');
  app(w.modDeps, encodeInt(fileIdx(w, dep)));
end;

const
  rodNL = #10+'';

procedure addInclDep(w: PRodWriter; const dep: string);
begin
  app(w.inclDeps, encodeInt(fileIdx(w, dep)));
  app(w.inclDeps, ' '+'');
  app(w.inclDeps, encodeInt(crcFromFile(dep)));
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
  f: TNodeFlags;
begin
  if n = nil then begin
    // nil nodes have to be stored too:
    result := toRope('()'); exit
  end;
  result := toRope('('+'');
  app(result, encodeInt(ord(n.kind)));
  // we do not write comments for now
  // Line information takes easily 20% or more of the filesize! Therefore we
  // omit line information if it is the same as the father's line information:
  if (finfo.fileIndex <> n.info.fileIndex) then
    appf(result, '?$1,$2,$3', [encodeInt(n.info.col), encodeInt(n.info.line),
                               encodeInt(fileIdx(w, toFilename(n.info)))])
  else if (finfo.line <> n.info.line) then
    appf(result, '?$1,$2', [encodeInt(n.info.col), encodeInt(n.info.line)])
  else if (finfo.col <> n.info.col) then
    appf(result, '?$1', [encodeInt(n.info.col)]);
    // No need to output the file index, as this is the serialization of one
    // file.
  f := n.flags * PersistentNodeFlags;
  if f <> {@set}[] then
    appf(result, '$$$1', [encodeInt({@cast}int32(f))]);
  if n.typ <> nil then begin
    appf(result, '^$1', [encodeInt(n.typ.id)]);
    pushType(w, n.typ);
  end;
  case n.kind of
    nkCharLit..nkInt64Lit: begin
      if n.intVal <> 0 then
        appf(result, '!$1', [encodeInt(n.intVal)]);
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
      appf(result, '!$1', [encodeInt(n.sym.id)]);
      pushSym(w, n.sym);
    end;
    else begin
      for i := 0 to sonsLen(n)-1 do
        app(result, encodeNode(w, n.info, n.sons[i]));
    end
  end;
  app(result, ')'+'');
end;

function encodeLoc(w: PRodWriter; const loc: TLoc): PRope;
begin
  result := nil;
  if loc.k <> low(loc.k) then
    app(result, encodeInt(ord(loc.k)));
  if loc.s <> low(loc.s) then
    appf(result, '*$1', [encodeInt(ord(loc.s))]);
  if loc.flags <> {@set}[] then
    appf(result, '$$$1', [encodeInt({@cast}int32(loc.flags))]);
  if loc.t <> nil then begin
    appf(result, '^$1', [encodeInt(loc.t.id)]);
    pushType(w, loc.t);
  end;
  if loc.r <> nil then
    appf(result, '!$1', [encodeStr(w, ropeToStr(loc.r))]);
  if loc.a <> 0 then
    appf(result, '?$1', [encodeInt(loc.a)]);
  if result <> nil then
    result := ropef('<$1>', [result]);
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
  app(result, encodeInt(ord(t.kind)));
  appf(result, '+$1', [encodeInt(t.id)]);
  if t.n <> nil then
    app(result, encodeNode(w, UnknownLineInfo(), t.n));
  if t.flags <> {@set}[] then
    appf(result, '$$$1', [encodeInt({@cast}int32(t.flags))]);
  if t.callConv <> low(t.callConv) then
    appf(result, '?$1', [encodeInt(ord(t.callConv))]);
  if t.owner <> nil then begin
    appf(result, '*$1', [encodeInt(t.owner.id)]);
    pushSym(w, t.owner);
  end;
  if t.sym <> nil then begin
    appf(result, '&$1', [encodeInt(t.sym.id)]);
    pushSym(w, t.sym);
  end;
  if t.size <> -1 then appf(result, '/$1', [encodeInt(t.size)]);
  if t.align <> 2 then appf(result, '=$1', [encodeInt(t.align)]);
  if t.containerID <> 0 then
    appf(result, '@$1', [encodeInt(t.containerID)]);
  app(result, encodeLoc(w, t.loc));
  for i := 0 to sonsLen(t)-1 do begin
    if t.sons[i] = nil then
      app(result, '^()')
    else begin
      appf(result, '^$1', [encodeInt(t.sons[i].id)]);
      pushType(w, t.sons[i]);
    end
  end;
end;

function encodeLib(w: PRodWriter; lib: PLib): PRope;
begin
  result := nil;
  appf(result, '|$1', [encodeInt(ord(lib.kind))]);
  appf(result, '|$1', [encodeStr(w, ropeToStr(lib.name))]);
  appf(result, '|$1', [encodeStr(w, lib.path)]);
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
  app(result, encodeInt(ord(s.kind)));
  appf(result, '+$1', [encodeInt(s.id)]);
  appf(result, '&$1', [encodeStr(w, s.name.s)]);
  if s.typ <> nil then begin
    appf(result, '^$1', [encodeInt(s.typ.id)]);
    pushType(w, s.typ);
  end;
  if s.info.col = int16(-1) then col := nil
  else col := encodeInt(s.info.col);
  if s.info.line = int16(-1) then line := nil
  else line := encodeInt(s.info.line);
  appf(result, '?$1,$2,$3', [col, line,
       encodeInt(fileIdx(w, toFilename(s.info)))]);
  if s.owner <> nil then begin
    appf(result, '*$1', [encodeInt(s.owner.id)]);
    pushSym(w, s.owner);
  end;
  if s.flags <> {@set}[] then
    appf(result, '$$$1', [encodeInt({@cast}int32(s.flags))]);
  if s.magic <> mNone then
    appf(result, '@$1', [encodeInt(ord(s.magic))]);
  if (s.ast <> nil) then begin
    if not astNeeded(s) then begin
      codeAst := s.ast.sons[codePos];
      s.ast.sons[codePos] := nil;
    end;
    app(result, encodeNode(w, s.info, s.ast));
    if codeAst <> nil then // restore code ast
      s.ast.sons[codePos] := codeAst;
  end;
  if s.options <> w.options then
    appf(result, '!$1', [encodeInt({@cast}int32(s.options))]);
  if s.position <> 0 then
    appf(result, '%$1', [encodeInt(s.position)]);
  if s.offset <> -1 then
    appf(result, '`$1', [encodeInt(s.offset)]);
  app(result, encodeLoc(w, s.loc));
  if s.annex <> nil then
    app(result, encodeLib(w, s.annex));
end;

procedure addToIndex(var w: TIndex; key, val: int);
begin
  if key - w.lastIdxKey = 1 then begin
    // we do not store a key-diff of 1 to safe space
    app(w.r, encodeInt(val - w.lastIdxVal));
    app(w.r, rodNL);
  end
  else
    appf(w.r, '$1 $2'+rodNL, [encodeInt(key - w.lastIdxKey),
                              encodeInt(val - w.lastIdxVal)]);
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
      if (m.id = w.module.id) or (sfFromGeneric in s.flags) then begin
        // put definition in here
        L := ropeLen(w.data);
        addToIndex(w.index, s.id, L);
        //intSetIncl(debugWritten, s.id);
        app(w.data, encodeSym(w, s));
        app(w.data, rodNL);
        if sfInInterface in s.flags then
          appf(w.interf, '$1 $2'+rodNL, [encode(s.name.s), encodeInt(s.id)]);
        if sfCompilerProc in s.flags then
          appf(w.compilerProcs, '$1 $2'+rodNL, [encode(s.name.s), encodeInt(s.id)]);
        if s.kind = skConverter then begin
          if w.converters <> nil then app(w.converters, ' '+'');
          app(w.converters, encodeInt(s.id))
        end
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
end;

procedure addInterfaceSym(w: PRodWriter; s: PSym);
begin
  if w = nil then exit;
  if [sfInInterface, sfCompilerProc] * s.flags <> [] then begin
    rawAddInterfaceSym(w, s);
  end
end;

procedure addStmt(w: PRodWriter; n: PNode);
begin
  app(w.init, encodeInt(ropeLen(w.data)));
  app(w.init, rodNL);
  app(w.data, encodeNode(w, UnknownLineInfo(), n));
  app(w.data, rodNL);
  processStacks(w);
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
  app(content, encodeInt(w.module.id));
  app(content, rodNL);
  app(content, toRope('CRC:'));
  app(content, encodeInt(w.crc));
  app(content, rodNL);
  app(content, toRope('OPTIONS:'));
  app(content, encodeInt({@cast}int32(w.options)));
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

function process(c: PPassContext; n: PNode): PNode;
var
  i: int;
  w: PRodWriter;
  a: PNode;
  s: PSym;
begin
  result := n;
  if c = nil then exit;
  w := PRodWriter(c);
  case n.kind of 
    nkStmtList: begin
      for i := 0 to sonsLen(n)-1 do {@discard} process(c, n.sons[i]);
    end;
    nkTemplateDef, nkMacroDef: begin
      s := n.sons[namePos].sym;
      addInterfaceSym(w, s);    
    end; 
    nkProcDef, nkMethodDef, nkIteratorDef, nkConverterDef: begin
      s := n.sons[namePos].sym;
      if s = nil then InternalError(n.info, 'rodwrite.process');
      if (n.sons[codePos] <> nil) or (s.magic <> mNone)
      or not (sfForward in s.flags) then begin
        addInterfaceSym(w, s);
      end
    end;
    nkVarSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if a.kind <> nkIdentDefs then InternalError(a.info, 'rodwrite.process');
        addInterfaceSym(w, a.sons[0].sym);
      end
    end;
    nkConstSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if a.kind <> nkConstDef then InternalError(a.info, 'rodwrite.process');
        addInterfaceSym(w, a.sons[0].sym);
      end
    end;
    nkTypeSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if a.sons[0].kind <> nkSym then
          InternalError(a.info, 'rodwrite.process');
        s := a.sons[0].sym;
        addInterfaceSym(w, s); // this takes care of enum fields too
        // Note: The check for ``s.typ.kind = tyEnum`` is wrong for enum
        // type aliasing! Otherwise the same enum symbol would be included
        // several times!
        (*
        if (a.sons[2] <> nil) and (a.sons[2].kind = nkEnumTy) then begin
          a := s.typ.n;
          for j := 0 to sonsLen(a)-1 do 
            addInterfaceSym(w, a.sons[j].sym);        
        end *)
      end
    end;
    nkImportStmt: begin
      for i := 0 to sonsLen(n)-1 do addModDep(w, getModuleFile(n.sons[i]));
      addStmt(w, n);
    end;
    nkFromStmt: begin
      addModDep(w, getModuleFile(n.sons[0]));
      addStmt(w, n);
    end;
    nkIncludeStmt: begin
      for i := 0 to sonsLen(n)-1 do addInclDep(w, getModuleFile(n.sons[i]));
    end;
    nkPragma: addStmt(w, n);
    else begin end
  end;
end;

function myOpen(module: PSym; const filename: string): PPassContext;
var
  w: PRodWriter;
begin
  if module.id < 0 then InternalError('rodwrite: module ID not set');
  w := newRodWriter(filename, rodread.GetCRC(filename), module);
  rawAddInterfaceSym(w, module);
  result := w;
end;

function myClose(c: PPassContext; n: PNode): PNode;
var
  w: PRodWriter;
begin
  w := PRodWriter(c);
  writeRod(w);
  result := n;
end;

function rodwritePass(): TPass;
begin
  initPass(result);
  if optSymbolFiles in gGlobalOptions then begin
    result.open := myOpen;
    result.close := myClose;
    result.process := process;
  end
end;

initialization
  IntSetInit(debugWritten);
end.
