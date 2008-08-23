//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit lexbase;

// Base Object of a lexer with efficient buffer handling. In fact
// I believe that this is the most efficient method of buffer
// handling that exists! Only at line endings checks are necessary
// if the buffer needs refilling.

interface

uses
  nsystem, charsets, strutils;

{@emit
const
  Lrz = ' ';
  Apo = '''';
  Tabulator = #9;
  ESC = #27;
  CR = #13;
  FF = #12;
  LF = #10;
  BEL = #7;
  BACKSPACE = #8;
  VT = #11;
}

const
  EndOfFile = #0;          // end of file marker
{ A little picture makes everything clear :-)
  buf:
  "Example Text\n ha!"   bufLen = 17
   ^pos = 0     ^ sentinel = 12
}
  NewLines = {@set}[CR, LF];

type
  TBaseLexer = object(NObject)
    bufpos: int;
    buf: PChar;      // NOT zero terminated!
    bufLen: int;     // length of buffer in characters
    f: TBinaryFile;  // we use a binary file here for efficiency
    LineNumber: int; // the current line number
    // private data:
    sentinel: int;
    lineStart: int;     // index of last line start in buffer
    fileOpened: boolean;
  end;

function initBaseLexer(out L: TBaseLexer;
                       const filename: string;
                       bufLen: int = 8192): boolean;
    // 8K is a reasonable buffer size

procedure initBaseLexerFromBuffer(out L: TBaseLexer;
                                  const buffer: string);

procedure deinitBaseLexer(var L: TBaseLexer);

function getCurrentLine(const L: TBaseLexer; marker: boolean = true): string;
function getColNumber(const L: TBaseLexer; pos: int): int;

function HandleCR(var L: TBaseLexer; pos: int): int;
// Call this if you scanned over CR in the buffer; it returns the the
// position to continue the scanning from. `pos` must be the position
// of the CR.

function HandleLF(var L: TBaseLexer; pos: int): int;
// Call this if you scanned over LF in the buffer; it returns the the
// position to continue the scanning from. `pos` must be the position
// of the LF.

implementation

const
  chrSize = sizeof(char);

procedure deinitBaseLexer(var L: TBaseLexer);
begin
  dealloc(L.buf);
  if L.fileOpened then closeFile(L.f);
end;

{@ignore}
{$ifdef false}
procedure printBuffer(const L: TBaseLexer);
var
  i: int;
begin
  writeln('____________________________________');
  writeln('sentinel: ', L.sentinel);
  writeln('bufLen: ', L.bufLen);
  writeln('buf: ');
  for i := 0 to L.bufLen-1 do write(L.buf[i]);
  writeln(NL + '____________________________________');
end;
{$endif}
{@emit}

procedure FillBuffer(var L: TBaseLexer);
var
  charsRead, toCopy, s: int; // all are in characters,
                             // not bytes (in case this
                             // is not the same)
  oldBufLen: int;
begin
  // we know here that pos == L.sentinel, but not if this proc
  // is called the first time by initBaseLexer()
  assert(L.sentinel < L.bufLen);
  toCopy := L.BufLen - L.sentinel - 1;
  assert(toCopy >= 0);
  if toCopy > 0 then
    MoveMem(L.buf, addr(L.buf[L.sentinel+1]), toCopy * chrSize);
    // "moveMem" handles overlapping regions
  charsRead := ReadBuffer(L.f, addr(L.buf[toCopy]), (L.sentinel+1) * chrSize)
                 div chrSize;
  s := toCopy + charsRead;
  if charsRead < L.sentinel+1 then begin
    L.buf[s] := EndOfFile; // set end marker
    L.sentinel := s
  end
  else begin
    // compute sentinel:
    dec(s); // BUGFIX (valgrind)
    while true do begin
      assert(s < L.bufLen);
      while (s >= 0) and not (L.buf[s] in NewLines) do Dec(s);
      if s >= 0 then begin
        // we found an appropriate character for a sentinel:
        L.sentinel := s;
        break
      end
      else begin
        // rather than to give up here because the line is too long,
        // double the buffer's size and try again:
        oldBufLen := L.BufLen;
        L.bufLen := L.BufLen * 2;
        L.buf := {@cast}PChar(realloc(L.buf, L.bufLen*chrSize));
        assert(L.bufLen - oldBuflen = oldBufLen);
        charsRead := ReadBuffer(L.f, addr(L.buf[oldBufLen]), oldBufLen*chrSize)
                      div chrSize;
        if charsRead < oldBufLen then begin
          L.buf[oldBufLen+charsRead] := EndOfFile;
          L.sentinel := oldBufLen+charsRead;
          break
        end;
        s := L.bufLen - 1
      end
    end
  end
end;

function fillBaseLexer(var L: TBaseLexer; pos: int): int;
begin
  assert(pos <= L.sentinel);
  if pos < L.sentinel then begin
    result := pos+1;          // nothing to do
  end
  else begin
    fillBuffer(L);
    L.bufpos := 0;          // XXX: is this really correct?
    result := 0;
  end;
  L.lineStart := result;
end;

function HandleCR(var L: TBaseLexer; pos: int): int;
begin
  assert(L.buf[pos] = CR);
  inc(L.linenumber);
  result := fillBaseLexer(L, pos);
  if L.buf[result] = LF then begin
    result := fillBaseLexer(L, result);
  end;
  //L.lastNL := result-1; // BUGFIX: was: result;
end;

function HandleLF(var L: TBaseLexer; pos: int): int;
begin
  assert(L.buf[pos] = LF);
  inc(L.linenumber);
  result := fillBaseLexer(L, pos);
  //L.lastNL := result-1; // BUGFIX: was: result;
end;

procedure skip_UTF_8_BOM(var L: TBaseLexer);
begin
  if (L.buf[0] = #239) and (L.buf[1] = #187) and (L.buf[2] = #191) then begin
    inc(L.bufpos, 3);
    inc(L.lineStart, 3)
  end
end;

function initBaseLexer(out L: TBaseLexer; const filename: string;
                       bufLen: int = 8192): boolean;
begin
  assert(bufLen > 0);
  L.bufpos := 0;
  L.bufLen := bufLen;
  L.buf := {@cast}PChar(alloc(bufLen * chrSize));
  L.sentinel := bufLen-1;
  L.lineStart := 0;
  L.linenumber := 1; // lines start at 1
  L.fileOpened := openFile(L.f, filename);
  result := L.fileOpened;
  if result then begin
    fillBuffer(L);
    skip_UTF_8_BOM(L)
  end;
end;

procedure initBaseLexerFromBuffer(out L: TBaseLexer;
                                  const buffer: string);
begin
  L.bufpos := 0;
  L.bufLen := length(buffer)+1;
  L.buf := {@cast}PChar(alloc(L.bufLen * chrSize));
  L.sentinel := L.bufLen-1;
  L.lineStart := 0;
  L.linenumber := 1; // lines start at 1
  L.fileOpened := false;
  if L.bufLen > 0 then begin
    copyMem(L.buf, {@cast}pointer(buffer), L.bufLen);
    L.buf[L.bufLen-1] := EndOfFile;
  end
  else
    L.buf[0] := EndOfFile;
  skip_UTF_8_BOM(L);
end;

function getColNumber(const L: TBaseLexer; pos: int): int;
begin
  result := pos - L.lineStart;
  assert(result >= 0);
end;

function getCurrentLine(const L: TBaseLexer; marker: boolean = true): string;
var
  i: int;
begin
  result := '';
  i := L.lineStart;
  while not (L.buf[i] in [CR, LF, EndOfFile]) do begin
    addChar(result, L.buf[i]);
    inc(i)
  end;
  result := result +{&} NL;
  if marker then
    result := result +{&} RepeatChar(getColNumber(L, L.bufpos)) +{&} '^' +{&} NL
end;

end.
