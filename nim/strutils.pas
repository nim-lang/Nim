//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit strutils;

interface

{$include 'config.inc'}

uses
  sysutils, nsystem;

type
  EInvalidFormatStr = class(Exception)
  end;

const
  StrStart = 1;

function normalize(const s: string): string;
function cmpIgnoreStyle(const x, y: string): int;
function cmp(const x, y: string): int;
function cmpIgnoreCase(const x, y: string): int;

function format(const f: string; const args: array of string): string;
procedure addf(var result: string; const f: string; args: array of string);

function toHex(x: BiggestInt; len: int): string;
function toOctal(value: Char): string;
function toOct(x: BiggestInt; len: int): string;
function toBin(x: BiggestInt; len: int): string;


procedure addChar(var s: string; c: Char);
function toInt(const s: string): int;
function toBiggestInt(const s: string): BiggestInt;

function toString(i: BiggestInt): string; overload;

//function toString(i: int): string; overload;
function ToStringF(const r: Real): string; overload;
function ToString(b: Boolean): string; overload;
function ToString(b: PChar): string; overload;

function IntToStr(i: BiggestInt; minChars: int): string;

function find(const s, sub: string; start: int = 1): int; overload;
function replace(const s, search, by: string): string;
procedure deleteStr(var s: string; first, last: int);

function ToLower(const s: string): string;
function toUpper(c: Char): Char; overload;
function toUpper(s: string): string; overload;

function parseInt(const s: string): int;
function parseBiggestInt(const s: string): BiggestInt;
function ParseFloat(const s: string; checkEnd: Boolean = True): Real;

function repeatChar(count: int; c: Char = ' '): string;

function split(const s: string; const seps: TCharSet): TStringSeq;

function startsWith(const s, prefix: string): bool;
function endsWith(const s, postfix: string): bool;

const
  WhiteSpace = [' ', #9..#13];

function strip(const s: string; const chars: TCharSet = WhiteSpace): string;
function allCharsInSet(const s: string; const theSet: TCharSet): bool;

function quoteIfContainsWhite(const s: string): string;
procedure addSep(var dest: string; sep: string = ', '); 

implementation

procedure addSep(var dest: string; sep: string = ', '); 
begin
  if length(dest) > 0 then add(dest, sep)
end;

function quoteIfContainsWhite(const s: string): string;
begin
  if ((find(s, ' ') >= strStart)
  or (find(s, #9) >= strStart)) and (s[strStart] <> '"') then
    result := '"' +{&} s +{&} '"'
  else
    result := s
end;

function allCharsInSet(const s: string; const theSet: TCharSet): bool;
var
  i: int;
begin
  for i := strStart to length(s)+strStart-1 do
    if not (s[i] in theSet) then begin result := false; exit end;
  result := true
end;

function strip(const s: string; const chars: TCharSet = WhiteSpace): string;
var
  a, b, last: int;
begin
  a := strStart;
  last := length(s) + strStart - 1;
  while (a <= last) and (s[a] in chars) do inc(a);
  b := last;
  while (b >= strStart) and (s[b] in chars) do dec(b);
  if a <= b then
    result := ncopy(s, a, b)
  else
    result := '';
end;

function startsWith(const s, prefix: string): bool;
var
  i, j: int;
begin
  result := false;
  if length(s) >= length(prefix) then begin
    i := 1;
    j := 1;
    while (i <= length(s)) and (j <= length(prefix)) do begin
      if s[i] <> prefix[j] then exit;
      inc(i);
      inc(j);
    end;
    result := j > length(prefix);
  end
end;

function endsWith(const s, postfix: string): bool;
var
  i, j: int;
begin
  result := false;
  if length(s) >= length(postfix) then begin
    i := length(s);
    j := length(postfix);
    while (i >= 1) and (j >= 1) do begin
      if s[i] <> postfix[j] then exit;
      dec(i);
      dec(j);
    end;
    result := j = 0;
  end
end;

function split(const s: string; const seps: TCharSet): TStringSeq;
var
  first, last, len: int;
begin
  first := 1;
  last := 1;
  setLength(result, 0);
  while last <= length(s) do begin
    while (last <= length(s)) and (s[last] in seps) do inc(last);
    first := last;
    while (last <= length(s)) and not (s[last] in seps) do inc(last);
    if first >= last-1 then begin
      len := length(result);
      setLength(result, len+1);
      result[len] := ncopy(s, first, last-1);
    end
  end
end;

function repeatChar(count: int; c: Char = ' '): string;
var
  i: int;
begin
  result := newString(count);
  for i := strStart to count+strStart-1 do result[i] := c
end;

function cmp(const x, y: string): int;
var
  aa, bb: char;
  a, b: PChar;
  i, j: int;
begin
  i := 0;
  j := 0;
  a := PChar(x); // this is correct even for x = ''
  b := PChar(y);
  repeat
    aa := a[i];
    bb := b[j];
    result := ord(aa) - ord(bb);
    if (result <> 0) or (aa = #0) then break;
    inc(i);
    inc(j);
  until false
end;

procedure deleteStr(var s: string; first, last: int);
begin
  delete(s, first, last - first + 1);
end;

function toUpper(c: Char): Char;
begin
  if (c >= 'a') and (c <= 'z') then
    result := Chr(Ord(c) - Ord('a') + Ord('A'))
  else
    result := c
end;

function ToString(b: Boolean): string;
begin
  if b then result := 'true'
  else result := 'false'
end;

function toOctal(value: Char): string;
var
  i: int;
  val: int;
begin
  val := ord(value);
  result := newString(3);
  for i := strStart+2 downto strStart do begin
    result[i] := Chr(val mod 8 + ord('0'));
    val := val div 8
  end;
end;

function ToLower(const s: string): string;
var
  i: int;
begin
  result := '';
  for i := strStart to length(s)+StrStart-1 do
    if s[i] in ['A'..'Z'] then
      result := result + Chr(Ord(s[i]) + Ord('a') - Ord('A'))
    else
      result := result + s[i]
end;

function toUpper(s: string): string;
var
  i: int;
begin
  result := '';
  for i := strStart to length(s)+StrStart-1 do
    if s[i] in ['a'..'z'] then
      result := result + Chr(Ord(s[i]) - Ord('a') + Ord('A'))
    else
      result := result + s[i]
end;

function find(const s, sub: string; start: int = 1): int;
var
  i, j, M, N: int;
begin
  M := length(sub); N := length(s);
  i := start; j := 1;
  if i > N then
    result := 0
  else begin
    repeat
      if s[i] = sub[j] then begin
        Inc(i); Inc(j);
      end
      else begin
        i := i - j + 2;
        j := 1
      end
    until (j > M) or (i > N);
    if j > M then result := i - M
    else result := 0
  end
end;

function replace(const s, search, by: string): string;
var
  i, j: int;
begin
  result := '';
  i := 1;
  repeat
    j := find(s, search, i);
    if j = 0 then begin
      // copy the rest:
      result := result + copy(s, i, length(s) - i + 1);
      break
    end;
    result := result + copy(s, i, j - i) + by;
    i := j + length(search)
  until false
end;

function ToStringF(const r: Real): string;
var
  i: int;
begin
  result := sysutils.format('%g', [r]);
  i := pos(',', result);
  if i > 0 then result[i] := '.' // long standing bug!
  else if (cmpIgnoreStyle(result, 'nan') = 0) then // BUGFIX
    result := 'NAN'
  else if (cmpIgnoreStyle(result, 'inf') = 0) or
          (cmpIgnoreStyle(result, '+inf') = 0) then
      // FPC 2.1.1 seems to write +Inf ..., so here we go
    result := 'INF'
  else if (cmpIgnoreStyle(result, '-inf') = 0) then
    result := '-INF' // another BUGFIX
  else if pos('.', result) = 0 then
    result := result + '.0'
end;

function toInt(const s: string): int;
var
  code: int;
begin
  Val(s, result, code)
end;

function toHex(x: BiggestInt; len: int): string;
const
  HexChars: array [0..$F] of Char = '0123456789ABCDEF';
var
  j: int;
  mask, shift: BiggestInt;
begin
  assert(len > 0);
  SetLength(result, len);
  mask := $F;
  shift := 0;
  for j := len + strStart-1 downto strStart do begin
    result[j] := HexChars[(x and mask) shr shift];
    shift := shift + 4;
    mask := mask shl 4;
  end;
end;

function toOct(x: BiggestInt; len: int): string;
var
  j: int;
  mask, shift: BiggestInt;
begin
  assert(len > 0);
  result := newString(len);
  mask := 7;
  shift := 0;
  for j := len + strStart-1 downto strStart do begin
    result[j] := chr(((x and mask) shr shift) + ord('0'));
    shift := shift + 3;
    mask := mask shl 3;
  end;
end;

function toBin(x: BiggestInt; len: int): string;
var
  j: int;
  mask, shift: BiggestInt;
begin
  assert(len > 0);
  result := newString(len);
  mask := 1;
  shift := 0;
  for j := len + strStart-1 downto strStart do begin
    result[j] := chr(((x and mask) shr shift) + ord('0'));
    shift := shift + 1;
    mask := mask shl 1;
  end;
end;

procedure addChar(var s: string; c: Char);
{@ignore}
// delphi produces suboptimal code for "s := s + c"
{$ifndef fpc}
var
  len: int;
{$endif}
{@emit}
begin
{@ignore}
{$ifdef fpc}
  s := s + c
{$else}
  {$ifopt H+}
  len := length(s);
  setLength(s, len + 1);
  PChar(Pointer(s))[len] := c
  {$else}
  s := s + c
  {$endif}
{$endif}
{@emit
  s &= c
}
end;

function IntToStr(i: BiggestInt; minChars: int): string;
var
  j: int;
begin
  result := sysutils.IntToStr(i);
  for j := 1 to minChars - length(result) do
    result := '0' + result;
end;

function toBiggestInt(const s: string): BiggestInt;
begin
{$ifdef dephi}
  result := '';
  str(i : 1, result);
{$else}
  result := StrToInt64(s);
{$endif}
end;

function toString(i: BiggestInt): string; overload;
begin
  result := sysUtils.intToStr(i);
end;

function ToString(b: PChar): string; overload;
begin
  result := string(b);
end;

function normalize(const s: string): string;
var
  i: int;
begin
  result := '';
  for i := strStart to length(s)+StrStart-1 do
    if s[i] in ['A'..'Z'] then
      result := result + Chr(Ord(s[i]) + Ord('a') - Ord('A'))
    else if s[i] <> '_' then
      result := result + s[i]
end;

function cmpIgnoreCase(const x, y: string): int;
var
  aa, bb: char;
  a, b: PChar;
  i, j: int;
begin
  i := 0;
  j := 0;
  a := PChar(x); // this is correct even for x = ''
  b := PChar(y);
  repeat
    aa := a[i];
    bb := b[j];
    if aa in ['A'..'Z'] then aa := Chr(Ord(aa) + Ord('a') - Ord('A'));
    if bb in ['A'..'Z'] then bb := Chr(Ord(bb) + Ord('a') - Ord('A'));
    result := ord(aa) - ord(bb);
    if (result <> 0) or (a[i] = #0) then break;
    inc(i);
    inc(j);
  until false
end;

function cmpIgnoreStyle(const x, y: string): int;
// this is a hotspot in the compiler!
// it took 14% of total runtime!
// So we optimize the heck out of it!
var
  aa, bb: char;
  a, b: PChar;
  i, j: int;
begin
  i := 0;
  j := 0;
  a := PChar(x); // this is correct even for x = ''
  b := PChar(y);
  repeat
    while a[i] = '_' do inc(i);
    while b[j] = '_' do inc(j);
    aa := a[i];
    bb := b[j];
    if aa in ['A'..'Z'] then aa := Chr(Ord(aa) + Ord('a') - Ord('A'));
    if bb in ['A'..'Z'] then bb := Chr(Ord(bb) + Ord('a') - Ord('A'));
    result := ord(aa) - ord(bb);
    if (result <> 0) or (a[i] = #0) then break;
    inc(i);
    inc(j);
  until false
end;

function find(const x: string; const inArray: array of string): int; overload;
var
  i: int;
  y: string;
begin
  y := normalize(x);
  i := 0;
  while i < high(inArray) do begin
    if y = normalize(inArray[i]) then begin
      result := i; exit
    end;
    inc(i, 2); // increment by 2, else a security whole!
  end;
  result := -1
end;

procedure addf(var result: string; const f: string; args: array of string);
const
  PatternChars = ['a'..'z', 'A'..'Z', '0'..'9', '_', #128..#255];
var
  i, j, x, num: int;
begin
  i := 1;
  num := 0;
  while i <= length(f) do
    if f[i] = '$' then begin
      case f[i+1] of
        '#': begin
          inc(i, 2);
          add(result, args[num]);
          inc(num);
        end;
        '$': begin
          addChar(result, '$');
          inc(i, 2);
        end;
        '1'..'9': begin
          num := ord(f[i+1]) - ord('0');
          add(result, args[num - 1]);
          inc(i, 2);
        end;
        '{': begin
          j := i+1;
          while (j <= length(f)) and (f[j] <> '}') do inc(j);
          x := find(ncopy(f, i+2, j-1), args);
          if (x >= 0) and (x < high(args)) then add(result, args[x+1])
          else raise EInvalidFormatStr.create('');
          i := j+1
        end;
        'a'..'z', 'A'..'Z', #128..#255, '_': begin
          j := i+1;
          while (j <= length(f)) and (f[j] in PatternChars) do inc(j);
          x := find(ncopy(f, i+1, j-1), args);
          if (x >= 0) and (x < high(args)) then add(result, args[x+1])
          else raise EInvalidFormatStr.create(ncopy(f, i+1, j-1));
          i := j
        end
        else raise EInvalidFormatStr.create('');
      end
    end
    else begin
      addChar(result, f[i]);
      inc(i)
    end
end;

function format(const f: string; const args: array of string): string;
begin
  result := '';
  addf(result, f, args)
end;

{@ignore}
{$ifopt Q-} {$Q+}
{$else}     {$define Q_off}
{$endif}
{@emit}
// this must be compiled with overflow checking turned on:
function rawParseInt(const a: string; var index: int): BiggestInt;
// index contains the start position at proc entry; end position will be
// in index before the proc returns; index = -1 on error (no number at all)
var
  i: int;
  sign: BiggestInt;
  s: string;
begin
  s := a + #0; // to avoid the sucking range check errors
  i := index; // a local i is more efficient than accessing an in out parameter
  sign := 1;
  if s[i] = '+' then inc(i)
  else if s[i] = '-' then begin
    inc(i);
    sign := -1
  end;

  if s[i] in ['0'..'9'] then begin
    result := 0;
    while s[i] in ['0'..'9'] do begin
      result := result * 10 + ord(s[i]) - ord('0');
      inc(i);
      while s[i] = '_' do inc(i) // underscores are allowed and ignored
    end;
    result := result * sign;
    index := i; // store index back
  end
  else begin
    index := -1;
    result := 0
  end
end;
{@ignore}
{$ifdef Q_off}
{$Q-} // turn it off again!!!
{$endif}
{@emit}

function parseInt(const s: string): int;
var
  index: int;
  res: BiggestInt;
begin
  index := strStart;
  res := rawParseInt(s, index);
  if index = -1 then
    raise EInvalidValue.create('')
{$ifdef cpu32}
  //else if (res < low(int)) or (res > high(int)) then
  //  raise EOverflow.create('')
{$endif}
  else
    result := int(res) // convert to smaller int type
end;

function parseBiggestInt(const s: string): BiggestInt;
var
  index: int;
  res: BiggestInt;
begin
  index := strStart;
  result := rawParseInt(s, index);
  if index = -1 then raise EInvalidValue.create('')
end;

{@ignore}
{$ifopt Q+} {$Q-}
{$else}     {$define Q_on}
{$endif}
{@emit}
// this function must be computed without overflow checking
function parseNimInt(const a: string): biggestInt;
var
  i: int;
begin
  i := StrStart;
  result := rawParseInt(a, i);
  if i = -1 then raise EInvalidValue.create('');
end;

function ParseFloat(const s: string; checkEnd: Boolean = True): Real;
var
  hd, esign, sign: Real;
  exponent, i, code: int;
  flags: cardinal;
begin
  result := 0.0;
  code := 1;
  exponent := 0;
  esign := 1;
  flags := 0;
  sign := 1;
  case s[code] of
    '+': inc(code);
    '-': begin
      sign := -1;
      inc(code);
    end;
  end;
  
  if (s[code] = 'N') or (s[code] = 'n') then begin
    inc(code);
    if (s[code] = 'A') or (s[code] = 'a') then begin
      inc(code);
      if (s[code] = 'N') or (s[code] = 'n') then begin
        if code = length(s) then begin result:= NaN; exit end;
      end
    end;
    raise EInvalidValue.create('invalid float: ' + s)
  end;
  if (s[code] = 'I') or (s[code] = 'i') then begin
    inc(code);
    if (s[code] = 'N') or (s[code] = 'n') then begin
      inc(code);
      if (s[code] = 'F') or (s[code] = 'f') then begin
        if code = length(s) then begin result:= Inf*sign; exit end;
      end
    end;
    raise EInvalidValue.create('invalid float: ' + s)
  end;
  
  while (code <= Length(s)) and (s[code] in ['0'..'9']) do begin
   { Read int part }
    flags := flags or 1;
    result := result * 10.0 + toFloat(ord(s[code])-ord('0'));
    inc(code);
    while (code <= length(s)) and (s[code] = '_') do inc(code);
  end;
  { Decimal ? }
  if (length(s) >= code) and (s[code] = '.') then begin
    hd := 1.0;
    inc(code);
    while (length(s)>=code) and (s[code] in ['0'..'9']) do begin
      { Read fractional part. }
      flags := flags or 2;
      result := result * 10.0 + toFloat(ord(s[code])-ord('0'));
      hd := hd * 10.0;
      inc(code);
      while (code <= length(s)) and (s[code] = '_') do inc(code);
    end;
    result := result / hd;
  end;
  { Again, read int and fractional part }
  if flags = 0 then
    raise EInvalidValue.create('invalid float: ' + s);
 { Exponent ? }
  if (length(s) >= code) and (upcase(s[code]) = 'E') then begin
    inc(code);
    if Length(s) >= code then
      if s[code] = '+' then
        inc(code)
      else
        if s[code] = '-' then begin
          esign := -1;
          inc(code);
        end;
    if (length(s) < code) or not (s[code] in ['0'..'9']) then
      raise EInvalidValue.create('');
    while (length(s) >= code) and (s[code] in ['0'..'9']) do begin
      exponent := exponent * 10;
      exponent := exponent + ord(s[code])-ord('0');
      inc(code);
      while (code <= length(s)) and (s[code] = '_') do inc(code);
    end;
  end;
  { Calculate Exponent }
  hd := 1.0;
  for i := 1 to exponent do hd := hd * 10.0;
  if esign > 0 then
    result := result * hd
  else
    result := result / hd;
  { Not all characters are read ? }
  if checkEnd and (length(s) >= code) then
    raise EInvalidValue.create('invalid float: ' + s);
  { evaluate sign }
  result := result * sign;
end;

{@ignore}
{$ifdef Q_on}
{$Q+} // turn it on again!
{$endif}
{@emit
@pop # overflowChecks
}

end.
