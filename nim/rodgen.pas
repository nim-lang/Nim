//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit rodgen;

// This module is responsible for loading and storing of rod
// files.
{
  Reading and writing binary files are really hard to debug. Therefore we use
  a text-based format. It consists of:

  - a header
  - a section that contains the lengths of the other sections
  - a ident section that contains all PIdents
  - an AST section that contains the module's AST

  The resulting file sizes are currently almost as small as the source files
  (about 10%-30% increase).

  Long comments have the format: @<jump_info>#comment
  Short comments: #comment
}

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, nos, options, strutils, nversion, ast, astalgo, msgs,
  platform, ropes, idents;

type
  TRodReaderFlag = (mrSkipComments, mrSkipProcBodies);
  TRodReaderFlags = set of TRodReaderFlag;

const
  FileVersion = '02'; // modify this if the MO2-format changes!

procedure generateRod(module: PNode; const filename: string);
function readRod(const filename: string; const flags: TRodReaderFlags): PNode;


implementation

// special characters:
// \  # ? !  $ @  #128..#255

type
  TIntObj = object(NObject)
    intVal: int;
  end;
  PIntObj = ^TIntObj;

  TRodGen = record
    identTab: TTable; // maps PIdent to PIntObj
    idents: PRope;
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

function fromBase62i(const s: string; index: int; out x: int): int;
var
  i: int;
  sign: int;
begin
  i := index;
  sign := -1;
  if s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  x := 0;
  while i <= length(s)+strStart-1 do begin
    case s[i] of
      '0'..'9': x := x * 62 - (ord(s[i]) - ord('0'));
      'a'..'z': x := x * 62 - (ord(s[i]) - ord('a') + 10);
      'A'..'Z': x := x * 62 - (ord(s[i]) - ord('A') + 36);
      else break;
    end;
    inc(i)
  end;
  x := x * sign;
  result := i
end;

function fromBase62b(const s: string; index: int; out x: BiggestInt): int;
var
  i: int;
  sign: biggestInt;
begin
  i := index;
  sign := -1;
  if s[i] = '-' then begin
    inc(i);
    sign := 1
  end;
  x := 0;
  while i <= length(s)+strStart-1 do begin
    case s[i] of
      '0'..'9': x := x * 62 - (ord(s[i]) - ord('0'));
      'a'..'z': x := x * 62 - (ord(s[i]) - ord('a') + 10);
      'A'..'Z': x := x * 62 - (ord(s[i]) - ord('A') + 36);
      else break;
    end;
    inc(i)
  end;
  x := x * sign;
  result := i
end;

function encode(const s: string): PRope;
var
  i: int;
  res: string;
begin
  res := '';
  for i := strStart to length(s)+strStart-1 do begin
    case s[i] of
      '\', '?', '!', '@', '$', #128..#255, #0..#31:
        res := res +{&} '\' +{&} toHex(ord(s[i]), 2)
      else
        addChar(res, s[i])
    end
  end;
  result := toRope(res);
end;

function encodeIdent(var g: TRodGen; ident: PIdent): PRope;
var
  n: PIntObj;
begin
  n := PIntObj(TableGet(g.identTab, ident));
  if n = nil then begin
    new(n);
    {@ignore}
    fillChar(n^, sizeof(n^), 0);
    {@emit}
    n.intVal := ropeLen(g.idents);
    TablePut(g.identTab, ident, n);

    app(g.idents, encode(ident.s));
    app(g.idents, '$'+'');
  end;
  result := toBase62(n.intVal)
end;

function encodeNode(var g: TRodGen; const fInfo: TLineInfo; n: PNode): PRope;
var
  i, len: int;
  com: PRope;
begin
  if n = nil then begin // nil nodes have to be stored too!
    result := toRope(#255+''); exit
  end;
  result := nil;
  if n.comment <> snil then begin
    com := encode(n.comment);
    if ropeLen(com) >= 128 then
      appRopeFormat(result, '@$1$2', [toBase62(ropeLen(com)), com])
    else
      result := com
    // do not emit comments to the string table as this would only increase
    // file size, because comments are likely to be unique!
  end;
  // Line information takes easily 50% or more of the filesize! Therefore we
  // omit line information if it is the same as the father's line information:
  if (finfo.line <> int(n.info.line)) then
    appRopeFormat(result, '?$1,$2', [toBase62(n.info.col),
                                     toBase62(n.info.line)])
  else if (finfo.col <> int(n.info.col)) then
    appRopeFormat(result, '?$1', [toBase62(n.info.col)]);
    // No need to output the file index, as this is the serialization of one
    // file.
  if n.base <> base10 then
    appRopeFormat(result, '$$$1', [toBase62(ord(n.base))]);
  case n.kind of
    nkCharLit..nkInt64Lit:
      appRopeFormat(result, '!$1', [toBase62(n.intVal)]);
    nkFloatLit..nkFloat64Lit:
      appRopeFormat(result, '!$1', [toRopeF(n.floatVal)]);
    nkStrLit..nkTripleStrLit:
      appRopeFormat(result, '!$1', [encode(n.strVal)]);
    nkSym: assert(false);
    nkIdent:
      appRopeFormat(result, '!$1', [encodeIdent(g, n.ident)]);
    else begin
      for i := 0 to sonsLen(n)-1 do
        app(result, encodeNode(g, n.info, n.sons[i]));
    end
  end;
  len := ropeLen(result);
  result := ropeFormat('$1$2$3', [toRope(chr(ord(n.kind)+128)+''), 
                                  toBase62(len), result]);
  assert(ord(n.kind)+128 < 256);
end;

procedure generateRod(module: PNode; const filename: string);
var
  g: TRodGen;
  ast: PRope;
  info: TLineInfo;
begin
  assert(ord(high(TNodeKind))+1 < 127);
  initTable(g.identTab);
  g.idents := nil;
  info := newLineInfo(changeFileExt(filename, '.nim'), -1, -1);
  ast := encodeNode(g, info, module);

  writeRope(ropeFormat('AA02 $1 $2,$3 $4 $5',
                       [toRope(FileVersion),
                        toBase62(ropeLen(g.idents)), toBase62(ropeLen(ast)),
                        g.idents, ast]), filename);
end;

// ----------------------- reader ---------------------------------------------

type
  TRodReader = record
    s: string;        // buffer of the whole Mo2 file
    pos: int;         // current position
    identOff: int;    // offset of start of first PIdent
    identLen: int;    // length of ident part
    astOff: int;      // offset of AST part
    astLen: int;      // length of AST part
    flags: TRodReaderFlags;
  end;

procedure initRodReader(out r: TRodReader; const filename: string;
                        const flags: TRodReaderFlags);
var
  i: int;
  version: string;
begin
  r.flags := flags;
  r.pos := -1; // indicates an error
  r.s := readFile(filename) {@ignore} + #0 {@emit};
  r.identOff := 0;
  r.astOff := 0;
  r.identLen := 0;
  r.astLen := 0;

  // read header:
  i := strStart;
  if (r.s[i] = 'A') and (r.s[i+1] = 'A')
  and (r.s[i+2] = '0') and (r.s[i+3] = '2') and (r.s[i+4] = ' ') then begin
    // check version:
    inc(i, 5);
    version := '';
    while (r.s[i] <> ' ') and (r.s[i] <> #0) do begin
      addChar(version, r.s[i]);
      inc(i);
    end;
    if r.s[i] = ' ' then inc(i);
    if version = FileVersion then begin
      i := fromBase62i(r.s, i, r.identLen);
      if r.s[i] = ',' then inc(i);
      i := fromBase62i(r.s, i, r.astLen);
      if r.s[i] = ' ' then inc(i);
      r.identOff := i;
      r.astOff := i+r.identLen+1;
      assert(r.s[r.astOff-1] = ' ');
      r.pos := r.astOff; // everything seems fine
    end
  end
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

function decode(const s: string; index: int; var d: string): int;
var
  i, xi: int;
begin
  i := index;
  while true do begin
    case s[i] of
      '?', '$', '@', '!', #128..#255, #0: break;
      '\': begin
        inc(i, 3); xi := 0;
        hexChar(s[i-2], xi);
        hexChar(s[i-1], xi);
        addChar(d, chr(xi));
      end;
      else begin
        addChar(d, s[i]);
        inc(i);
      end
    end
  end;
  result := i;
end;

function readNode(var r: TRodReader; const fatherInfo: TLineInfo;
                  skip: bool): PNode;
var
  i, len, x, endpos: int;
  kind: TNodeKind;
  fl: string;
begin
  result := nil;
  i := r.pos;
  if r.s[i] = #255 then begin
    inc(r.pos); exit // nil node
  end;
  assert(r.s[i] >= #128);
  kind := TNodeKind(ord(r.s[i])-int(128));
  assert((kind >= low(TNodeKind)) and (kind <= high(TNodeKind)));
  inc(i); // skip kind
  i := fromBase62i(r.s, i, len);
  endpos := i+len-1;
  if skip then
    inc(i, len)
  else begin
    result := newNode(kind);
    result.info := fatherInfo;
    // comment:
    if r.s[i] = '#' then begin
      result.comment := '';
      i := decode(r.s, i, result.comment);
      if mrSkipComments in r.flags then result.comment := snil;
    end
    else if r.s[i] = '@' then begin
      inc(i);
      i := fromBase62i(r.s, i, x);
      if mrSkipComments in r.flags then
        inc(i, x)
      else begin
        result.comment := '';
        i := decode(r.s, i, result.comment)
      end
    end;
    // info:
    if r.s[i] = '?' then begin
      inc(i);
      i := fromBase62i(r.s, i, x);
      result.info.col := x;
      if r.s[i] = ',' then begin
        inc(i);
        i := fromBase62i(r.s, i, x);
        result.info.line := x
      end
    end;
    // base:
    if r.s[i] = '$' then begin
      inc(i);
      i := fromBase62i(r.s, i, x);
      result.base := TNumericalBase(x);
    end;
    // atom:
    if r.s[i] = '!' then begin
      inc(i);
      case kind of
        nkCharLit..nkInt64Lit:
          i := fromBase62b(r.s, i, result.intVal);
        nkFloatLit..nkFloat64Lit: begin
          fl := '';
          i := decode(r.s, i, fl);
          result.floatVal := parseFloat(fl);
        end;
        nkStrLit..nkTripleStrLit:
          i := decode(r.s, i, result.strVal);
        nkSym: assert(false);
        nkIdent: begin
          i := fromBase62i(r.s, i, x);
          fl := '';
          {@discard} decode(r.s, r.identOff+x, fl);
          result.ident := getIdent(fl)
        end
        else assert(false);
      end
    end
    else if r.s[i] >= #128 then begin
      case kind of
        nkCharLit..nkInt64Lit, nkFloatLit..nkFloat64Lit, 
        nkStrLit..nkTripleStrLit, nkSym, nkIdent: assert(false);
        else begin end;
      end;
      r.pos := i;
      // H3YYY
      // 01234
      while r.pos <= endpos do
        addSon(result, readNode(r, result.info, false));
      i := r.pos;
    end
    else assert(r.s[i] = #0);
  end;
  r.pos := i;
end;

function readRod(const filename: string; const flags: TRodReaderFlags): PNode;
var
  r: TRodReader;
  info: TLineInfo;
begin
  result := nil;
  initRodReader(r, filename, flags);
  info := newLineInfo(changeFileExt(filename, '.nim'), -1, -1);
  if r.pos > 0 then
    result := readNode(r, info, false);
end;

end.
