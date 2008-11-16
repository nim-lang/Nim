//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ropes;

{ Ropes for the C code generator

  Ropes are a data structure that represents a very long string
  efficiently; especially concatenation is done in O(1) instead of O(N).
  Ropes make use a lazy evaluation: They are essentially concatenation
  trees that are only flattened when converting to a native Nimrod
  string or when written to disk. The empty string is represented with a
  nil pointer.
  A little picture makes everything clear:

  "this string" & " is internally " & "represented as"

             con  -- inner nodes do not contain raw data
            /   \
           /     \
          /       \
        con       "represented as"
       /   \
      /     \
     /       \
    /         \
   /           \
"this string"  " is internally "

  Note that this is the same as:
  "this string" & (" is internally " & "represented as")

             con
            /   \
           /     \
          /       \
 "this string"    con
                 /   \
                /     \
               /       \
              /         \
             /           \
" is internally "        "represented as"

  The 'con' operator is associative! This does not matter however for
  the algorithms we use for ropes.

  Note that the left and right pointers are not needed for leafs.
  Leafs have relatively high memory overhead (~30 bytes on a 32
  bit machines) and we produce many of them. This is why we cache and
  share leafs accross different rope trees.
  To cache them they are inserted in another tree, a splay tree for best
  performance. But for the caching tree we use the leafs' left and right
  pointers.
}

interface

{$include 'config.inc'}

uses
  nsystem, msgs, strutils, platform, hashes, crc;

const
  CacheLeafs = true;
  countCacheMisses = False; // see what our little optimization gives

type
  TFormatStr = string;
  // later we may change it to CString for better
  // performance of the code generator (assignments copy the format strings
  // though it is not necessary)

  PRope = ^TRope;
  TRope = object(NObject)
    left, right: PRope;
    len: int;
    data: string; // != nil if a leaf
  end {@acyclic};
  // the empty rope is represented by nil to safe space

  TRopeSeq = array of PRope;

function con(a, b: PRope): PRope; overload;
function con(a: PRope; const b: string): PRope; overload;
function con(const a: string; b: PRope): PRope; overload;
function con(a: array of PRope): PRope; overload;

procedure app(var a: PRope; b: PRope); overload;
procedure app(var a: PRope; const b: string); overload;

procedure prepend(var a: PRope; b: PRope);

function toRope(const s: string): PRope; overload;
function toRopeF(const r: BiggestFloat): PRope;
function toRope(i: BiggestInt): PRope; overload;

function ropeLen(a: PRope): int;

procedure WriteRope(head: PRope; const filename: string);
function writeRopeIfNotEqual(r: PRope; const filename: string): boolean;

function ropeToStr(p: PRope): string;

function ropef(const frmt: TFormatStr; const args: array of PRope): PRope;

procedure appf(var c: PRope; const frmt: TFormatStr;
  const args: array of PRope);

procedure RopeSeqInsert(var rs: TRopeSeq; r: PRope; at: Natural);

function getCacheStats: string;

function RopeEqualsFile(r: PRope; const f: string): Boolean;
// returns true if the rope r is the same as the contents of file f

function RopeInvariant(r: PRope): Boolean;
// exported for debugging

implementation

function ropeLen(a: PRope): int;
begin
  if a = nil then result := 0
  else result := a.len
end;

function newRope(const data: string = snil): PRope;
begin
  new(result);
  {@ignore}
  fillChar(result^, sizeof(TRope), 0);
  {@emit}
  if data <> snil then begin
    result.len := length(data);
    result.data := data;
  end
end;

// -------------- leaf cache: ---------------------------------------
var
  cache: PRope; // the root of the cache tree
  misses, hits: int;
  N: PRope; // dummy rope needed for splay algorithm

function getCacheStats: string;
begin
  if hits+misses <> 0 then
    result := 'Misses: ' +{&} ToString(misses) +{&}
              ' total: ' +{&} toString(hits+misses) +{&}
              ' quot: '  +{&} toStringF(toFloat(misses) / toFloat(hits+misses))
  else
    result := ''
end;

function splay(const s: string; tree: PRope; out cmpres: int): PRope;
var
  le, r, y, t: PRope;
  c: int;
begin
  t := tree;
  N.left := nil; N.right := nil; // reset to nil
  le := N;
  r := N;
  repeat
    c := cmp(s, t.data);
    if c < 0 then begin
      if (t.left <> nil) and (s < t.left.data) then begin
        y := t.left; t.left := y.right; y.right := t; t := y
      end;
      if t.left = nil then break;
      r.left := t; r := t; t := t.left
    end
    else if c > 0 then begin
      if (t.right <> nil) and (s > t.right.data) then begin
        y := t.right; t.right := y.left; y.left := t; t := y
      end;
      if t.right = nil then break;
      le.right := t; le := t; t := t.right
    end
    else break
  until false;
  cmpres := c;
  le.right := t.left; r.left := t.right; t.left := N.right; t.right := N.left;
  result := t
end;

function insertInCache(const s: string; tree: PRope): PRope;
// Insert i into the tree t, unless it's already there.
// Return a pointer to the resulting tree.
var
  t: PRope;
  cmp: int;
begin
  t := tree;
  if t = nil then begin
    result := newRope(s);
    if countCacheMisses then inc(misses);
    exit
  end;
  t := splay(s, t, cmp);
  if cmp = 0 then begin
    // We get here if it's already in the Tree
    // Don't add it again
    result := t;
    if countCacheMisses then inc(hits);
  end
  else begin
    if countCacheMisses then inc(misses);
    result := newRope(s);
    if cmp < 0 then begin
      result.left := t.left; result.right := t; t.left := nil
    end
    else begin // i > t.item:
      result.right := t.right; result.left := t; t.right := nil
    end
  end
end;

function RopeInvariant(r: PRope): Boolean;
begin
  if r = nil then
    result := true
  else begin
    result := true
  (*
    if r.data <> snil then
      result := true
    else begin
      result := (r.left <> nil) and (r.right <> nil);
      if result then result := ropeInvariant(r.left);
      if result then result := ropeInvariant(r.right);
    end *)
  end
end;

function toRope(const s: string): PRope;
begin
  if s = '' then
    result := nil
  else if cacheLeafs then begin
    result := insertInCache(s, cache);
    cache := result;
  end
  else
    result := newRope(s);
  assert(RopeInvariant(result));
end;

// ------------------------------------------------------------------

procedure RopeSeqInsert(var rs: TRopeSeq; r: PRope; at: Natural);
var
  len, i: int;
begin
  len := length(rs);
  if at > len then
    SetLength(rs, at+1)
  else
    SetLength(rs, len+1);

  // move old rope elements:
  for i := len downto at+1 do
    rs[i] := rs[i-1]; // this is correct, I used pen and paper to validate it
  rs[at] := r
end;

function con(a, b: PRope): PRope; overload;
begin
  assert(RopeInvariant(a));
  assert(RopeInvariant(b));
  if a = nil then // len is valid for every cord not only for leafs
    result := b
  else if b = nil then
    result := a
  else begin
    result := newRope();
    result.len := a.len + b.len;
    result.left := a;
    result.right := b
  end;
  assert(RopeInvariant(result));
end;

function con(a: PRope; const b: string): PRope; overload;
var
  r: PRope;
begin
  assert(RopeInvariant(a));
  if b = '' then
    result := a
  else begin
    r := toRope(b);
    if a = nil then begin
      result := r
    end
    else begin
      result := newRope();
      result.len := a.len + r.len;
      result.left := a;
      result.right := r;
    end
  end;
  assert(RopeInvariant(result));
end;

function con(const a: string; b: PRope): PRope; overload;
var
  r: PRope;
begin
  assert(RopeInvariant(b));
  if a = '' then
    result := b
  else begin
    r := toRope(a);

    if b = nil then
      result := r
    else begin
      result := newRope();
      result.len := b.len + r.len;
      result.left := r;
      result.right := b;
    end
  end;
  assert(RopeInvariant(result));
end;

function con(a: array of PRope): PRope; overload;
var
  i: int;
begin
  result := nil;
  for i := 0 to high(a) do result := con(result, a[i]);
  assert(RopeInvariant(result));
end;

function toRope(i: BiggestInt): PRope;
begin
  result := toRope(ToString(i))
end;

function toRopeF(const r: BiggestFloat): PRope;
begin
  result := toRope(toStringF(r))
end;

procedure app(var a: PRope; b: PRope); overload;
begin
  a := con(a, b);
  assert(RopeInvariant(a));
end;

procedure app(var a: PRope; const b: string); overload;
begin
  a := con(a, b);
  assert(RopeInvariant(a));
end;

procedure prepend(var a: PRope; b: PRope);
begin
  a := con(b, a);
  assert(RopeInvariant(a));
end;

procedure InitStack(var stack: TRopeSeq);
begin
  {@ignore}
  setLength(stack, 0);
  {@emit stack := @[];}
end;

procedure push(var stack: TRopeSeq; r: PRope);
var
  len: int;
begin
  len := length(stack);
  setLength(stack, len+1);
  stack[len] := r;
end;

function pop(var stack: TRopeSeq): PRope;
var
  len: int;
begin
  len := length(stack);
  result := stack[len-1];
  setLength(stack, len-1);
end;

procedure WriteRopeRec(var f: TTextFile; c: PRope);
begin
  assert(RopeInvariant(c));

  if c = nil then exit;
  if (c.data <> snil) then begin
    nimWrite(f, c.data)
  end
  else begin
    writeRopeRec(f, c.left);
    writeRopeRec(f, c.right)
  end
end;

procedure newWriteRopeRec(var f: TTextFile; c: PRope);
var
  stack: TRopeSeq;
  it: PRope;
begin
  assert(RopeInvariant(c));
  initStack(stack);
  push(stack, c);
  while length(stack) > 0 do begin
    it := pop(stack);
    while it.data = snil do begin
      push(stack, it.right);
      it := it.left;
      assert(it <> nil);
    end;
    assert(it.data <> snil);
    nimWrite(f, it.data);
  end
end;

procedure WriteRope(head: PRope; const filename: string);
var
  f: TTextFile; // we use a textfile for automatic buffer handling
begin
  if OpenFile(f, filename, fmWrite) then begin
    if head <> nil then newWriteRopeRec(f, head);
    nimCloseFile(f);
  end
  else
    rawMessage(errCannotOpenFile, filename);
end;

procedure recRopeToStr(var result: string; var resultLen: int; p: PRope);
begin
  if p = nil then exit; // do not add to result
  if (p.data = snil) then begin
    recRopeToStr(result, resultLen, p.left);
    recRopeToStr(result, resultLen, p.right);
  end
  else begin
    CopyMem(@result[resultLen+StrStart], @p.data[strStart], p.len);
    Inc(resultLen, p.len);
    assert(resultLen <= length(result));
  end
end;

procedure newRecRopeToStr(var result: string; var resultLen: int;
                          r: PRope);
var
  stack: TRopeSeq;
  it: PRope;
begin
  initStack(stack);
  push(stack, r);
  while length(stack) > 0 do begin
    it := pop(stack);
    while it.data = snil do begin
      push(stack, it.right);
      it := it.left;
    end;
    assert(it.data <> snil);
    CopyMem(@result[resultLen+StrStart], @it.data[strStart], it.len);
    Inc(resultLen, it.len);
    assert(resultLen <= length(result));
  end
end;

function ropeToStr(p: PRope): string;
var
  resultLen: int;
begin
  assert(RopeInvariant(p));
  if p = nil then
    result := ''
  else begin
    result := newString(p.len);
    resultLen := 0;
    newRecRopeToStr(result, resultLen, p);
  end
end;

function ropef(const frmt: TFormatStr; const args: array of PRope): PRope;
var
  i, j, len, start: int;
begin
  i := strStart;
  len := length(frmt);
  result := nil;
  while i <= len + StrStart - 1 do begin
    if frmt[i] = '$' then begin
      inc(i); // skip '$'
      case frmt[i] of
        '$': begin app(result, '$'+''); inc(i); end;
        '0'..'9': begin
          j := 0;
          repeat
            j := (j*10) + Ord(frmt[i]) - ord('0');
            inc(i);
          until (i > len + StrStart - 1) or not (frmt[i] in ['0'..'9']);
          if j > high(args)+1 then
            internalError('ropes: invalid format string $' + toString(j));
          app(result, args[j-1]);
        end;
        'N', 'n': begin app(result, tnl); inc(i); end;
        else InternalError('ropes: invalid format string $' + frmt[i]);
      end
    end;
    start := i;
    while (i <= len + StrStart - 1) do
      if (frmt[i] <> '$') then inc(i) else break;
    if i-1 >= start then begin
      app(result, ncopy(frmt, start, i-1));
    end
  end;
  assert(RopeInvariant(result));
end;

procedure appf(var c: PRope; const frmt: TFormatStr;
  const args: array of PRope);
begin
  app(c, ropef(frmt, args))
end;

const
  bufSize = 1024; // 1 KB is reasonable

function auxRopeEqualsFile(r: PRope; var bin: TBinaryFile;
                           buf: Pointer): Boolean;
var
  readBytes: int;
begin
  if (r.data <> snil) then begin
    if r.len > bufSize then
      // A token bigger than 1 KB? - This cannot happen in reality.
      // Well, at least I hope so. 1 KB did happen!
      internalError('ropes: token too long');
    readBytes := readBuffer(bin, buf, r.len);
    result := (readBytes = r.len) // BUGFIX
      and equalMem(buf, addr(r.data[strStart]), r.len);
  end
  else begin
    result := auxRopeEqualsFile(r.left, bin, buf);
    if result then
      result := auxRopeEqualsFile(r.right, bin, buf);
  end
end;

function RopeEqualsFile(r: PRope; const f: string): Boolean;
var
  bin: TBinaryFile;
  buf: Pointer;
begin
  result := openFile(bin, f);
  if not result then exit; // not equal if file does not exist
  buf := alloc(BufSize);
  result := auxRopeEqualsFile(r, bin, buf);
  if result then
    result := readBuffer(bin, buf, bufSize) = 0; // really at the end of file?
  dealloc(buf);
  CloseFile(bin);
end;

function crcFromRopeAux(r: PRope; startVal: TCrc32): TCrc32;
var
  i: int;
begin
  if r.data <> snil then begin
    result := startVal;
    for i := strStart to length(r.data)+strStart-1 do
      result := updateCrc32(r.data[i], result);
  end
  else begin
    result := crcFromRopeAux(r.left, startVal);
    result := crcFromRopeAux(r.right, result);
  end
end;

function newCrcFromRopeAux(r: PRope; startVal: TCrc32): TCrc32;
var
  stack: TRopeSeq;
  it: PRope;
  L, i: int;
begin
  initStack(stack);
  push(stack, r);
  result := startVal;
  while length(stack) > 0 do begin
    it := pop(stack);
    while it.data = snil do begin
      push(stack, it.right);
      it := it.left;
    end;
    assert(it.data <> snil);
    i := strStart;
    L := length(it.data)+strStart;
    while i < L do begin
      result := updateCrc32(it.data[i], result);
      inc(i);
    end
  end
end;

function crcFromRope(r: PRope): TCrc32;
begin
  result := newCrcFromRopeAux(r, initCrc32)
end;

function writeRopeIfNotEqual(r: PRope; const filename: string): boolean;
// returns true if overwritten
var
  c: TCrc32;
begin
  c := crcFromFile(filename);
  if c <> crcFromRope(r) then begin
    writeRope(r, filename);
    result := true
  end
  else
    result := false
end;

initialization
  new(N); // init dummy node for splay algorithm
{@ignore}
  fillChar(N^, sizeof(N^), 0);
{@emit}
end.
