//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit paslex;

// This module implements a FreePascal scanner. This is a adaption from
// the scanner module.

interface

{$include 'config.inc'}

uses
  charsets, nsystem, sysutils,
  hashes, options, msgs, strutils, platform, idents,
  lexbase, wordrecg, scanner;

const
  MaxLineLength = 80; // lines longer than this lead to a warning

  numChars: TCharSet = ['0'..'9','a'..'z','A'..'Z']; // we support up to base 36
  SymChars: TCharSet = ['a'..'z', 'A'..'Z', '0'..'9', #128..#255];
  SymStartChars: TCharSet = ['a'..'z', 'A'..'Z', #128..#255];
  OpChars: TCharSet = ['+', '-', '*', '/', '<', '>', '!', '?', '^', '.',
    '|', '=', ':', '%', '&', '$', '@', '~', #128..#255];

type
  // order is important for TPasTokKind
  TPasTokKind = (pxInvalid, pxEof,
    // keywords:
    //[[[cog
    //from string import capitalize
    //keywords = eval(open("data/pas_keyw.yml").read())
    //idents = ""
    //strings = ""
    //i = 1
    //for k in keywords:
    //  idents = idents + "px" + capitalize(k) + ", "
    //  strings = strings + "'" + k + "', "
    //  if i % 4 == 0:
    //    idents = idents + "\n"
    //    strings = strings + "\n"
    //  i = i + 1
    //cog.out(idents)
    //]]]
    pxAnd, pxArray, pxAs, pxAsm, 
    pxBegin, pxCase, pxClass, pxConst, 
    pxConstructor, pxDestructor, pxDiv, pxDo, 
    pxDownto, pxElse, pxEnd, pxExcept, 
    pxExports, pxFinalization, pxFinally, pxFor, 
    pxFunction, pxGoto, pxIf, pxImplementation, 
    pxIn, pxInherited, pxInitialization, pxInline, 
    pxInterface, pxIs, pxLabel, pxLibrary, 
    pxMod, pxNil, pxNot, pxObject, 
    pxOf, pxOr, pxOut, pxPacked, 
    pxProcedure, pxProgram, pxProperty, pxRaise, 
    pxRecord, pxRepeat, pxResourcestring, pxSet, 
    pxShl, pxShr, pxThen, pxThreadvar, 
    pxTo, pxTry, pxType, pxUnit, 
    pxUntil, pxUses, pxVar, pxWhile, 
    pxWith, pxXor, 
    //[[[end]]]
    pxComment,   // ordinary comment
    pxCommand,   // {@}
    pxAmp,       // {&}
    pxPer,       // {%}
    pxStrLit,
    pxSymbol,    // a symbol

    pxIntLit,
    pxInt64Lit,  // long constant like 0x00000070fffffff or out of int range
    pxFloatLit,

    pxParLe, pxParRi, pxBracketLe, pxBracketRi,
    pxComma, pxSemiColon, pxColon,

    // operators
    pxAsgn,
    pxEquals, pxDot, pxDotDot, pxHat, pxPlus, pxMinus, pxStar, pxSlash,
    pxLe, pxLt, pxGe, pxGt, pxNeq, pxAt,

    pxStarDirLe,
    pxStarDirRi,
    pxCurlyDirLe,
    pxCurlyDirRi
  );
  TPasTokKinds = set of TPasTokKind;
const
  PasTokKindToStr: array [TPasTokKind] of string = (
    'pxInvalid', '[EOF]',
    //[[[cog
    //cog.out(strings)
    //]]]
    'and', 'array', 'as', 'asm', 
    'begin', 'case', 'class', 'const', 
    'constructor', 'destructor', 'div', 'do', 
    'downto', 'else', 'end', 'except', 
    'exports', 'finalization', 'finally', 'for', 
    'function', 'goto', 'if', 'implementation', 
    'in', 'inherited', 'initialization', 'inline', 
    'interface', 'is', 'label', 'library', 
    'mod', 'nil', 'not', 'object', 
    'of', 'or', 'out', 'packed', 
    'procedure', 'program', 'property', 'raise', 
    'record', 'repeat', 'resourcestring', 'set', 
    'shl', 'shr', 'then', 'threadvar', 
    'to', 'try', 'type', 'unit', 
    'until', 'uses', 'var', 'while', 
    'with', 'xor', 
    //[[[end]]]
    'pxComment', 'pxCommand',
    '{&}', '{%}', 'pxStrLit', '[IDENTIFIER]', 'pxIntLit', 'pxInt64Lit',
    'pxFloatLit',
    '('+'', ')'+'', '['+'', ']'+'',
    ','+'', ';'+'', ':'+'',
    ':=', '='+'', '.'+'', '..', '^'+'', '+'+'', '-'+'', '*'+'', '/'+'',
    '<=', '<'+'', '>=', '>'+'', '<>', '@'+'', '(*$', '*)', '{$', '}'+''
  );

type
  TPasTok = object(TToken)         // a Pascal token
    xkind: TPasTokKind;            // the type of the token
  end;

  TPasLex = object(TLexer)
  end;

procedure getPasTok(var L: TPasLex; out tok: TPasTok);

procedure PrintPasTok(const tok: TPasTok);
function pasTokToStr(const tok: TPasTok): string;

implementation

function pastokToStr(const tok: TPasTok): string;
begin
  case tok.xkind of
    pxIntLit, pxInt64Lit:
      result := toString(tok.iNumber);
    pxFloatLit:
      result := toStringF(tok.fNumber);
    pxInvalid, pxComment..pxStrLit:
      result := tok.literal;
    else if (tok.ident.s <> '') then
      result := tok.ident.s
    else
      result := pasTokKindToStr[tok.xkind];
  end
end;

procedure PrintPasTok(const tok: TPasTok);
begin
  write(output, pasTokKindToStr[tok.xkind]);
  write(output, ' ');
  writeln(output, pastokToStr(tok))
end;

// ----------------------------------------------------------------------------

procedure setKeyword(var L: TPasLex; var tok: TPasTok);
begin
  case tok.ident.id of
    //[[[cog
    //for k in keywords:
    //  m = capitalize(k)
    //  cog.outl("ord(w%s):%s tok.xkind := px%s;" % (m, ' '*(18-len(m)), m))
    //]]]
    ord(wAnd):                tok.xkind := pxAnd;
    ord(wArray):              tok.xkind := pxArray;
    ord(wAs):                 tok.xkind := pxAs;
    ord(wAsm):                tok.xkind := pxAsm;
    ord(wBegin):              tok.xkind := pxBegin;
    ord(wCase):               tok.xkind := pxCase;
    ord(wClass):              tok.xkind := pxClass;
    ord(wConst):              tok.xkind := pxConst;
    ord(wConstructor):        tok.xkind := pxConstructor;
    ord(wDestructor):         tok.xkind := pxDestructor;
    ord(wDiv):                tok.xkind := pxDiv;
    ord(wDo):                 tok.xkind := pxDo;
    ord(wDownto):             tok.xkind := pxDownto;
    ord(wElse):               tok.xkind := pxElse;
    ord(wEnd):                tok.xkind := pxEnd;
    ord(wExcept):             tok.xkind := pxExcept;
    ord(wExports):            tok.xkind := pxExports;
    ord(wFinalization):       tok.xkind := pxFinalization;
    ord(wFinally):            tok.xkind := pxFinally;
    ord(wFor):                tok.xkind := pxFor;
    ord(wFunction):           tok.xkind := pxFunction;
    ord(wGoto):               tok.xkind := pxGoto;
    ord(wIf):                 tok.xkind := pxIf;
    ord(wImplementation):     tok.xkind := pxImplementation;
    ord(wIn):                 tok.xkind := pxIn;
    ord(wInherited):          tok.xkind := pxInherited;
    ord(wInitialization):     tok.xkind := pxInitialization;
    ord(wInline):             tok.xkind := pxInline;
    ord(wInterface):          tok.xkind := pxInterface;
    ord(wIs):                 tok.xkind := pxIs;
    ord(wLabel):              tok.xkind := pxLabel;
    ord(wLibrary):            tok.xkind := pxLibrary;
    ord(wMod):                tok.xkind := pxMod;
    ord(wNil):                tok.xkind := pxNil;
    ord(wNot):                tok.xkind := pxNot;
    ord(wObject):             tok.xkind := pxObject;
    ord(wOf):                 tok.xkind := pxOf;
    ord(wOr):                 tok.xkind := pxOr;
    ord(wOut):                tok.xkind := pxOut;
    ord(wPacked):             tok.xkind := pxPacked;
    ord(wProcedure):          tok.xkind := pxProcedure;
    ord(wProgram):            tok.xkind := pxProgram;
    ord(wProperty):           tok.xkind := pxProperty;
    ord(wRaise):              tok.xkind := pxRaise;
    ord(wRecord):             tok.xkind := pxRecord;
    ord(wRepeat):             tok.xkind := pxRepeat;
    ord(wResourcestring):     tok.xkind := pxResourcestring;
    ord(wSet):                tok.xkind := pxSet;
    ord(wShl):                tok.xkind := pxShl;
    ord(wShr):                tok.xkind := pxShr;
    ord(wThen):               tok.xkind := pxThen;
    ord(wThreadvar):          tok.xkind := pxThreadvar;
    ord(wTo):                 tok.xkind := pxTo;
    ord(wTry):                tok.xkind := pxTry;
    ord(wType):               tok.xkind := pxType;
    ord(wUnit):               tok.xkind := pxUnit;
    ord(wUntil):              tok.xkind := pxUntil;
    ord(wUses):               tok.xkind := pxUses;
    ord(wVar):                tok.xkind := pxVar;
    ord(wWhile):              tok.xkind := pxWhile;
    ord(wWith):               tok.xkind := pxWith;
    ord(wXor):                tok.xkind := pxXor;
    //[[[end]]]
    else                      tok.xkind := pxSymbol
  end
end;


// ----------------------------------------------------------------------------

procedure matchUnderscoreChars(var L: TPasLex; var tok: TPasTok;
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

procedure getNumber2(var L: TPasLex; var tok: TPasTok);
var
  pos, bits: int;
  xi: biggestInt;
begin
  pos := L.bufpos+1; // skip %
  if not (L.buf[pos] in ['0'..'1']) then begin // BUGFIX for %date%
    tok.xkind := pxInvalid;
    addChar(tok.literal, '%');
    inc(L.bufpos);
    exit;
  end;

  tok.base := base2;
  xi := 0;
  bits := 0;
  while true do begin
    case L.buf[pos] of
      'A'..'Z', 'a'..'z', '2'..'9', '.': begin
        lexMessage(L, errInvalidNumber);
        inc(pos)
      end;
      '_': inc(pos);
      '0', '1': begin
        xi := shlu(xi, 1) or (ord(L.buf[pos]) - ord('0'));
        inc(pos);
        inc(bits);
      end;
      else break;
    end
  end;
  tok.iNumber := xi;
  if (bits > 32) then //or (xi < low(int32)) or (xi > high(int32)) then
    tok.xkind := pxInt64Lit
  else
    tok.xkind := pxIntLit;
  L.bufpos := pos;
end;

procedure getNumber16(var L: TPasLex; var tok: TPasTok);
var
  pos, bits: int;
  xi: biggestInt;
begin
  pos := L.bufpos+1; // skip $
  tok.base := base16;
  xi := 0;
  bits := 0;
  while true do begin
    case L.buf[pos] of
      'G'..'Z', 'g'..'z', '.': begin
        lexMessage(L, errInvalidNumber);
        inc(pos);
      end;
      '_': inc(pos);
      '0'..'9': begin
        xi := shlu(xi, 4) or (ord(L.buf[pos]) - ord('0'));
        inc(pos);
        inc(bits, 4);
      end;
      'a'..'f': begin
        xi := shlu(xi, 4) or (ord(L.buf[pos]) - ord('a') + 10);
        inc(pos);
        inc(bits, 4);
      end;
      'A'..'F': begin
        xi := shlu(xi, 4) or (ord(L.buf[pos]) - ord('A') + 10);
        inc(pos);
        inc(bits, 4);
      end;
      else break;
    end
  end;
  tok.iNumber := xi;
  if (bits > 32) then // (xi < low(int32)) or (xi > high(int32)) then
    tok.xkind := pxInt64Lit
  else
    tok.xkind := pxIntLit;
  L.bufpos := pos;
end;

procedure getNumber10(var L: TPasLex; var tok: TPasTok);
begin
  tok.base := base10;
  matchUnderscoreChars(L, tok, ['0'..'9']);
  if (L.buf[L.bufpos] = '.') and (L.buf[L.bufpos+1] in ['0'..'9']) then begin
    addChar(tok.literal, '.');
    inc(L.bufpos);
    matchUnderscoreChars(L, tok, ['e', 'E', '+', '-', '0'..'9'])
  end;
  try
    if isFloatLiteral(tok.literal) then begin
      tok.fnumber := parseFloat(tok.literal);
      tok.xkind := pxFloatLit;
    end
    else begin
      tok.iNumber := ParseInt(tok.literal);
      if (tok.iNumber < low(int32)) or (tok.iNumber > high(int32)) then
        tok.xkind := pxInt64Lit
      else
        tok.xkind := pxIntLit;
    end;
  except
    on EInvalidValue do
      lexMessage(L, errInvalidNumber, tok.literal);
    on EOverflow do
      lexMessage(L, errNumberOutOfRange, tok.literal);
  {@ignore}
    on sysutils.EIntOverflow do
      lexMessage(L, errNumberOutOfRange, tok.literal);
  {@emit}
  end;
end;

function HandleCRLF(var L: TLexer; pos: int): int;
begin
  case L.buf[pos] of
    CR: result := lexbase.HandleCR(L, pos);
    LF: result := lexbase.HandleLF(L, pos);
    else result := pos
  end
end;

procedure getString(var L: TPasLex; var tok: TPasTok);
var
  pos, xi: int;
  buf: PChar;
begin
  pos := L.bufPos;
  buf := L.buf;
  while true do begin
    if buf[pos] = '''' then begin
      inc(pos);
      while true do begin
        case buf[pos] of
          CR, LF, lexbase.EndOfFile: begin
            lexMessage(L, errClosingQuoteExpected);
            break
          end;
          '''': begin
            inc(pos);
            if buf[pos] = '''' then begin
              inc(pos);
              addChar(tok.literal, '''');
            end
            else break;
          end;
          else begin
            addChar(tok.literal, buf[pos]);
            inc(pos);
          end
        end
      end
    end
    else if buf[pos] = '#' then begin
      inc(pos);
      xi := 0;
      case buf[pos] of
        '$': begin
          inc(pos);
          xi := 0;
          while true do begin
            case buf[pos] of
              '0'..'9': xi := (xi shl 4) or (ord(buf[pos]) - ord('0'));
              'a'..'f': xi := (xi shl 4) or (ord(buf[pos]) - ord('a') + 10);
              'A'..'F': xi := (xi shl 4) or (ord(buf[pos]) - ord('A') + 10);
              else break;
            end;
            inc(pos)
          end
        end;
        '0'..'9': begin
          xi := 0;
          while buf[pos] in ['0'..'9'] do begin
            xi := (xi * 10) + (ord(buf[pos]) - ord('0'));
            inc(pos);
          end;
        end
        else lexMessage(L, errInvalidCharacterConstant)
      end;
      if (xi <= 255) then
        addChar(tok.literal, Chr(xi))
      else
        lexMessage(L, errInvalidCharacterConstant)
    end
    else break
  end;
  tok.xkind := pxStrLit;
  L.bufpos := pos;
end;

{@ignore}
{$ifopt Q+} {$define Q_on} {$Q-} {$endif}
{$ifopt R+} {$define R_on} {$R-} {$endif}
{@emit}
procedure getSymbol(var L: TPasLex; var tok: TPasTok);
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
  setKeyword(L, tok);
end;
{@ignore}
{$ifdef Q_on} {$undef Q_on} {$Q+} {$endif}
{$ifdef R_on} {$undef R_on} {$R+} {$endif}
{@emit}

procedure scanLineComment(var L: TPasLex; var tok: TPasTok);
var
  buf: PChar;
  pos, col: int;
  indent: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  // a comment ends if the next line does not start with the // on the same
  // column after only whitespace
  tok.xkind := pxComment;
  col := getColNumber(L, pos);
  while true do begin
    inc(pos, 2); // skip //
    addChar(tok.literal, '#');
    while not (buf[pos] in [CR, LF, lexbase.EndOfFile]) do begin
      addChar(tok.literal, buf[pos]); inc(pos);
    end;
    pos := handleCRLF(L, pos);
    indent := 0;
    while buf[pos] = ' ' do begin inc(pos); inc(indent) end;
    if (col = indent) and (buf[pos] = '/') and (buf[pos+1] = '/') then
      tok.literal := tok.literal +{&} nl
    else
      break
  end;
  L.bufpos := pos;
end;

procedure scanCurlyComment(var L: TPasLex; var tok: TPasTok);
var
  buf: PChar;
  pos: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  tok.literal := '#'+'';
  tok.xkind := pxComment;
  repeat
    case buf[pos] of
      CR, LF: begin
        pos := HandleCRLF(L, pos);
        tok.literal := tok.literal +{&} nl + '#';
      end;
      '}': begin inc(pos); break end;
      lexbase.EndOfFile: lexMessage(L, errTokenExpected, '}'+'');
      else begin
        addChar(tok.literal, buf[pos]);
        inc(pos)
      end
    end
  until false;
  L.bufpos := pos;
end;

procedure scanStarComment(var L: TPasLex; var tok: TPasTok);
var
  buf: PChar;
  pos: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  tok.literal := '#'+'';
  tok.xkind := pxComment;
  repeat
    case buf[pos] of
      CR, LF: begin
        pos := HandleCRLF(L, pos);
        tok.literal := tok.literal +{&} nl + '#';
      end;
      '*': begin
        inc(pos);
        if buf[pos] = ')' then begin inc(pos); break end
        else addChar(tok.literal, '*')
      end;
      lexbase.EndOfFile: lexMessage(L, errTokenExpected, '*)');
      else begin
        addChar(tok.literal, buf[pos]);
        inc(pos)
      end
    end
  until false;
  L.bufpos := pos;
end;

procedure skip(var L: TPasLex; var tok: TPasTok);
var
  buf: PChar;
  pos: int;
begin
  pos := L.bufpos;
  buf := L.buf;
  repeat
    case buf[pos] of
      ' ', Tabulator: Inc(pos);
      // newline is special:
      CR, LF: pos := HandleCRLF(L, pos);
      else break // EndOfFile also leaves the loop
    end
  until false;
  L.bufpos := pos;
end;

procedure getPasTok(var L: TPasLex; out tok: TPasTok);
var
  c: Char;
begin
  tok.xkind := pxInvalid;
  fillToken(tok);
  skip(L, tok);
  c := L.buf[L.bufpos];
  if c in SymStartChars then // common case first
    getSymbol(L, tok)
  else if c in ['0'..'9'] then
    getNumber10(L, tok)
  else begin
    case c of
      ';': begin tok.xkind := pxSemicolon; Inc(L.bufpos) end;
      '/': begin
        if L.buf[L.bufpos+1] = '/' then scanLineComment(L, tok)
        else begin tok.xkind := pxSlash; inc(L.bufpos) end;
      end;
      ',': begin tok.xkind := pxComma; Inc(L.bufpos) end;
      '(': begin
        Inc(L.bufpos);
        if (L.buf[L.bufPos] = '*') then begin
          if (L.buf[L.bufPos+1] = '$') then begin
            Inc(L.bufpos, 2);
            skip(L, tok);
            getSymbol(L, tok);
            tok.xkind := pxStarDirLe;
          end
          else begin
            inc(L.bufpos);
            scanStarComment(L, tok)
          end
        end
        else
          tok.xkind := pxParLe;
      end;
      '*': begin
        inc(L.bufpos);
        if L.buf[L.bufpos] = ')' then begin
          inc(L.bufpos); tok.xkind := pxStarDirRi
        end
        else tok.xkind := pxStar
      end;
      ')': begin tok.xkind := pxParRi; Inc(L.bufpos) end;
      '[': begin Inc(L.bufpos); tok.xkind := pxBracketLe end;
      ']': begin Inc(L.bufpos); tok.xkind := pxBracketRi end;
      '.': begin
        inc(L.bufpos);
        if L.buf[L.bufpos] = '.' then begin
          tok.xkind := pxDotDot; inc(L.bufpos)
        end
        else tok.xkind := pxDot
      end;
      '{': begin
        Inc(L.bufpos);
        case L.buf[L.bufpos] of
          '$': begin
            Inc(L.bufpos);
            skip(L, tok);
            getSymbol(L, tok);
            tok.xkind := pxCurlyDirLe
          end;
          '&': begin Inc(L.bufpos); tok.xkind := pxAmp end;
          '%': begin Inc(L.bufpos); tok.xkind := pxPer end;
          '@': begin Inc(L.bufpos); tok.xkind := pxCommand end;
          else scanCurlyComment(L, tok);
        end;
      end;
      '+': begin tok.xkind := pxPlus; inc(L.bufpos) end;
      '-': begin tok.xkind := pxMinus; inc(L.bufpos) end;
      ':': begin
        inc(L.bufpos);
        if L.buf[L.bufpos] = '=' then begin
          inc(L.bufpos); tok.xkind := pxAsgn;
        end
        else tok.xkind := pxColon
      end;
      '<': begin
        inc(L.bufpos);
        if L.buf[L.bufpos] = '>' then begin
          inc(L.bufpos);
          tok.xkind := pxNeq
        end
        else if L.buf[L.bufpos] = '=' then begin
          inc(L.bufpos);
          tok.xkind := pxLe
        end
        else tok.xkind := pxLt
      end;
      '>': begin
        inc(L.bufpos);
        if L.buf[L.bufpos] = '=' then begin
          inc(L.bufpos);
          tok.xkind := pxGe
        end
        else tok.xkind := pxGt
      end;
      '=': begin tok.xkind := pxEquals; inc(L.bufpos) end;
      '@': begin tok.xkind := pxAt; inc(L.bufpos) end;
      '^': begin tok.xkind := pxHat; inc(L.bufpos) end;
      '}': begin tok.xkind := pxCurlyDirRi; Inc(L.bufpos) end;
      '''', '#': getString(L, tok);
      '$': getNumber16(L, tok);
      '%': getNumber2(L, tok);
      lexbase.EndOfFile: tok.xkind := pxEof;
      else begin
        tok.literal := c + '';
        tok.xkind := pxInvalid;
        lexMessage(L, errInvalidToken, c + ' (\' +{&} toString(ord(c)) + ')');
        Inc(L.bufpos);
      end
    end
  end
end;

end.
