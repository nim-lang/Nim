//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit rodread;

// This module is responsible for loading of rod files.
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
  TRodReader = object(NObject)
    pos: int;    // position; used for parsing
    s: string;   // the whole file in memory
    options: TOptions;
    reason: TReasonForRecompile;
    modDeps: TStringSeq;
    files: TStringSeq;
    dataIdx: int;       // offset of start of data section
    convertersIdx: int; // offset of start of converters section
    initIdx, interfIdx, compilerProcsIdx, cgenIdx: int;
    filename: string;
    index, imports: TIndex;
    readerIndex: int;
    line: int;          // only used for debugging, but is always in the code
    moduleID: int;
    syms: TIdTable;     // already processed symbols
  end;
  PRodReader = ^TRodReader;

const
  FileVersion = '1012'; // modify this if the rod-format changes!

var
  rodCompilerprocs: TStrTable; // global because this is needed by magicsys


function handleSymbolFile(module: PSym; const filename: string): PRodReader;
function GetCRC(const filename: string): TCrc32;

function loadInitSection(r: PRodReader): PNode;

procedure loadStub(s: PSym);

function encodeInt(x: BiggestInt): PRope;
function encode(const s: string): PRope;

implementation

var
  gTypeTable: TIdTable;

function rrGetSym(r: PRodReader; id: int; const info: TLineInfo): PSym; forward;
  // `info` is only used for debugging purposes

function rrGetType(r: PRodReader; id: int; const info: TLineInfo): PType; forward;

function decode(r: PRodReader): string; forward;
function decodeInt(r: PRodReader): int; forward;
function decodeBInt(r: PRodReader): biggestInt; forward;

function encode(const s: string): PRope;
var
  i: int;
  res: string;
begin
  res := '';
  for i := strStart to length(s)+strStart-1 do begin
    case s[i] of
      'a'..'z', 'A'..'Z', '0'..'9', '_':
        addChar(res, s[i]);
      else
        res := res +{&} '\' +{&} toHex(ord(s[i]), 2)
    end
  end;
  result := toRope(res);
end;

procedure encodeIntAux(var str: string; x: BiggestInt);
const
  chars: string =
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  v, rem: biggestInt;
  d: char;
  idx: int;
begin
  v := x;
  rem := v mod 190;
  if (rem < 0) then begin
    str := str + '-';
    v := -(v div 190);
    rem := -rem;
  end
  else
    v := v div 190;
  idx := int(rem);
  if idx < 62 then d := chars[idx+strStart]
  else d := chr(idx - 62 + 128);
  if (v <> 0) then encodeIntAux(str, v);
  addChar(str, d);
end;

function encodeInt(x: BiggestInt): PRope;
var
  res: string;
begin
  res := '';
  encodeIntAux(res, x);
  result := toRope(res);
end;


procedure decodeLineInfo(r: PRodReader; var info: TLineInfo);
begin
  if r.s[r.pos] = '?' then begin
    inc(r.pos);
    if r.s[r.pos] = ',' then
      info.col := int16(-1)
    else
      info.col := int16(decodeInt(r));
    if r.s[r.pos] = ',' then begin
      inc(r.pos);
      if r.s[r.pos] = ',' then info.line := int16(-1)
      else info.line := int16(decodeInt(r));
      if r.s[r.pos] = ',' then begin
        inc(r.pos);
        info := newLineInfo(r.files[decodeInt(r)], info.line, info.col);
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
    result := newNodeI(TNodeKind(decodeInt(r)), fInfo);
    decodeLineInfo(r, result.info);
    if r.s[r.pos] = '$' then begin
      inc(r.pos);
      result.flags := {@cast}TNodeFlags(int32(decodeInt(r)));
    end;
    if r.s[r.pos] = '^' then begin
      inc(r.pos);
      id := decodeInt(r);
      result.typ := rrGetType(r, id, result.info);
    end;
    case result.kind of
      nkCharLit..nkInt64Lit: begin
        if r.s[r.pos] = '!' then begin
          inc(r.pos);
          result.intVal := decodeBInt(r);
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
          id := decodeInt(r);
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

procedure decodeLoc(r: PRodReader; var loc: TLoc; const info: TLineInfo);
begin
  if r.s[r.pos] = '<' then begin
    inc(r.pos);
    if r.s[r.pos] in ['0'..'9', 'a'..'z', 'A'..'Z'] then
      loc.k := TLocKind(decodeInt(r))
    else
      loc.k := low(loc.k);
    if r.s[r.pos] = '*' then begin
      inc(r.pos);
      loc.s := TStorageLoc(decodeInt(r));
    end
    else
      loc.s := low(loc.s);
    if r.s[r.pos] = '$' then begin
      inc(r.pos);
      loc.flags := {@cast}TLocFlags(int32(decodeInt(r)));
    end
    else
      loc.flags := {@set}[];
    if r.s[r.pos] = '^' then begin
      inc(r.pos);
      loc.t := rrGetType(r, decodeInt(r), info);
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
      loc.a := decodeInt(r);
    end
    else
      loc.a := 0;
    if r.s[r.pos] = '>' then inc(r.pos)
    else InternalError(info, 'decodeLoc ' + r.s[r.pos]);
  end
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
  result.kind := TTypeKind(decodeInt(r));
  if r.s[r.pos] = '+' then begin
    inc(r.pos);
    result.id := decodeInt(r);
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
    result.flags := {@cast}TTypeFlags(int32(decodeInt(r)));
  end;
  if r.s[r.pos] = '?' then begin
    inc(r.pos);
    result.callConv := TCallingConvention(decodeInt(r));
  end;
  if r.s[r.pos] = '*' then begin
    inc(r.pos);
    result.owner := rrGetSym(r, decodeInt(r), info);
  end;
  if r.s[r.pos] = '&' then begin
    inc(r.pos);
    result.sym := rrGetSym(r, decodeInt(r), info);
  end;
  if r.s[r.pos] = '/' then begin
    inc(r.pos);
    result.size := decodeInt(r);
  end
  else result.size := -1;
  if r.s[r.pos] = '=' then begin
    inc(r.pos);
    result.align := decodeInt(r);
  end
  else result.align := 2;
  if r.s[r.pos] = '@' then begin
    inc(r.pos);
    result.containerID := decodeInt(r);
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
      d := decodeInt(r);
      addSon(result, rrGetType(r, d, info));
    end;
  end
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
    result.kind := TLibKind(decodeInt(r));
    if r.s[r.pos] <> '|' then InternalError('decodeLib: 1');
    inc(r.pos);
    result.name := toRope(decode(r));
    if r.s[r.pos] <> '|' then InternalError('decodeLib: 2');
    inc(r.pos);
    result.path := decode(r);
  end
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
  k := TSymKind(decodeInt(r));
  if r.s[r.pos] = '+' then begin
    inc(r.pos);
    id := decodeInt(r);
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
    result.typ := rrGetType(r, decodeInt(r), info);
  end;
  decodeLineInfo(r, result.info);
  if r.s[r.pos] = '*' then begin
    inc(r.pos);
    result.owner := rrGetSym(r, decodeInt(r), result.info);
  end;
  if r.s[r.pos] = '$' then begin
    inc(r.pos);
    result.flags := {@cast}TSymFlags(int32(decodeInt(r)));
  end;
  if r.s[r.pos] = '@' then begin
    inc(r.pos);
    result.magic := TMagic(decodeInt(r));
  end;
  if r.s[r.pos] = '(' then
    result.ast := decodeNode(r, result.info);
  if r.s[r.pos] = '!' then begin
    inc(r.pos);
    result.options := {@cast}TOptions(int32(decodeInt(r)));
  end
  else
    result.options := r.options;
  if r.s[r.pos] = '%' then begin
    inc(r.pos);
    result.position := decodeInt(r);
  end
  else
    result.position := 0; // BUGFIX: this may have been misused as reader index!
  if r.s[r.pos] = '`' then begin
    inc(r.pos);
    result.offset := decodeInt(r);
  end
  else
    result.offset := -1;
  decodeLoc(r, result.loc, result.info);
  result.annex := decodeLib(r);
end;

function decodeInt(r: PRodReader): int; // base 190 numbers
var
  i: int;
  sign: int;
begin
  i := r.pos;
  sign := -1;
  assert(r.s[i] in ['a'..'z', 'A'..'Z', '0'..'9', '-', #128..#255]);
  if r.s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  result := 0;
  while true do begin
    case r.s[i] of
      '0'..'9': result := result * 190 - (ord(r.s[i]) - ord('0'));
      'a'..'z': result := result * 190 - (ord(r.s[i]) - ord('a') + 10);
      'A'..'Z': result := result * 190 - (ord(r.s[i]) - ord('A') + 36);
      #128..#255: result := result * 190 - (ord(r.s[i]) - 128 + 62);
      else break;
    end;
    inc(i)
  end;
  result := result * sign;
  r.pos := i
end;

function decodeBInt(r: PRodReader): biggestInt;
var
  i: int;
  sign: biggestInt;
begin
  i := r.pos;
  sign := -1;
  assert(r.s[i] in ['a'..'z', 'A'..'Z', '0'..'9', '-', #128..#255]);
  if r.s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  result := 0;
  while true do begin
    case r.s[i] of
      '0'..'9': result := result * 190 - (ord(r.s[i]) - ord('0'));
      'a'..'z': result := result * 190 - (ord(r.s[i]) - ord('a') + 10);
      'A'..'Z': result := result * 190 - (ord(r.s[i]) - ord('A') + 36);
      #128..#255: result := result * 190 - (ord(r.s[i]) - 128 + 62);
      else break;
    end;
    inc(i)
  end;
  result := result * sign;
  r.pos := i
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
      'a'..'z', 'A'..'Z', '0'..'9', '_': begin
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
  //MessageOut(result.name.s);
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
    key := decodeInt(r);
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
    key := decodeInt(r);
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
    tmp := decodeInt(r);
    if r.s[r.pos] = ' ' then begin
      inc(r.pos);
      key := idx.lastIdxKey + tmp;
      val := decodeInt(r) + idx.lastIdxVal;
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
      if int(crc) <> decodeInt(r) then
        r.reason := rrCrcChange
    end
    else if section = 'ID' then begin
      inc(r.pos); // skip ':'
      r.moduleID := decodeInt(r);
      setID(r.moduleID);
    end
    else if section = 'OPTIONS' then begin
      inc(r.pos); // skip ':'
      r.options := {@cast}TOptions(int32(decodeInt(r)));
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
        w := r.files[decodeInt(r)];
        inc(r.pos); // skip ' '
        inclCrc := decodeInt(r);
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
        r.modDeps[L] := r.files[decodeInt(r)];
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
    else if section = 'CGEN' then begin
      r.cgenIdx := r.pos+2;
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
{@emit result.files := @[];}
{@emit result.modDeps := @[];}
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
    crc: TCrc32;
  end;
  TFileModuleMap = array of TFileModuleRec;
var
  gMods: TFileModuleMap = {@ignore} nil {@emit @[]}; // all compiled modules

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
          'missing from both indexes: +' + ropeToStr(encodeInt(id)));
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
                'rrGetSym: no reader found: +' + ropeToStr(encodeInt(id)));
          end
          else begin
            //if IiTableGet(rd.index.tab, id) <> invalidKey then
            // XXX expensive check!
              //InternalError(info,
              //'id found in other module: +' + ropeToStr(encodeInt(id)))
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
    d := decodeInt(r);
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
    d := decodeInt(r);
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
  rodfile: string;
  idx, i: int;
  res: TReasonForRecompile;
begin
  idx := getModuleIdx(filename);
  if gMods[idx].reason <> rrEmpty then begin
    // reason has already been computed for this module:
    result := gMods[idx].reason; exit
  end;
  crc := crcFromFile(filename);
  gMods[idx].reason := rrNone; // we need to set it here to avoid cycles
  gMods[idx].filename := filename;
  gMods[idx].crc := crc;
  result := rrNone;
  r := nil;
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
    r := nil;
  end;
  gMods[idx].rd := r;
  gMods[idx].reason := result; // now we know better
end;

function handleSymbolFile(module: PSym; const filename: string): PRodReader;
var
  idx: int;
begin
  if not (optSymbolFiles in gGlobalOptions) then begin
    module.id := getID();
    result := nil;
    exit
  end;
  {@discard} checkDep(filename);
  idx := getModuleIdx(filename);
  if gMods[idx].reason = rrEmpty then InternalError('handleSymbolFile');
  result := gMods[idx].rd;
  if result <> nil then begin
    module.id := result.moduleID;
    IdTablePut(result.syms, module, module);
    processInterf(result, module);
    processCompilerProcs(result, module);
    loadConverters(result);
  end
  else
    module.id := getID();
end;

function GetCRC(const filename: string): TCrc32;
var
  idx: int;
begin
  idx := getModuleIdx(filename);
  result := gMods[idx].crc;
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
end.
