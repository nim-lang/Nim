//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit highlite;

// Source highlighter for programming or markup languages.
// Currently only few languages are supported, other languages may be added.
// The interface supports one language nested in another.

interface

{$include 'config.inc'}

uses
  charsets, nsystem, sysutils, nhashes, options, msgs, strutils, platform,
  idents, lexbase, wordrecg, scanner;

type
  TTokenClass = (
    gtEof,
    gtNone,
    gtWhitespace,
    gtDecNumber,
    gtBinNumber,
    gtHexNumber,
    gtOctNumber,
    gtFloatNumber,
    gtIdentifier,
    gtKeyword,
    gtStringLit,
    gtLongStringLit,
    gtCharLit,
    gtEscapeSequence,         // escape sequence like \xff
    gtOperator,
    gtPunctation,
    gtComment,
    gtLongComment,
    gtRegularExpression,
    gtTagStart,
    gtTagEnd,
    gtKey,
    gtValue,
    gtRawData,
    gtAssembler,
    gtPreprocessor,
    gtDirective,
    gtCommand,
    gtRule,
    gtHyperlink,
    gtLabel,
    gtReference,
    gtOther
  );
  TGeneralTokenizer = object(NObject)
    kind: TTokenClass;
    start, len: int;
    // private:
    buf: PChar;
    pos: int;
    state: TTokenClass;
  end;
  TSourceLanguage = (
    langNone,
    langNimrod,
    langCpp,
    langCsharp,
    langC,
    langJava
  );
const
  sourceLanguageToStr: array [TSourceLanguage] of string = (
    'none', 'Nimrod', 'C++', 'C#', 'C'+'', 'Java'
  );
  tokenClassToStr: array [TTokenClass] of string = (
    'Eof',
    'None',
    'Whitespace',
    'DecNumber',
    'BinNumber',
    'HexNumber',
    'OctNumber',
    'FloatNumber',
    'Identifier',
    'Keyword',
    'StringLit',
    'LongStringLit',
    'CharLit',
    'EscapeSequence',
    'Operator',
    'Punctation',
    'Comment',
    'LongComment',
    'RegularExpression',
    'TagStart',
    'TagEnd',
    'Key',
    'Value',
    'RawData',
    'Assembler',
    'Preprocessor',
    'Directive',
    'Command',
    'Rule',
    'Hyperlink',
    'Label',
    'Reference',
    'Other'
  );

function getSourceLanguage(const name: string): TSourceLanguage;

procedure initGeneralTokenizer(var g: TGeneralTokenizer;
                               const buf: string);
procedure deinitGeneralTokenizer(var g: TGeneralTokenizer);
procedure getNextToken(var g: TGeneralTokenizer; lang: TSourceLanguage);

implementation

function getSourceLanguage(const name: string): TSourceLanguage;
var
  i: TSourceLanguage;
begin
  for i := succ(low(TSourceLanguage)) to high(TSourceLanguage) do
    if cmpIgnoreStyle(name, sourceLanguageToStr[i]) = 0 then begin
      result := i; exit
    end;
  result := langNone
end;

procedure initGeneralTokenizer(var g: TGeneralTokenizer;
                               const buf: string);
var
  pos: int;
begin
{@ignore} fillChar(g, sizeof(g), 0); {@emit}
  g.buf := PChar(buf);
  g.kind := low(TTokenClass);
  g.start := 0;
  g.len := 0;
  g.state := low(TTokenClass);
  pos := 0;
  // skip initial whitespace:
  while g.buf[pos] in [' ', #9..#13] do inc(pos);
  g.pos := pos;
end;

procedure deinitGeneralTokenizer(var g: TGeneralTokenizer);
begin
end;

function nimGetKeyword(const id: string): TTokenClass;
var
  i: PIdent;
begin
  i := getIdent(id);
  if (i.id >= ord(tokKeywordLow)-ord(tkSymbol)) and
     (i.id <= ord(tokKeywordHigh)-ord(tkSymbol)) then
    result := gtKeyword
  else
    result := gtIdentifier
end;

function nimNumberPostfix(var g: TGeneralTokenizer; position: int): int;
var
  pos: int;
begin
  pos := position;
  if g.buf[pos] = '''' then begin
    inc(pos);
    case g.buf[pos] of
      'f', 'F': begin
        g.kind := gtFloatNumber;
        inc(pos);
        if g.buf[pos] in ['0'..'9'] then inc(pos);
        if g.buf[pos] in ['0'..'9'] then inc(pos);
      end;
      'i', 'I': begin
        inc(pos);
        if g.buf[pos] in ['0'..'9'] then inc(pos);
        if g.buf[pos] in ['0'..'9'] then inc(pos);
      end;
      else begin end
    end
  end;
  result := pos;
end;

function nimNumber(var g: TGeneralTokenizer; position: int): int;
const
  decChars = ['0'..'9', '_'];
var
  pos: int;
begin
  pos := position;
  g.kind := gtDecNumber;
  while g.buf[pos] in decChars do inc(pos);
  if g.buf[pos] = '.' then begin
    g.kind := gtFloatNumber;
    inc(pos);
    while g.buf[pos] in decChars do inc(pos);
  end;
  if g.buf[pos] in ['e', 'E'] then begin
    g.kind := gtFloatNumber;
    inc(pos);
    if g.buf[pos] in ['+', '-'] then inc(pos);
    while g.buf[pos] in decChars do inc(pos);
  end;
  result := nimNumberPostfix(g, pos);
end;

procedure nimNextToken(var g: TGeneralTokenizer);
const
  hexChars = ['0'..'9', 'A'..'F', 'a'..'f', '_'];
  octChars = ['0'..'7', '_'];
  binChars = ['0'..'1', '_'];
var
  pos: int;
  id: string;
begin
  pos := g.pos;
  g.start := g.pos;
  if g.state = gtStringLit then begin
    g.kind := gtStringLit;
    while true do begin
      case g.buf[pos] of
        '\': begin
          g.kind := gtEscapeSequence;
          inc(pos);
          case g.buf[pos] of
            'x', 'X': begin
              inc(pos);
              if g.buf[pos] in hexChars then inc(pos);
              if g.buf[pos] in hexChars then inc(pos);
            end;
            '0'..'9': while g.buf[pos] in ['0'..'9'] do inc(pos);
            #0: g.state := gtNone;
            else inc(pos);
          end;
          break
        end;
        #0, #13, #10: begin g.state := gtNone; break end;
        '"': begin
          inc(pos);
          g.state := gtNone;
          break
        end;
        else inc(pos)
      end
    end
  end
  else begin
    case g.buf[pos] of
      ' ', #9..#13: begin
        g.kind := gtWhitespace;
        while g.buf[pos] in [' ', #9..#13] do inc(pos);
      end;
      '#': begin
        g.kind := gtComment;
        while not (g.buf[pos] in [#0, #10, #13]) do inc(pos);
      end;
      'a'..'z', 'A'..'Z', '_', #128..#255: begin
        id := '';
        while g.buf[pos] in scanner.SymChars+['_'] do begin
          addChar(id, g.buf[pos]);
          inc(pos)
        end;
        if (g.buf[pos] = '"') then begin
          if (g.buf[pos+1] = '"') and (g.buf[pos+2] = '"') then begin
            inc(pos, 3);
            g.kind := gtLongStringLit;
            while true do begin
              case g.buf[pos] of
                #0: break;
                '"': begin
                  inc(pos);
                  if (g.buf[pos] = '"') and (g.buf[pos+1] = '"') then begin
                    inc(pos, 2);
                    break
                  end
                end;
                else inc(pos);
              end
            end
          end
          else begin
            g.kind := gtRawData;
            inc(pos);
            while not (g.buf[pos] in [#0, '"', #10, #13]) do inc(pos);
            if g.buf[pos] = '"' then inc(pos);
          end
        end
        else begin
          g.kind := nimGetKeyword(id);
        end
      end;
      '0': begin
        inc(pos);
        case g.buf[pos] of
          'b', 'B': begin
            inc(pos);
            while g.buf[pos] in binChars do inc(pos);
            pos := nimNumberPostfix(g, pos);
          end;
          'x', 'X': begin
            inc(pos);
            while g.buf[pos] in hexChars do inc(pos);
            pos := nimNumberPostfix(g, pos);
          end;
          'o', 'O': begin
            inc(pos);
            while g.buf[pos] in octChars do inc(pos);
            pos := nimNumberPostfix(g, pos);
          end;
          else
            pos := nimNumber(g, pos);
        end
      end;
      '1'..'9': begin
        pos := nimNumber(g, pos);
      end;
      '''': begin
        inc(pos);
        g.kind := gtCharLit;
        while true do begin
          case g.buf[pos] of
            #0, #13, #10: break;
            '''': begin inc(pos); break end;
            '\': begin inc(pos, 2); end;
            else inc(pos);
          end
        end
      end;
      '"': begin
        inc(pos);
        if (g.buf[pos] = '"') and (g.buf[pos+1] = '"') then begin
          inc(pos, 2);
          g.kind := gtLongStringLit;
          while true do begin
            case g.buf[pos] of
              #0: break;
              '"': begin
                inc(pos);
                if (g.buf[pos] = '"') and (g.buf[pos+1] = '"') then begin
                  inc(pos, 2);
                  break
                end
              end;
              else inc(pos);
            end
          end
        end
        else begin
          g.kind := gtStringLit;
          while true do begin
            case g.buf[pos] of
              #0, #13, #10: break;
              '"': begin inc(pos); break end;
              '\': begin g.state := g.kind; break end;
              else inc(pos);
            end
          end
        end
      end;
      '(', ')', '[', ']', '{', '}', '`', ':', ',', ';': begin
        inc(pos);
        g.kind := gtPunctation
      end;
      #0: g.kind := gtEof;
      else if g.buf[pos] in scanner.OpChars then begin
        g.kind := gtOperator;
        while g.buf[pos] in scanner.OpChars do inc(pos);
      end
      else begin
        inc(pos);
        g.kind := gtNone
      end;
    end
  end;
  g.len := pos - g.pos;
  if (g.kind <> gtEof) and (g.len <= 0) then 
    InternalError('nimNextToken: ' + toString(g.buf));
  g.pos := pos;
end;

// ------------------------------- helpers ------------------------------------

function generalNumber(var g: TGeneralTokenizer; position: int): int;
const
  decChars = ['0'..'9'];
var
  pos: int;
begin
  pos := position;
  g.kind := gtDecNumber;
  while g.buf[pos] in decChars do inc(pos);
  if g.buf[pos] = '.' then begin
    g.kind := gtFloatNumber;
    inc(pos);
    while g.buf[pos] in decChars do inc(pos);
  end;
  if g.buf[pos] in ['e', 'E'] then begin
    g.kind := gtFloatNumber;
    inc(pos);
    if g.buf[pos] in ['+', '-'] then inc(pos);
    while g.buf[pos] in decChars do inc(pos);
  end;
  result := pos;
end;

function generalStrLit(var g: TGeneralTokenizer; position: int): int;
const
  decChars = ['0'..'9'];
  hexChars = ['0'..'9', 'A'..'F', 'a'..'f'];
var
  pos: int;
  c: Char;
begin
  pos := position;
  g.kind := gtStringLit;
  c := g.buf[pos];
  inc(pos); // skip " or '
  while true do begin
    case g.buf[pos] of
      #0: break;
      '\': begin
        inc(pos);
        case g.buf[pos] of
          #0: break;
          '0'..'9': while g.buf[pos] in decChars do inc(pos);
          'x', 'X': begin
            inc(pos);
            if g.buf[pos] in hexChars then inc(pos);
            if g.buf[pos] in hexChars then inc(pos);
          end;
          else inc(pos, 2)
        end
      end;
      else if g.buf[pos] = c then begin
        inc(pos); break;
      end
      else
        inc(pos);
    end
  end;
  result := pos;
end;

function isKeyword(const x: array of string; const y: string): int;
var
  a, b, mid, c: int;
begin
  a := 0;
  b := length(x)-1;
  while a <= b do begin
    mid := (a + b) div 2;
    c := cmp(x[mid], y);
    if c < 0 then
      a := mid + 1
    else if c > 0 then
      b := mid - 1
    else begin
      result := mid;
      exit
    end
  end;
  result := -1
end;

function isKeywordIgnoreCase(const x: array of string; const y: string): int;
var
  a, b, mid, c: int;
begin
  a := 0;
  b := length(x)-1;
  while a <= b do begin
    mid := (a + b) div 2;
    c := cmpIgnoreCase(x[mid], y);
    if c < 0 then
      a := mid + 1
    else if c > 0 then
      b := mid - 1
    else begin
      result := mid;
      exit
    end
  end;
  result := -1
end;

// ---------------------------------------------------------------------------

type
  TTokenizerFlag = (hasPreprocessor, hasNestedComments);
  TTokenizerFlags = set of TTokenizerFlag;

procedure clikeNextToken(var g: TGeneralTokenizer;
                         const keywords: array of string;
                         flags: TTokenizerFlags);
const
  hexChars = ['0'..'9', 'A'..'F', 'a'..'f'];
  octChars = ['0'..'7'];
  binChars = ['0'..'1'];
  symChars = ['A'..'Z', 'a'..'z', '0'..'9', '_', #128..#255];
var
  pos, nested: int;
  id: string;
begin
  pos := g.pos;
  g.start := g.pos;
  if g.state = gtStringLit then begin
    g.kind := gtStringLit;
    while true do begin
      case g.buf[pos] of
        '\': begin
          g.kind := gtEscapeSequence;
          inc(pos);
          case g.buf[pos] of
            'x', 'X': begin
              inc(pos);
              if g.buf[pos] in hexChars then inc(pos);
              if g.buf[pos] in hexChars then inc(pos);
            end;
            '0'..'9': while g.buf[pos] in ['0'..'9'] do inc(pos);
            #0: g.state := gtNone;
            else inc(pos);
          end;
          break
        end;
        #0, #13, #10: begin g.state := gtNone; break end;
        '"': begin
          inc(pos);
          g.state := gtNone;
          break
        end;
        else inc(pos)
      end
    end
  end
  else begin
    case g.buf[pos] of
      ' ', #9..#13: begin
        g.kind := gtWhitespace;
        while g.buf[pos] in [' ', #9..#13] do inc(pos);
      end;
      '/': begin
        inc(pos);
        if g.buf[pos] = '/' then begin
          g.kind := gtComment;
          while not (g.buf[pos] in [#0, #10, #13]) do inc(pos);
        end
        else if g.buf[pos] = '*' then begin
          g.kind := gtLongComment;
          nested := 0;
          inc(pos);
          while true do begin
            case g.buf[pos] of
              '*': begin
                inc(pos);
                if g.buf[pos] = '/' then begin
                  inc(pos);
                  if nested = 0 then break
                end;
              end;
              '/': begin
                inc(pos);
                if g.buf[pos] = '*' then begin
                  inc(pos);
                  if hasNestedComments in flags then inc(nested);
                end
              end;
              #0: break;
              else inc(pos);
            end
          end
        end
      end;
      '#': begin
        inc(pos);
        if hasPreprocessor in flags then begin
          g.kind := gtPreprocessor;
          while g.buf[pos] in [' ', Tabulator] do inc(pos);
          while g.buf[pos] in symChars do inc(pos);
        end
        else
          g.kind := gtOperator
      end;
      'a'..'z', 'A'..'Z', '_', #128..#255: begin
        id := '';
        while g.buf[pos] in SymChars do begin
          addChar(id, g.buf[pos]);
          inc(pos)
        end;
        if isKeyword(keywords, id) >= 0 then g.kind := gtKeyword
        else g.kind := gtIdentifier;
      end;
      '0': begin
        inc(pos);
        case g.buf[pos] of
          'b', 'B': begin
            inc(pos);
            while g.buf[pos] in binChars do inc(pos);
            if g.buf[pos] in ['A'..'Z', 'a'..'z'] then inc(pos);
          end;
          'x', 'X': begin
            inc(pos);
            while g.buf[pos] in hexChars do inc(pos);
            if g.buf[pos] in ['A'..'Z', 'a'..'z'] then inc(pos);
          end;
          '0'..'7': begin
            inc(pos);
            while g.buf[pos] in octChars do inc(pos);
            if g.buf[pos] in ['A'..'Z', 'a'..'z'] then inc(pos);
          end;
          else begin
            pos := generalNumber(g, pos);
            if g.buf[pos] in ['A'..'Z', 'a'..'z'] then inc(pos);
          end
        end
      end;
      '1'..'9': begin
        pos := generalNumber(g, pos);
        if g.buf[pos] in ['A'..'Z', 'a'..'z'] then inc(pos);
      end;
      '''': begin
        pos := generalStrLit(g, pos);
        g.kind := gtCharLit;
      end;
      '"': begin
        inc(pos);
        g.kind := gtStringLit;
        while true do begin
          case g.buf[pos] of
            #0: break;
            '"': begin inc(pos); break end;
            '\': begin g.state := g.kind; break end;
            else inc(pos);
          end
        end
      end;
      '(', ')', '[', ']', '{', '}', ':', ',', ';', '.': begin
        inc(pos);
        g.kind := gtPunctation
      end;
      #0: g.kind := gtEof;
      else if g.buf[pos] in scanner.OpChars then begin
        g.kind := gtOperator;
        while g.buf[pos] in scanner.OpChars do inc(pos);
      end
      else begin
        inc(pos);
        g.kind := gtNone
      end;
    end
  end;
  g.len := pos - g.pos;
  if (g.kind <> gtEof) and (g.len <= 0) then InternalError('clikeNextToken');
  g.pos := pos;
end;

// --------------------------------------------------------------------------

procedure cNextToken(var g: TGeneralTokenizer);
const
  keywords: array [0..36] of string = (
    '_Bool', '_Complex', '_Imaginary',
    'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
    'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if',
    'inline', 'int', 'long', 'register', 'restrict', 'return', 'short',
    'signed', 'sizeof', 'static', 'struct', 'switch', 'typedef', 'union',
    'unsigned', 'void', 'volatile', 'while'
  );
begin
  clikeNextToken(g, keywords, {@set}[hasPreprocessor]);
end;

procedure cppNextToken(var g: TGeneralTokenizer);
const
  keywords: array [0..47] of string = (
    'asm', 'auto', 'break', 'case', 'catch', 'char', 'class', 'const',
    'continue', 'default', 'delete', 'do', 'double', 'else', 'enum', 'extern',
    'float', 'for', 'friend', 'goto', 'if', 'inline', 'int', 'long', 'new',
    'operator', 'private', 'protected', 'public', 'register', 'return',
    'short', 'signed', 'sizeof', 'static', 'struct', 'switch', 'template',
    'this', 'throw', 'try', 'typedef', 'union', 'unsigned', 'virtual', 'void',
    'volatile', 'while'
  );
begin
  clikeNextToken(g, keywords, {@set}[hasPreprocessor]);
end;

procedure csharpNextToken(var g: TGeneralTokenizer);
const
  keywords: array [0..76] of string = (
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch',
    'char', 'checked', 'class', 'const', 'continue', 'decimal', 'default',
    'delegate', 'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern',
    'false', 'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if',
    'implicit', 'in', 'int', 'interface', 'internal', 'is', 'lock', 'long',
    'namespace', 'new', 'null', 'object', 'operator', 'out', 'override',
    'params', 'private', 'protected', 'public', 'readonly', 'ref', 'return',
    'sbyte', 'sealed', 'short', 'sizeof', 'stackalloc', 'static', 'string',
    'struct', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'uint',
    'ulong', 'unchecked', 'unsafe', 'ushort', 'using', 'virtual', 'void',
    'volatile', 'while'
  );
begin
  clikeNextToken(g, keywords, {@set}[hasPreprocessor]);
end;

procedure javaNextToken(var g: TGeneralTokenizer);
const
  keywords: array [0..52] of string = (
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
    'char', 'class', 'const', 'continue', 'default', 'do', 'double', 'else',
    'enum', 'extends', 'false', 'final', 'finally', 'float', 'for', 'goto',
    'if', 'implements', 'import', 'instanceof', 'int', 'interface', 'long',
    'native', 'new', 'null', 'package', 'private', 'protected', 'public',
    'return', 'short', 'static', 'strictfp', 'super', 'switch',
    'synchronized', 'this', 'throw', 'throws', 'transient', 'true', 'try',
    'void', 'volatile', 'while'
  );
begin
  clikeNextToken(g, keywords, {@set}[]);
end;

procedure getNextToken(var g: TGeneralTokenizer; lang: TSourceLanguage);
begin
  case lang of
    langNimrod: nimNextToken(g);
    langCpp: cppNextToken(g);
    langCsharp: csharpNextToken(g);
    langC: cNextToken(g);
    langJava: javaNextToken(g);
    else InternalError('getNextToken');
  end
end;

end.
