//
//
//            Nimrod's Runtime Library
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit strtabs;

// String tables.

interface

{$include 'config.inc'}

uses
  nsystem, nos, hashes, strutils;

type
  TStringTableMode = (
    modeCaseSensitive,   // the table is case sensitive
    modeCaseInsensitive, // the table is case insensitive
    modeStyleInsensitive // the table is style insensitive
  );
  TKeyValuePair = record{@tuple}
    key, val: string;
  end;
  TKeyValuePairSeq = array of TKeyValuePair;
  TStringTable = object(NObject)
    counter: int;
    data: TKeyValuePairSeq;
    mode: TStringTableMode;
  end;
  PStringTable = ^TStringTable;

function newStringTable(const keyValuePairs: array of string;
            mode: TStringTableMode = modeCaseSensitive): PStringTable;

procedure put(t: PStringTable; const key, val: string);
function get(t: PStringTable; const key: string): string;
function hasKey(t: PStringTable; const key: string): bool;
function len(t: PStringTable): int;

type
  TFormatFlag = (
    useEnvironment, // use environment variable if the ``$key``
                    // is not found in the table
    useEmpty,       // use the empty string as a default, thus it
                    // won't throw an exception if ``$key`` is not
                    // in the table
    useKey          // do not replace ``$key`` if it is not found
                    // in the table (or in the environment)
  );
  TFormatFlags = set of TFormatFlag;

function format(const f: string; t: PStringTable;
                flags: TFormatFlags = {@set}[]): string;

implementation

const
  growthFactor = 2;
  startSize = 64;

{@ignore}
function isNil(const s: string): bool;
begin
  result := s = ''
end;
{@emit}

function newStringTable(const keyValuePairs: array of string;
            mode: TStringTableMode = modeCaseSensitive): PStringTable;
var
  i: int;
begin
  new(result);
  result.mode := mode;
  result.counter := 0;
{@ignore}
  setLength(result.data, startSize);
  fillChar(result.data[0], length(result.data)*sizeof(result.data[0]), 0);
{@emit
  newSeq(result.data, startSize); }
  i := 0;
  while i < high(keyValuePairs) do begin
    put(result, keyValuePairs[i], keyValuePairs[i+1]);
    inc(i, 2);
  end
end;

function myhash(t: PStringTable; const key: string): THash;
begin
  case t.mode of
    modeCaseSensitive: result := hashes.GetHashStr(key);
    modeCaseInsensitive: result := hashes.GetHashStrCI(key);
    modeStyleInsensitive: result := hashes.getNormalizedHash(key);
  end
end;

function myCmp(t: PStringTable; const a, b: string): bool;
begin
  case t.mode of
    modeCaseSensitive: result := cmp(a, b) = 0;
    modeCaseInsensitive: result := cmpIgnoreCase(a, b) = 0;
    modeStyleInsensitive: result := cmpIgnoreStyle(a, b) = 0;
  end
end;

function mustRehash(len, counter: int): bool;
begin
  assert(len > counter);
  result := (len * 2 < counter * 3) or (len-counter < 4);
end;

function len(t: PStringTable): int;
begin
  result := t.counter
end;

{@ignore}
const
  EmptySeq = nil;
{@emit
const
  EmptySeq = [];
}

function nextTry(h, maxHash: THash): THash;
begin
  result := ((5*h) + 1) and maxHash;
  // For any initial h in range(maxHash), repeating that maxHash times
  // generates each int in range(maxHash) exactly once (see any text on
  // random-number generation for proof).
end;

function RawGet(t: PStringTable; const key: string): int;
var
  h: THash;
begin
  h := myhash(t, key) and high(t.data); // start with real hash value
  while not isNil(t.data[h].key) do begin
    if mycmp(t, t.data[h].key, key) then begin
      result := h; exit
    end;
    h := nextTry(h, high(t.data))
  end;
  result := -1
end;

function get(t: PStringTable; const key: string): string;
var
  index: int;
begin
  index := RawGet(t, key);
  if index >= 0 then result := t.data[index].val
  else result := ''
end;

function hasKey(t: PStringTable; const key: string): bool;
begin
  result := rawGet(t, key) >= 0
end;

procedure RawInsert(t: PStringTable;
                    var data: TKeyValuePairSeq;
                    const key, val: string);
var
  h: THash;
begin
  h := myhash(t, key) and high(data);
  while not isNil(data[h].key) do begin
    h := nextTry(h, high(data))
  end;
  data[h].key := key;
  data[h].val := val;
end;

procedure Enlarge(t: PStringTable);
var
  n: TKeyValuePairSeq;
  i: int;
begin
{@ignore}
  n := emptySeq;
  setLength(n, length(t.data) * growthFactor);
  fillChar(n[0], length(n)*sizeof(n[0]), 0);
{@emit
  newSeq(n, length(t.data) * growthFactor); }
  for i := 0 to high(t.data) do
    if not isNil(t.data[i].key) then
      RawInsert(t, n, t.data[i].key, t.data[i].val);
{@ignore}
  t.data := n;
{@emit
  swap(t.data, n);
}
end;

procedure Put(t: PStringTable; const key, val: string);
var
  index: int;
begin
  index := RawGet(t, key);
  if index >= 0 then
    t.data[index].val := val
  else begin
    if mustRehash(length(t.data), t.counter) then Enlarge(t);
    RawInsert(t, t.data, key, val);
    inc(t.counter)
  end;
end;

{@ignore}
type
  EInvalidValue = int; // dummy for the Pascal compiler
{@emit}

procedure RaiseFormatException(const s: string);
var
  e: ^EInvalidValue;
begin
{@ignore}
  raise EInvalidFormatStr.create(s);
{@emit
  new(e);}
{@emit
  e.msg := 'format string: key not found: ' + s;}
{@emit
  raise e;}
end;

function getValue(t: PStringTable; flags: TFormatFlags;
                  const key: string): string;
begin
  if hasKey(t, key) then begin
    result := get(t, key); exit
  end;
  if useEnvironment in flags then
    result := nos.getEnv(key)
  else
    result := '';
  if (result = '') then begin
    if useKey in flags then result := '$' + key
    else if not (useEmpty in flags) then
      raiseFormatException(key)
  end
end;

function format(const f: string; t: PStringTable;
                flags: TFormatFlags = {@set}[]): string;
const
  PatternChars = ['a'..'z', 'A'..'Z', '0'..'9', '_', #128..#255];
var
  i, j: int;
  key: string;
begin
  result := '';
  i := strStart;
  while i <= length(f)+strStart-1 do
    if f[i] = '$' then begin
      case f[i+1] of
        '$': begin
          addChar(result, '$');
          inc(i, 2);
        end;
        '{': begin
          j := i+1;
          while (j <= length(f)+strStart-1) and (f[j] <> '}') do inc(j);
          key := ncopy(f, i+2+strStart-1, j-1+strStart-1);
          result := result +{&} getValue(t, flags, key);
          i := j+1
        end;
        'a'..'z', 'A'..'Z', #128..#255, '_': begin
          j := i+1;
          while (j <= length(f)+strStart-1) and (f[j] in PatternChars) do inc(j);
          key := ncopy(f, i+1+strStart-1, j-1+strStart-1);
          result := result +{&} getValue(t, flags, key);
          i := j
        end
        else begin
          addChar(result, f[i]);
          inc(i)
        end
      end
    end
    else begin
      addChar(result, f[i]);
      inc(i)
    end
end;

end.
