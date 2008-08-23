//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit scanner;

// This scanner is handwritten for efficiency. I used an elegant buffering
// scheme which I have not seen anywhere else:
// We guarantee that a hole line is in the buffer (too long lines are reported
// as an error). Thus only when scanning the \n or \r character we have
// to check wether we need to read in the next chunk. (\n or \r already need
// special handling for incrementing the line counter; choosing both \n and \r
// allows the scanner to properly read Unix, DOS or Macintosh text files, even
// when it is not the native format.

interface

{$include 'config.inc'}

uses
  charsets, nsystem, sysutils,
  hashes, options, msgs, strutils, platform, idents,
  lexbase, wordrecg;

const
  MaxLineLength = 80; // lines longer than this lead to a warning

  numChars: TCharSet = ['0'..'9','a'..'z','A'..'Z']; // we support up to base 36
  SymChars: TCharSet = ['a'..'z', 'A'..'Z', '0'..'9', #128..#255];
  SymStartChars: TCharSet = ['a'..'z', 'A'..'Z', #128..#255];
  OpChars: TCharSet = ['+', '-', '*', '/', '<', '>', '!', '?', '^', '.',
    '|', '=', '%', '&', '$', '@', '~', #128..#255];

type
  TTokType = (tkInvalid, tkEof, // order is important here!
    tkSymbol,
    // keywords:
    //[[[cog
    //keywords = (file("data/keywords.txt").read()).split()
    //idents = ""
    //strings = ""
    //i = 1
    //for k in keywords:
    //  idents += "tk" + k.capitalize() + ", "
    //  strings += "'" + k + "', "
    //  if i % 4 == 0: idents += "\n"; strings += "\n"
    //  i += 1
    //cog.out(idents)
    //]]]
    tkAddr, tkAnd, tkAs, tkAsm, 
    tkBlock, tkBreak, tkCase, tkCast, 
    tkConst, tkContinue, tkConverter, tkDiscard, 
    tkDiv, tkElif, tkElse, tkEnd, 
    tkEnum, tkExcept, tkException, tkFinally, 
    tkFor, tkFrom, tkGeneric, tkIf, 
    tkImplies, tkImport, tkIn, tkInclude, 
    tkIs, tkIsnot, tkIterator, tkLambda, 
    tkMacro, tkMethod, tkMod, tkNil, 
    tkNot, tkNotin, tkObject, tkOf, 
    tkOr, tkOut, tkProc, tkPtr, 
    tkRaise, tkRef, tkReturn, tkShl, 
    tkShr, tkTemplate, tkTry, tkTuple, 
    tkType, tkVar, tkWhen, tkWhere, 
    tkWhile, tkWith, tkWithout, tkXor, 
    tkYield, 
    //[[[end]]]
    tkIntLit, tkInt8Lit, tkInt16Lit, tkInt32Lit, tkInt64Lit,
    tkFloatLit, tkFloat32Lit, tkFloat64Lit,
    tkStrLit, tkRStrLit, tkTripleStrLit, tkCharLit,
    tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
    tkBracketDotLe, tkBracketDotRi, // [. and  .]
    tkCurlyDotLe, tkCurlyDotRi, // {.  and  .}
    tkParDotLe, tkParDotRi, // (. and .)
    tkComma, tkSemiColon, tkColon,
    tkEquals, tkDot, tkDotDot, tkHat, tkOpr,
    tkComment, tkAccent, tkInd, tkSad, tkDed,
    // pseudo token types used by the source renderers:
    tkSpaces, tkInfixOpr, tkPrefixOpr, tkPostfixOpr
  );
  TTokTypes = set of TTokType;
const
  tokKeywordLow = succ(tkSymbol);
  tokKeywordHigh = pred(tkIntLit);
  tokOperators: TTokTypes = {@set}[tkOpr, tkSymbol, tkBracketLe, tkBracketRi,
    tkIn, tkIs, tkIsNot, tkEquals, tkDot, tkHat, tkNot, tkAnd, tkOr, tkXor,
    tkShl, tkShr, tkDiv, tkMod, tkNotIn];

  TokTypeToStr: array [TTokType] of string = (
    'tkInvalid', '[EOF]',
    'tkSymbol',
    //[[[cog
    //cog.out(strings)
    //]]]
    'addr', 'and', 'as', 'asm', 
    'block', 'break', 'case', 'cast', 
    'const', 'continue', 'converter', 'discard', 
    'div', 'elif', 'else', 'end', 
    'enum', 'except', 'exception', 'finally', 
    'for', 'from', 'generic', 'if', 
    'implies', 'import', 'in', 'include', 
    'is', 'isnot', 'iterator', 'lambda', 
    'macro', 'method', 'mod', 'nil', 
    'not', 'notin', 'object', 'of', 
    'or', 'out', 'proc', 'ptr', 
    'raise', 'ref', 'return', 'shl', 
    'shr', 'template', 'try', 'tuple', 
    'type', 'var', 'when', 'where', 
    'while', 'with', 'without', 'xor', 
    'yield', 
    //[[[end]]]
    'tkIntLit', 'tkInt8Lit', 'tkInt16Lit', 'tkInt32Lit', 'tkInt64Lit',
    'tkFloatLit', 'tkFloat32Lit', 'tkFloat64Lit',
    'tkStrLit', 'tkRStrLit', 'tkTripleStrLit', 'tkCharLit',
    '('+'', ')'+'', '['+'', ']'+'', '{'+'', '}'+'',
    '[.', '.]', '{.', '.}', '(.', '.)', ','+'', ';'+'', ':'+'',
    '='+'', '.'+'', '..', '^'+'', 'tkOpr',
    'tkComment', '`'+'', '[new indentation]', '[same indentation]',
    '[dedentation]',
    'tkSpaces', 'tkInfixOpr', 'tkPrefixOpr', 'tkPostfixOpr'
  );

type
  TNumericalBase = (base10, // base10 is listed as the first element,
                            // so that it is the correct default value
                    base2,
                    base8,
                    base16);
  PToken = ^TToken;
  TToken = object          // a Nimrod token
    tokType: TTokType;     // the type of the token
    indent: int;           // the indentation; only valid if tokType = tkIndent
    ident: PIdent;         // the parsed identifier
    iNumber: BiggestInt;   // the parsed integer literal
    fNumber: BiggestFloat; // the parsed floating point literal
    base: TNumericalBase;  // the numerical base; only valid for int
                           // or float literals
    literal: string;       // the parsed (string) literal; and
                           // documentation comments are here too
    next: PToken;          // next token; used for arbitrary look-ahead
  end;

  PLexer = ^TLexer;
  TLexer = object(TBaseLexer)
    // lexers can be put into a stack through the next pointer;
    // this feature is currently unused, however
    filename: string;
    next: PLexer;
    indentStack: array of int; // the indentation stack
    dedent: int;             // counter for DED token generation
    indentAhead: int;        // if > 0 an indendation has already been read
                             // this is needed because scanning # comments
                             // needs so much look-ahead
  end;

procedure pushInd(var L: TLexer; indent: int);
function isKeyword(kind: TTokType): boolean;

function openLexer(out lex: TLexer; const filename: string): TResult;
procedure bufferLexer(out lex: TLexer; const buf: string);

procedure rawGetTok(var L: TLexer; var tok: TToken);
// reads in the next token into tok and skips it

function getColumn(const L: TLexer): int;

function getLineInfo(const L: TLexer): TLineInfo;

procedure closeLexer(var lex: TLexer);

procedure PrintTok(tok: PToken);
function tokToStr(tok: PToken): string;

// auxiliary functions:
procedure lexMessage(const L: TLexer; const msg: TMsgKind;
                     const arg: string = '');

// the Pascal scanner uses this too:
procedure fillToken(var L: TToken);

implementation

function isKeyword(kind: TTokType): boolean;
begin
  result := (kind >= tokKeywordLow) and (kind <= tokKeywordHigh)
end;

procedure pushInd(var L: TLexer; indent: int);
var
  len: int;
begin
  len := length(L.indentStack);
  setLength(L.indentStack, len+1);
  assert(indent > L.indentStack[len-1]);
  L.indentstack[len] := indent;
  //writeln('push indent ', indent);
end;

function findIdent(const L: TLexer; indent: int): boolean;
var
  i: int;
begin
  for i := length(L.indentStack)-1 downto 0 do
    if L.indentStack[i] = indent then begin result := true; exit end;
  result := false
end;

function tokToStr(tok: PToken): string;
begin
  case tok.tokType of
    tkIntLit..tkInt64Lit:
      result := toString(tok.iNumber);
    tkFloatLit..tkFloat64Lit:
      result := toStringF(tok.fNumber);
    tkInvalid, tkStrLit..tkCharLit, tkComment:
      result := tok.literal;
    tkParLe..tkColon, tkEof, tkInd, tkSad, tkDed, tkAccent:
      result := tokTypeToStr[tok.tokType];
    else if (tok.ident <> nil) then
      result := tok.ident.s
    else begin
      assert(false);
      result := ''
    end
  end
end;

procedure PrintTok(tok: PToken);
begin
  write(output, TokTypeToStr[tok.tokType]);
  write(output, ' '+'');
  writeln(output, tokToStr(tok))
end;

// ----------------------------------------------------------------------------

var
  dummyIdent: PIdent;

procedure fillToken(var L: TToken);
begin
  L.TokType := tkInvalid;
  L.iNumber := 0;
  L.Indent := 0;
  L.literal := '';
  L.fNumber := 0.0;
  L.base := base10;
  L.ident := dummyIdent; // this prevents many bugs!
end;

function openLexer(out lex: TLexer; const filename: string): TResult;
begin
{@ignore}
  FillChar(lex, sizeof(lex), 0); // work around Delphi/fpc bug
{@emit}
  if initBaseLexer(lex, filename) then
    result := Success
  else
    result := Failure;
{@ignore}
  setLength(lex.indentStack, 1);
  lex.indentStack[0] := 0;
{@emit lex.indentStack := [0]; }
  lex.filename := filename;
  lex.indentAhead := -1;
end;

procedure bufferLexer(out lex: TLexer; const buf: string);
begin
{@ignore}
  FillChar(lex, sizeof(lex), 0); // work around Delphi/fpc bug
{@emit}
  initBaseLexerFromBuffer(lex, buf);
{@ignore}
  setLength(lex.indentStack, 1);
  lex.indentStack[0] := 0;
{@emit lex.indentStack := [0]; }
  lex.filename := 'buffer';
  lex.indentAhead := -1;
end;

procedure closeLexer(var lex: TLexer);
begin
  deinitBaseLexer(lex);
end;

function getColumn(const L: TLexer): int;
begin
  result := getColNumber(L, L.bufPos)
end;

function getLineInfo(const L: TLexer): TLineInfo;
begin
  result := newLineInfo(L.filename, L.linenumber, getColNumber(L, L.bufpos))
end;

procedure lexMessage(const L: TLexer; const msg: TMsgKind;
                     const arg: string = '');
begin
  msgs.liMessage(getLineInfo(L), msg, arg)
end;

procedure lexMessagePos(var L: TLexer; const msg: TMsgKind; pos: int;
                        const arg: string = '');
var
  info: TLineInfo;
begin
  info := newLineInfo(L.filename, L.linenumber, pos - L.lineStart);
  msgs.liMessage(info, msg, arg);
end;

// ----------------------------------------------------------------------------

procedure matchUnderscoreChars(var L: TLexer; var tok: TToken;
                               const chars: TCharSet);
// matches ([chars]_)*
var
  pos: int;
  buf: PChar;
begin
  pos := L.bufpos; // use registers for pos, buf
  buf := L.buf;
  repeat
    if buf[pos] in chars then begin
      addChar(tok.literal, buf[pos]);
      Inc(pos)
    end
    else break;
    if buf[pos] = '_' then begin
      addChar(tok.literal, '_');
      Inc(pos);
    end;
  until false;
  L.bufPos := pos;
end;

function matchTwoChars(const L: TLexer; first: Char;
                       const second: TCharSet): Boolean;
begin
  result := (L.buf[L.bufpos] = first) and (L.buf[L.bufpos+1] in Second);
end;

function isFloatLiteral(const s: string): boolean;
var
  i: int;
begin
  for i := strStart to length(s)+strStart-1 do
    if s[i] in ['.','e','E'] then begin
      result := true; exit
    end;
  result := false
end;

function GetNumber(var L: TLexer): TToken;
// extremely hard work above us!
var
  pos, endpos: int;
  xi: biggestInt;
begin
  // get the base:
  result.tokType := tkIntLit; // int literal until we know better
  result.literal := '';
  result.base := base10; // BUGFIX
  pos := L.bufpos;
  // make sure the literal is correct for error messages:
  matchUnderscoreChars(L, result, ['A'..'Z', 'a'..'z', '0'..'9']);
  if (L.buf[L.bufpos] = '.') and (L.buf[L.bufpos+1] in ['0'..'9']) then begin
    addChar(result.literal, '.');
    inc(L.bufpos);
    //matchUnderscoreChars(L, result, ['A'..'Z', 'a'..'z', '0'..'9'])
    matchUnderscoreChars(L, result, ['0'..'9']);
    if L.buf[L.bufpos] in ['e', 'E'] then begin
      addChar(result.literal, 'e');
      inc(L.bufpos);
      if L.buf[L.bufpos] in ['+', '-'] then begin
        addChar(result.literal, L.buf[L.bufpos]);
        inc(L.bufpos);
      end;
      matchUnderscoreChars(L, result, ['0'..'9']);
    end
  end;
  endpos := L.bufpos;
  if L.buf[endpos] = '''' then begin
    //matchUnderscoreChars(L, result, ['''', 'f', 'F', 'i', 'I', '0'..'9']);
    inc(endpos);
    L.bufpos := pos; // restore position
    case L.buf[endpos] of
      'f', 'F': begin
        inc(endpos);
        if (L.buf[endpos] = '6') and (L.buf[endpos+1] = '4') then begin
          result.tokType := tkFloat64Lit;
          inc(endpos, 2);
        end
        else if (L.buf[endpos] = '3') and (L.buf[endpos+1] = '2') then begin
          result.tokType := tkFloat32Lit;
          inc(endpos, 2);
        end
        else lexMessage(L, errInvalidNumber, result.literal);
      end;
      'i', 'I': begin
        inc(endpos);
        if (L.buf[endpos] = '6') and (L.buf[endpos+1] = '4') then begin
          result.tokType := tkInt64Lit;
          inc(endpos, 2);
        end
        else if (L.buf[endpos] = '3') and (L.buf[endpos+1] = '2') then begin
          result.tokType := tkInt32Lit;
          inc(endpos, 2);
        end
        else if (L.buf[endpos] = '1') and (L.buf[endpos+1] = '6') then begin
          result.tokType := tkInt16Lit;
          inc(endpos, 2);
        end
        else if (L.buf[endpos] = '8') then begin
          result.tokType := tkInt8Lit;
          inc(endpos);
        end
        else lexMessage(L, errInvalidNumber, result.literal);
      end;
      else lexMessage(L, errInvalidNumber, result.literal);
    end
  end
  else
    L.bufpos := pos; // restore position

  try
    if (L.buf[pos] = '0') and (L.buf[pos+1] in ['x','X','b','B','o','O'])
    then begin
      inc(pos, 2);
      xi := 0;
      // it may be a base prefix
      case L.buf[pos-1] of
        'b', 'B': begin
          result.base := base2;
          while true do begin
            case L.buf[pos] of
              'A'..'Z', 'a'..'z', '2'..'9', '.': begin
                lexMessage(L, errInvalidNumber, result.literal);
                inc(pos)
              end;
              '_': inc(pos);
              '0', '1': begin
                xi := (xi shl 1) or (ord(L.buf[pos]) - ord('0'));
                inc(pos);
              end;
              else break;
            end
          end
        end;
        'o': begin
          result.base := base8;
          while true do begin
            case L.buf[pos] of
              'A'..'Z', 'a'..'z', '8'..'9', '.': begin
                lexMessage(L, errInvalidNumber, result.literal);
                inc(pos)
              end;
              '_': inc(pos);
              '0'..'7': begin
                xi := (xi shl 3) or (ord(L.buf[pos]) - ord('0'));
                inc(pos);
              end;
              else break;
            end
          end
        end;
        'O': lexMessage(L, errInvalidNumber, result.literal);
        'x', 'X': begin
          result.base := base16;
          while true do begin
            case L.buf[pos] of
              'G'..'Z', 'g'..'z', '.': begin
                lexMessage(L, errInvalidNumber, result.literal);
                inc(pos);
              end;
              '_': inc(pos);
              '0'..'9': begin
                xi := (xi shl 4) or (ord(L.buf[pos]) - ord('0'));
                inc(pos);
              end;
              'a'..'f': begin
                xi := (xi shl 4) or (ord(L.buf[pos]) - ord('a') + 10);
                inc(pos);
              end;
              'A'..'F': begin
                xi := (xi shl 4) or (ord(L.buf[pos]) - ord('A') + 10);
                inc(pos);
              end;
              else break;
            end
          end
        end;
        else assert(false);
      end;
      // now look at the optional type suffix:
      case result.tokType of
        tkIntLit..tkInt64Lit:
          result.iNumber := xi;
        tkFloat32Lit:
          result.fNumber := ({@cast}PFloat32(addr(xi)))^;
          // note: this code is endian neutral!
          // XXX: Test this on big endian machine!
        tkFloat64Lit:
          result.fNumber := ({@cast}PFloat64(addr(xi)))^;
        else assert(false);
      end
    end
    else if isFloatLiteral(result.literal)
         or (result.tokType = tkFloat32Lit)
         or (result.tokType = tkFloat64Lit) then begin
      result.fnumber := parseFloat(result.literal);
      if result.tokType = tkIntLit then result.tokType := tkFloatLit;
    end
    else begin
      result.iNumber := ParseBiggestInt(result.literal);
      if (result.iNumber < low(int32)) or (result.iNumber > high(int32)) then
      begin
        if result.tokType = tkIntLit then result.tokType := tkInt64Lit
        else if result.tokType <> tkInt64Lit then
          lexMessage(L, errInvalidNumber, result.literal);
      end
    end;
  except
    on EInvalidValue do
      lexMessage(L, errInvalidNumber, result.literal);
  {@ignore}
    on sysutils.EIntOverflow do
      lexMessage(L, errNumberOutOfRange, result.literal);
  {@emit}
    on EOverflow do
      lexMessage(L, errNumberOutOfRange, result.literal);
  end;
  L.bufpos := endpos;
end;

procedure handleHexChar(var L: TLexer; var xi: int);
begin
  case L.buf[L.bufpos] of
    '0'..'9': begin
      xi := (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('0'));
      inc(L.bufpos);
    end;
    'a'..'f': begin
      xi := (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('a') + 10);
      inc(L.bufpos);
    end;
    'A'..'F': begin
      xi := (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('A') + 10);
      inc(L.bufpos);
    end;
    else begin end // do nothing
  end
end;

procedure handleDecChars(var L: TLexer; var xi: int);
begin
  while L.buf[L.bufpos] in ['0'..'9'] do begin
    xi := (xi * 10) + (ord(L.buf[L.bufpos]) - ord('0'));
    inc(L.bufpos);
  end;
end;

procedure getEscapedChar(var L: TLexer; var tok: TToken);
var
  xi: int;
begin
  inc(L.bufpos); // skip '\'
  case L.buf[L.bufpos] of
    'n', 'N': begin
      if tok.toktype = tkCharLit then
        lexMessage(L, errNnotAllowedInCharacter);
      tok.literal := tok.literal +{&} tnl;
      Inc(L.bufpos);
    end;
    'r', 'R', 'c', 'C': begin addChar(tok.literal, CR); Inc(L.bufpos); end;
    'l', 'L': begin addChar(tok.literal, LF); Inc(L.bufpos); end;
    'f', 'F': begin addChar(tok.literal, FF); inc(L.bufpos); end;
    'e', 'E': begin addChar(tok.literal, ESC); Inc(L.bufpos); end;
    'a', 'A': begin addChar(tok.literal, BEL); Inc(L.bufpos); end;
    'b', 'B': begin addChar(tok.literal, BACKSPACE); Inc(L.bufpos); end;
    'v', 'V': begin addChar(tok.literal, VT); Inc(L.bufpos); end;
    't', 'T': begin addChar(tok.literal, Tabulator); Inc(L.bufpos); end;
    '''', '"': begin addChar(tok.literal, L.buf[L.bufpos]); Inc(L.bufpos); end;
    '\': begin addChar(tok.literal, '\'); Inc(L.bufpos) end;
    'x', 'X': begin
      inc(L.bufpos);
      xi := 0;
      handleHexChar(L, xi);
      handleHexChar(L, xi);
      addChar(tok.literal, Chr(xi));
    end;
    '0'..'9': begin
      if matchTwoChars(L, '0', ['0'..'9']) then
      // this warning will make it easier for newcomers:
        lexMessage(L, warnOctalEscape);
      xi := 0;
      handleDecChars(L, xi);
      if (xi <= 255) then
        addChar(tok.literal, Chr(xi))
      else
        lexMessage(L, errInvalidCharacterConstant)
    end
    else lexMessage(L, errInvalidCharacterConstant)
  end
end;

function HandleCRLF(var L: TLexer; pos: int): int;
begin
  case L.buf[pos] of
    CR: begin
      if getColNumber(L, pos) > MaxLineLength then
        lexMessagePos(L, hintLineTooLong, pos);
      result := lexbase.HandleCR(L, pos)
    end;
    LF: begin
      if getColNumber(L, pos) > MaxLineLength then
        lexMessagePos(L, hintLineTooLong, pos);
      result := lexbase.HandleLF(L, pos)
    end;
    else result := pos
  end
end;

procedure getString(var L: TLexer; var tok: TToken; rawMode: Boolean);
var
  line, line2, pos: int;
  c: Char;
  buf: PChar;
begin
  pos := L.bufPos + 1; // skip "
  buf := L.buf; // put `buf` in a register
  line := L.linenumber; // save linenumber for better error message
  if (buf[pos] = '"') and (buf[pos+1] = '"') then begin
    tok.tokType := tkTripleStrLit;
    // long string literal:
    inc(pos, 2); // skip ""
    // skip leading newline:
    pos := HandleCRLF(L, pos);
    repeat
      case buf[pos] of
        '"': begin
          if (buf[pos+1] = '"') and (buf[pos+2] = '"') then
            break;
          addChar(tok.literal, '"');
          Inc(pos)
        end;
        CR, LF: begin
          pos := HandleCRLF(L, pos);
          tok.literal := tok.literal +{&} tnl;
        end;
        lexbase.EndOfFile: begin
          line2 := L.linenumber;
          L.LineNumber := line;
          lexMessagePos(L, errClosingTripleQuoteExpected, L.lineStart);
          L.LineNumber := line2;
          break
        end
        else begin
          addChar(tok.literal, buf[pos]);
          Inc(pos)
        end
      end
    until false;
    L.bufpos := pos + 3 // skip the three """
  end
  else begin // ordinary string literal
    if rawMode then tok.tokType := tkRStrLit
    else tok.tokType := tkStrLit;
    repeat
      c := buf[pos];
      if c = '"' then begin
        inc(pos); // skip '"'
        break
      end;
      if c in [CR, LF, lexbase.EndOfFile] then begin
        lexMessage(L, errClosingQuoteExpected);
        break
      end;
      if (c = '\') and not rawMode then begin
        L.bufPos := pos;
        getEscapedChar(L, tok);
        pos := L.bufPos;
      end
      else begin
        addChar(tok.literal, c);
        Inc(pos)
      end
    until false;
    L.bufpos := pos;
  end
end;

procedure getCharacter(var L: TLexer; var tok: TToken);
var
  c: Char;
begin
  Inc(L.bufpos); // skip '
  c := L.buf[L.bufpos];
  case c of
    #0..Pred(' '), '''': lexMessage(L, errInvalidCharacterConstant);
    '\': getEscapedChar(L, tok);
    else begin
      tok.literal := c + '';
      Inc(L.bufpos);
    end
  end;
  if L.buf[L.bufpos] <> '''' then lexMessage(L, errMissingFinalQuote);
  inc(L.bufpos); // skip '
end;

{@ignore}
{$ifopt Q+} {$define Q_on} {$Q-} {$endif}
{$ifopt R+} {$define R_on} {$R-} {$endif}
{@emit}
procedure getSymbol(var L: TLexer; var tok: TToken);
var
  pos: int;
  c: Char;
  buf: pchar;
  h: THash; // hashing algorithm inlined
begin
  h := 0;
  pos := L.bufpos;
  buf := L.buf;
  while true do begin
    c := buf[pos];
    case c of
      'a'..'z', '0'..'9', #128..#255: begin
        h := h +{%} Ord(c);
        h := h +{%} h shl 10;
        h := h xor (h shr 6)
      end;
      'A'..'Z': begin
        c := chr(ord(c) + (ord('a')-ord('A'))); // toLower()
        h := h +{%} Ord(c);
        h := h +{%} h shl 10;
        h := h xor (h shr 6)
      end;
      '_': begin end;
      else break
    end;
    Inc(pos)
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  tok.ident := getIdent(addr(L.buf[L.bufpos]), pos-L.bufpos, h);
  L.bufpos := pos;
  if (tok.ident.id < ord(tokKeywordLow)-ord(tkSymbol)) or
     (tok.ident.id > ord(tokKeywordHigh)-ord(tkSymbol)) then
    tok.tokType := tkSymbol
  else
    tok.tokType := TTokType(tok.ident.id+ord(tkSymbol))
end;

procedure getOperator(var L: TLexer; var tok: TToken);
var
  pos: int;
  c: Char;
  buf: pchar;
  h: THash; // hashing algorithm inlined
begin
  pos := L.bufpos;
  buf := L.buf;
  h := 0;
  while true do begin
    c := buf[pos];
    if c in OpChars then begin
      h := h +{%} Ord(c);
      h := h +{%} h shl 10;
      h := h xor (h shr 6)
    end
    else break;
    Inc(pos)
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  tok.ident := getIdent(addr(L.buf[L.bufpos]), pos-L.bufpos, h);
  if (tok.ident.id < oprLow) or (tok.ident.id > oprHigh) then
    tok.tokType := tkOpr
  else
    tok.tokType := TTokType(tok.ident.id - oprLow + ord(tkColon));
  L.bufpos := pos
end;
{@ignore}
{$ifdef Q_on} {$undef Q_on} {$Q+} {$endif}
{$ifdef R_on} {$undef R_on} {$R+} {$endif}
{@emit}

procedure handleIndentation(var L: TLexer; var tok: TToken; indent: int);
var
  i: int;
begin
  tok.indent := indent;
  i := high(L.indentStack);
  if indent > L.indentStack[i] then
    tok.tokType := tkInd
  else if indent = L.indentStack[i] then
    tok.tokType := tkSad
  else begin
    // check we have the indentation somewhere in the stack:
    while (i >= 0) and (indent <> L.indentStack[i]) do begin
      dec(i);
      inc(L.dedent);
    end;
    dec(L.dedent);
    tok.tokType := tkDed;
    if i >= 0 then
      setLength(L.indentStack, i+1) // pop indentations
    else begin
      tok.tokType := tkSad; // for the parser it is better as SAD
      lexMessage(L, errInvalidIndentation);
    end
  end;
end;

procedure scanComment(var L: TLexer; var tok: TToken);
var
  buf: PChar;
  pos, col: int;
  indent: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  // a comment ends if the next line does not start with the # on the same
  // column after only whitespace
  tok.tokType := tkComment;
  col := getColNumber(L, pos);
  while true do begin
    while not (buf[pos] in [CR, LF, lexbase.EndOfFile]) do begin
      addChar(tok.literal, buf[pos]); inc(pos);
    end;
    pos := handleCRLF(L, pos);
    indent := 0;
    while buf[pos] = ' ' do begin inc(pos); inc(indent) end;
    if (buf[pos] = '#') and (col = indent) then begin
      tok.literal := tok.literal +{&} nl;
    end
    else begin
      if buf[pos] > ' ' then begin
        L.indentAhead := indent;
        inc(L.dedent)
      end;
      break
    end
  end;
  L.bufpos := pos;
end;

procedure skip(var L: TLexer; var tok: TToken);
var
  buf: PChar;
  indent, pos: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  repeat
    case buf[pos] of
      ' ': Inc(pos);
      Tabulator: begin
        lexMessagePos(L, errTabulatorsAreNotAllowed, pos);
        inc(pos); // BUGFIX
      end;
      // newline is special:
      CR, LF: begin
        pos := HandleCRLF(L, pos);
        indent := 0;
        while buf[pos] = ' ' do begin
          Inc(pos); Inc(indent)
        end;
        if (buf[pos] > ' ') then begin
          handleIndentation(L, tok, indent);
          break;
        end
      end;
      else break // EndOfFile also leaves the loop
    end
  until false;
  L.bufpos := pos;
end;

procedure rawGetTok(var L: TLexer; var tok: TToken);
var
  c: Char;
begin
  fillToken(tok);
  if L.dedent > 0 then begin
    dec(L.dedent);
    if L.indentAhead >= 0 then begin
      handleIndentation(L, tok, L.indentAhead);
      L.indentAhead := -1;
    end
    else
      tok.tokType := tkDed;
    exit;
  end;
  // Skip whitespace, comments:
  skip(L, tok); // skip
  // got an documentation comment or tkIndent, return that:
  if tok.toktype <> tkInvalid then exit;

  // to the parser
  c := L.buf[L.bufpos];
  if c in SymStartChars - ['r', 'R', 'l'] then // common case first
    getSymbol(L, tok)
  else if c in ['0'..'9'] then
    tok := getNumber(L)
  else begin
    case c of
      '#': scanComment(L, tok);
      ':': begin
        tok.tokType := tkColon;
        inc(L.bufpos);
      end;
      ',': begin
        tok.toktype := tkComma;
        Inc(L.bufpos)
      end;
      'l': begin
        // if we parsed exactly one character and its a small L (l), this
        // is treated as a warning because it may be confused with the number 1
        if not (L.buf[L.bufpos+1] in (SymChars+['_'])) then
          lexMessage(L, warnSmallLshouldNotBeUsed);
        getSymbol(L, tok);
      end;
      'r', 'R': begin
        if L.buf[L.bufPos+1] = '"' then begin
          Inc(L.bufPos);
          getString(L, tok, true);
        end
        else getSymbol(L, tok);
      end;
      '(': begin
        Inc(L.bufpos);
        if (L.buf[L.bufPos] = '.')
        and (L.buf[L.bufPos+1] <> '.') then begin
          tok.toktype := tkParDotLe;
          Inc(L.bufpos);
        end
        else
          tok.toktype := tkParLe;
      end;
      ')': begin
        tok.toktype := tkParRi;
        Inc(L.bufpos)
      end;
      '[': begin
        Inc(L.bufpos);
        if (L.buf[L.bufPos] = '.')
        and (L.buf[L.bufPos+1] <> '.') then begin
          tok.toktype := tkBracketDotLe;
          Inc(L.bufpos);
        end
        else
          tok.toktype := tkBracketLe;
      end;
      ']': begin
        tok.toktype := tkBracketRi;
        Inc(L.bufpos)
      end;
      '.': begin
        if L.buf[L.bufPos+1] = ']' then begin
          tok.tokType := tkBracketDotRi;
          Inc(L.bufpos, 2);
        end
        else if L.buf[L.bufPos+1] = '}' then begin
          tok.tokType := tkCurlyDotRi;
          Inc(L.bufpos, 2);
        end
        else if L.buf[L.bufPos+1] = ')' then begin
          tok.tokType := tkParDotRi;
          Inc(L.bufpos, 2);
        end
        else
          getOperator(L, tok)
      end;
      '{': begin
        Inc(L.bufpos);
        if (L.buf[L.bufPos] = '.')
        and (L.buf[L.bufPos+1] <> '.') then begin
          tok.toktype := tkCurlyDotLe;
          Inc(L.bufpos);
        end
        else
          tok.toktype := tkCurlyLe;
      end;
      '}': begin
        tok.toktype := tkCurlyRi;
        Inc(L.bufpos)
      end;
      ';': begin
        tok.toktype := tkSemiColon;
        Inc(L.bufpos)
      end;
      '`': begin
        tok.tokType := tkAccent;
        Inc(L.bufpos);
      end;
      '"': getString(L, tok, false);
      '''': begin
        getCharacter(L, tok);
        tok.tokType := tkCharLit;
      end;
      lexbase.EndOfFile: tok.toktype := tkEof;
      else if c in OpChars then
        getOperator(L, tok)
      else begin
        tok.literal := c + '';
        tok.tokType := tkInvalid;
        lexMessage(L, errInvalidToken, c +{&} ' (\' +{&} toString(ord(c)) + ')');
        Inc(L.bufpos);
      end
    end
  end
end;

initialization
  dummyIdent := getIdent('');
end.
