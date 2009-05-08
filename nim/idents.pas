//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit idents;

{$include 'config.inc'}

// Identifier handling
// An identifier is a shared non-modifiable string that can be compared by its
// id. This module is essential for the compiler's performance.

interface

uses
  nhashes, nsystem, strutils;

type
  TIdObj = object(NObject)
    id: int; // unique id; use this for comparisons and not the pointers
  end;
  PIdObj = ^TIdObj;

  PIdent = ^TIdent;
  TIdent = object(TIdObj)
    s: string;
    next: PIdent;  // for hash-table chaining
    h: THash;      // hash value of s
  end {@acyclic};

function getIdent(const identifier: string): PIdent; overload;
function getIdent(const identifier: string; h: THash): PIdent; overload;
function getIdent(identifier: cstring; len: int; h: THash): PIdent; overload;
  // special version for the scanner; the scanner's buffering scheme makes
  // this horribly efficient. Most of the time no character copying is needed!

function IdentEq(id: PIdent; const name: string): bool;

implementation

function IdentEq(id: PIdent; const name: string): bool;
begin
  result := id.id = getIdent(name).id;
end;

var
  buckets: array [0..4096*2-1] of PIdent;

function cmpIgnoreStyle(a, b: cstring; blen: int): int;
var
  aa, bb: char;
  i, j: int;
begin
  i := 0;
  j := 0;
  result := 1;
  while j < blen do begin
    while a[i] = '_' do inc(i);
    while b[j] = '_' do inc(j);
    // tolower inlined:
    aa := a[i];
    bb := b[j];
    if (aa >= 'A') and (aa <= 'Z') then
      aa := chr(ord(aa) + (ord('a') - ord('A')));
    if (bb >= 'A') and (bb <= 'Z') then
      bb := chr(ord(bb) + (ord('a') - ord('A')));
    result := ord(aa) - ord(bb);
    if (result <> 0) or (aa = #0) then break;
    inc(i);
    inc(j)
  end;
  if result = 0 then 
    if a[i] <> #0 then result := 1
end;

function cmpExact(a, b: cstring; blen: int): int;
var
  aa, bb: char;
  i, j: int;
begin
  i := 0;
  j := 0;
  result := 1;
  while j < blen do begin
    aa := a[i];
    bb := b[j];
    result := ord(aa) - ord(bb);
    if (result <> 0) or (aa = #0) then break;
    inc(i);
    inc(j)
  end;
  if result = 0 then 
    if a[i] <> #0 then result := 1
end;

function getIdent(const identifier: string): PIdent;
begin
  result := getIdent(pchar(identifier), length(identifier),
                     getNormalizedHash(identifier))
end;

function getIdent(const identifier: string; h: THash): PIdent;
begin
  result := getIdent(pchar(identifier), length(identifier), h)
end;

var
  wordCounter: int = 1;

function getIdent(identifier: cstring; len: int; h: THash): PIdent;
var
  idx, i, id: int;
  last: PIdent;
begin
  idx := h and high(buckets);
  result := buckets[idx];
  last := nil;
  id := 0;
  while result <> nil do begin
    if cmpExact(pchar(result.s), identifier, len) = 0 then begin
      if last <> nil then begin
        // make access to last looked up identifier faster:
        last.next := result.next;
        result.next := buckets[idx];
        buckets[idx] := result
      end;
      exit
    end
    else if cmpIgnoreStyle(pchar(result.s), identifier, len) = 0 then begin
      (*if (id <> 0) and (id <> result.id) then begin
        result := buckets[idx];
        writeln('current id ', id);
        for i := 0 to len-1 do write(identifier[i]);
        writeln;
        while result <> nil do begin
          writeln(result.s, '  ', result.id);
          result := result.next
        end
      end;*)
      assert((id = 0) or (id = result.id));
      id := result.id
    end;
    last := result;
    result := result.next
  end;
  // new ident:
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.h := h;
  result.s := newString(len);
  for i := strStart to len+StrStart-1 do
    result.s[i] := identifier[i-StrStart];
  result.next := buckets[idx];
  buckets[idx] := result;
  if id = 0 then begin
    inc(wordCounter);
    result.id := - wordCounter;
  end
  else
    result.id := id
//  writeln('new word ', result.s);
end;

end.
