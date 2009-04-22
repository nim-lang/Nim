//
//
//            Nimrod's Runtime Library
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit parsecfg;

// A HIGH-PERFORMANCE configuration file parser;
// the Nimrod version of this file is part of the
// standard library.

interface

{$include 'config.inc'}

uses
  nsystem, charsets, llstream, sysutils, hashes, strutils, lexbase;

type
  TCfgEventKind = (
    cfgEof,     // end of file reached
    cfgSectionStart, // a ``[section]`` has been parsed
    cfgKeyValuePair, // a ``key=value`` pair has been detected
    cfgOption, // a ``--key=value`` command line option
    cfgError   // an error ocurred during parsing; msg contains the
               // error message
  );
  TCfgEvent = {@ignore} record
    kind: TCfgEventKind;
    section: string;
    key, value: string;
    msg: string;
  end;
  {@emit object(NObject)
    case kind: TCfgEventKind of
      cfgEof: ();
      cfgSectionStart: (section: string);
      cfgKeyValuePair, cfgOption: (key, value: string);
      cfgError: (msg: string);
  end;}
  TTokKind = (tkInvalid, tkEof, // order is important here!
    tkSymbol, tkEquals, tkColon,
    tkBracketLe, tkBracketRi, tkDashDash
  );
  TToken = record       // a token
    kind: TTokKind;     // the type of the token
    literal: string;    // the parsed (string) literal
  end;
  TParserState = (startState, commaState);
  TCfgParser = object(TBaseLexer)
    tok: TToken;
    state: TParserState;
    filename: string;
  end;

procedure Open(var c: TCfgParser; const filename: string;
               inputStream: PLLStream);
procedure Close(var c: TCfgParser);

function next(var c: TCfgParser): TCfgEvent;

function getColumn(const c: TCfgParser): int;
function getLine(const c: TCfgParser): int;
function getFilename(const c: TCfgParser): string;

function errorStr(const c: TCfgParser; const msg: string): string;

implementation

const
  SymChars: TCharSet = ['a'..'z', 'A'..'Z', '0'..'9', '_', #128..#255];

// ----------------------------------------------------------------------------
procedure rawGetTok(var c: TCfgParser; var tok: TToken); forward;

procedure open(var c: TCfgParser; const filename: string;
               inputStream: PLLStream);
begin
{@ignore}
  FillChar(c, sizeof(c), 0);
{@emit}
  openBaseLexer(c, inputStream);
  c.filename := filename;
  c.state := startState;
  c.tok.kind := tkInvalid;
  c.tok.literal := '';
  rawGetTok(c, c.tok);
end;

procedure close(var c: TCfgParser);
begin
  closeBaseLexer(c);
end;

function getColumn(const c: TCfgParser): int;
begin
  result := getColNumber(c, c.bufPos)
end;

function getLine(const c: TCfgParser): int;
begin
  result := c.linenumber
end;

function getFilename(const c: TCfgParser): string;
begin
  result := c.filename
end;

// ----------------------------------------------------------------------------

procedure handleHexChar(var c: TCfgParser; var xi: int);
begin
  case c.buf[c.bufpos] of
    '0'..'9': begin
      xi := (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('0'));
      inc(c.bufpos);
    end;
    'a'..'f': begin
      xi := (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('a') + 10);
      inc(c.bufpos);
    end;
    'A'..'F': begin
      xi := (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('A') + 10);
      inc(c.bufpos);
    end;
    else begin end // do nothing
  end
end;

procedure handleDecChars(var c: TCfgParser; var xi: int);
begin
  while c.buf[c.bufpos] in ['0'..'9'] do begin
    xi := (xi * 10) + (ord(c.buf[c.bufpos]) - ord('0'));
    inc(c.bufpos);
  end;
end;

procedure getEscapedChar(var c: TCfgParser; var tok: TToken);
var
  xi: int;
begin
  inc(c.bufpos); // skip '\'
  case c.buf[c.bufpos] of
    'n', 'N': begin
      tok.literal := tok.literal +{&} nl;
      Inc(c.bufpos);
    end;
    'r', 'R', 'c', 'C': begin addChar(tok.literal, CR); Inc(c.bufpos); end;
    'l', 'L': begin addChar(tok.literal, LF); Inc(c.bufpos); end;
    'f', 'F': begin addChar(tok.literal, FF); inc(c.bufpos); end;
    'e', 'E': begin addChar(tok.literal, ESC); Inc(c.bufpos); end;
    'a', 'A': begin addChar(tok.literal, BEL); Inc(c.bufpos); end;
    'b', 'B': begin addChar(tok.literal, BACKSPACE); Inc(c.bufpos); end;
    'v', 'V': begin addChar(tok.literal, VT); Inc(c.bufpos); end;
    't', 'T': begin addChar(tok.literal, Tabulator); Inc(c.bufpos); end;
    '''', '"': begin addChar(tok.literal, c.buf[c.bufpos]); Inc(c.bufpos); end;
    '\': begin addChar(tok.literal, '\'); Inc(c.bufpos) end;
    'x', 'X': begin
      inc(c.bufpos);
      xi := 0;
      handleHexChar(c, xi);
      handleHexChar(c, xi);
      addChar(tok.literal, Chr(xi));
    end;
    '0'..'9': begin
      xi := 0;
      handleDecChars(c, xi);
      if (xi <= 255) then
        addChar(tok.literal, Chr(xi))
      else
        tok.kind := tkInvalid
    end
    else tok.kind := tkInvalid
  end
end;

function HandleCRLF(var c: TCfgParser; pos: int): int;
begin
  case c.buf[pos] of
    CR: result := lexbase.HandleCR(c, pos);
    LF: result := lexbase.HandleLF(c, pos);
    else result := pos
  end
end;

procedure getString(var c: TCfgParser; var tok: TToken; rawMode: Boolean);
var
  pos: int;
  ch: Char;
  buf: PChar;
begin
  pos := c.bufPos + 1; // skip "
  buf := c.buf; // put `buf` in a register
  tok.kind := tkSymbol;
  if (buf[pos] = '"') and (buf[pos+1] = '"') then begin
    // long string literal:
    inc(pos, 2); // skip ""
    // skip leading newline:
    pos := HandleCRLF(c, pos);
    repeat
      case buf[pos] of
        '"': begin
          if (buf[pos+1] = '"') and (buf[pos+2] = '"') then
            break;
          addChar(tok.literal, '"');
          Inc(pos)
        end;
        CR, LF: begin
          pos := HandleCRLF(c, pos);
          tok.literal := tok.literal +{&} nl;
        end;
        lexbase.EndOfFile: begin
          tok.kind := tkInvalid;
          break
        end
        else begin
          addChar(tok.literal, buf[pos]);
          Inc(pos)
        end
      end
    until false;
    c.bufpos := pos + 3 // skip the three """
  end
  else begin // ordinary string literal
    repeat
      ch := buf[pos];
      if ch = '"' then begin
        inc(pos); // skip '"'
        break
      end;
      if ch in [CR, LF, lexbase.EndOfFile] then begin
        tok.kind := tkInvalid;
        break
      end;
      if (ch = '\') and not rawMode then begin
        c.bufPos := pos;
        getEscapedChar(c, tok);
        pos := c.bufPos;
      end
      else begin
        addChar(tok.literal, ch);
        Inc(pos)
      end
    until false;
    c.bufpos := pos;
  end
end;

procedure getSymbol(var c: TCfgParser; var tok: TToken);
var
  pos: int;
  buf: pchar;
begin
  pos := c.bufpos;
  buf := c.buf;
  while true do begin
    addChar(tok.literal, buf[pos]);
    Inc(pos);
    if not (buf[pos] in SymChars) then break;
  end;
  c.bufpos := pos;
  tok.kind := tkSymbol
end;

procedure skip(var c: TCfgParser);
var
  buf: PChar;
  pos: int;
begin
  pos := c.bufpos;
  buf := c.buf;
  repeat
    case buf[pos] of
      ' ': Inc(pos);
      Tabulator: inc(pos);
      '#', ';': while not (buf[pos] in [CR, LF, lexbase.EndOfFile]) do inc(pos);
      CR, LF: pos := HandleCRLF(c, pos);
      else break // EndOfFile also leaves the loop
    end
  until false;
  c.bufpos := pos;
end;

procedure rawGetTok(var c: TCfgParser; var tok: TToken);
begin
  tok.kind := tkInvalid;
  setLength(tok.literal, 0);
  skip(c);
  case c.buf[c.bufpos] of
    '=': begin
      tok.kind := tkEquals;
      inc(c.bufpos);
      tok.literal := '='+'';
    end;
    '-': begin
      inc(c.bufPos);
      if c.buf[c.bufPos] = '-' then inc(c.bufPos);
      tok.kind := tkDashDash;
      tok.literal := '--';
    end;
    ':': begin
      tok.kind := tkColon;
      inc(c.bufpos);
      tok.literal := ':'+'';
    end;
    'r', 'R': begin
      if c.buf[c.bufPos+1] = '"' then begin
        Inc(c.bufPos);
        getString(c, tok, true);
      end
      else
        getSymbol(c, tok);
    end;
    '[': begin
      tok.kind := tkBracketLe;
      inc(c.bufpos);
      tok.literal := '['+'';
    end;
    ']': begin
      tok.kind := tkBracketRi;
      Inc(c.bufpos);
      tok.literal := ']'+'';
    end;
    '"': getString(c, tok, false);
    lexbase.EndOfFile: tok.kind := tkEof;
    else getSymbol(c, tok);
  end
end;

function errorStr(const c: TCfgParser; const msg: string): string;
begin
  result := format('$1($2, $3) Error: $4', [
    c.filename, toString(getLine(c)), toString(getColumn(c)),
    msg
  ]);
end;

function getKeyValPair(var c: TCfgParser; kind: TCfgEventKind): TCfgEvent;
begin
  if c.tok.kind = tkSymbol then begin
    result.kind := kind;
    result.key := c.tok.literal;
    result.value := '';
    rawGetTok(c, c.tok);
    while c.tok.literal = '.'+'' do begin
      addChar(result.key, '.');
      rawGetTok(c, c.tok);
      if c.tok.kind = tkSymbol then begin
        add(result.key, c.tok.literal);
        rawGetTok(c, c.tok);
      end
      else begin
        result.kind := cfgError;
        result.msg := errorStr(c, 'symbol expected, but found: ' +
                               c.tok.literal);
        break
      end
    end;
    if c.tok.kind in [tkEquals, tkColon] then begin
      rawGetTok(c, c.tok);
      if c.tok.kind = tkSymbol then begin
        result.value := c.tok.literal;
      end
      else begin
        result.kind := cfgError;
        result.msg := errorStr(c, 'symbol expected, but found: '
                               + c.tok.literal);
      end;
      rawGetTok(c, c.tok);
    end
  end
  else begin
    result.kind := cfgError;
    result.msg := errorStr(c, 'symbol expected, but found: ' + c.tok.literal);
    rawGetTok(c, c.tok);
  end;
end;

function next(var c: TCfgParser): TCfgEvent;
begin
  case c.tok.kind of
    tkEof: result.kind := cfgEof;
    tkDashDash: begin
      rawGetTok(c, c.tok);
      result := getKeyValPair(c, cfgOption);
    end;
    tkSymbol: begin
      result := getKeyValPair(c, cfgKeyValuePair);
    end;
    tkBracketLe: begin
      rawGetTok(c, c.tok);
      if c.tok.kind = tkSymbol then begin
        result.kind := cfgSectionStart;
        result.section := c.tok.literal;
      end
      else begin
        result.kind := cfgError;
        result.msg := errorStr(c, 'symbol expected, but found: ' + c.tok.literal);
      end;
      rawGetTok(c, c.tok);
      if c.tok.kind = tkBracketRi then rawGetTok(c, c.tok)
      else begin
        result.kind := cfgError;
        result.msg := errorStr(c, ''']'' expected, but found: ' + c.tok.literal);
      end
    end;
    tkInvalid, tkBracketRi, tkEquals, tkColon: begin
      result.kind := cfgError;
      result.msg := errorStr(c, 'invalid token: ' + c.tok.literal);
      rawGetTok(c, c.tok);
    end
  end
end;

end.
