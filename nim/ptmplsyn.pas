//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ptmplsyn;

// This module implements the parser of the Nimrod Template files.

{$include config.inc}

interface

uses
  nsystem, llstream, nos, charsets, wordrecg, strutils,
  ast, astalgo, msgs, options, pnimsyn;

function ParseTmplFile(const filename: string): PNode;


type
  TParseState = (psDirective, psMultiDir, psTempl);
  TTmplParser = record
    inp: PLLStream;
    state: TParseState;
    info: TLineInfo;
    indent, par: int;
    x: string; // the current input line
    outp: PLLStream; // the ouput will be parsed by pnimsyn
    subsChar: Char;
  end;

function ParseTmpl(var p: TTmplParser): PNode;

procedure openTmplParser(var p: TTmplParser; const filename: string;
                         inputStream: PLLStream);
procedure closeTmplParser(var p: TTmplParser);

implementation

const
  NimDirective = '#';
  PatternChars = ['a'..'z', 'A'..'Z', '0'..'9', #128..#255, '.', '_'];

procedure newLine(var p: TTmplParser);
begin
  LLStreamWrite(p.outp, repeatChar(p.par, ')'));
  p.par := 0;
  if p.info.line > int16(1) then LLStreamWrite(p.outp, nl);
end;

procedure parseLine(var p: TTmplParser);
var
  d, j, curly: int;
  keyw: string;
begin
  j := strStart;
  while p.x[j] = ' ' do inc(j);
  if p.state = psMultiDir then begin
    newLine(p);
    if p.x[j] = '*' then begin
      inc(j);
      if p.x[j] = NimDirective then p.state := psTempl;
      // ignore the rest of the line
    end
    else
      LLStreamWrite(p.outp, p.x); // simply add the whole line
  end
  else if p.x[j] = NimDirective then begin
    newLine(p);
    inc(j);
    while p.x[j] = ' ' do inc(j);
    d := j;
    if p.x[j] = '*' then begin
      inc(j);
      p.state := psMultiDir;
      LLStreamWrite(p.outp, repeatChar(p.indent));
      LLStreamWrite(p.outp, '#*');
      LLStreamWrite(p.outp, ncopy(p.x, j)); // simply add the whole line
    end
    else begin
      keyw := '';
      while p.x[j] in PatternChars do begin
        addChar(keyw, p.x[j]);
        inc(j);
      end;
      case whichKeyword(keyw) of
        wEnd: begin
          if p.indent >= 2 then
            dec(p.indent, 2)
          else begin
            p.info.col := int16(j);
            liMessage(p.info, errXNotAllowedHere, 'end');
          end;
          LLStreamWrite(p.outp, repeatChar(p.indent));
          LLStreamWrite(p.outp, '#end');
        end;
        wSubsChar: begin
          LLStreamWrite(p.outp, repeatChar(p.indent));
          LLStreamWrite(p.outp, '#subschar');
          while p.x[j] = ' ' do inc(j);
          if p.x[j] in ['+', '-', '*', '/', '<', '>', '!', '?', '^', '.',
                 '|', '=', '%', '&', '$', '@', '~'] then p.subsChar := p.x[j]
          else begin
            p.info.col := int16(j);
            liMessage(p.info, errXNotAllowedHere, p.x[j]+'');
          end
        end;
        wIf, wWhen, wTry, wWhile, wFor, wBlock, wCase, wProc, wIterator,
        wConverter, wMacro, wTemplate: begin
          LLStreamWrite(p.outp, repeatChar(p.indent));
          LLStreamWrite(p.outp, ncopy(p.x, d));
          inc(p.indent, 2);
        end;
        wElif, wOf, wElse, wExcept, wFinally: begin
          LLStreamWrite(p.outp, repeatChar(p.indent-2));
          LLStreamWrite(p.outp, ncopy(p.x, d));
        end
        else begin
          LLStreamWrite(p.outp, repeatChar(p.indent));
          LLStreamWrite(p.outp, ncopy(p.x, d));
        end
      end;
      p.state := psDirective;
    end
  end
  else begin
    // data line
    j := strStart;
    case p.state of
      psTempl: begin
        // next line of string literal:
        LLStreamWrite(p.outp, ' &'+nl);
        LLStreamWrite(p.outp, repeatChar(p.indent + 2));
        LLStreamWrite(p.outp, '"'+'');
      end;
      psDirective: begin
        newLine(p);
        LLStreamWrite(p.outp, repeatChar(p.indent));
        LLStreamWrite(p.outp, 'add(result, "');
        inc(p.par);
      end;
      else InternalError(p.info, 'parser in invalid state');
    end;
    p.state := psTempl;
    while true do begin
      case p.x[j] of
        #0: break;
        #1..#31, #128..#255: begin
          LLStreamWrite(p.outp, '\x');
          LLStreamWrite(p.outp, toHex(ord(p.x[j]), 2));
          inc(j);
        end;
        '\': begin LLStreamWrite(p.outp, '\\'); inc(j); end;
        '''': begin LLStreamWrite(p.outp, '\'''); inc(j); end;
        '"': begin LLStreamWrite(p.outp, '\"'); inc(j); end;
        else if p.x[j] = p.subsChar then begin // parse Nimrod expression:
          inc(j);
          case p.x[j] of
            '{': begin
              p.info.col := int16(j);
              LLStreamWrite(p.outp, '" & $(');
              inc(j);
              curly := 0;
              while true do begin
                case p.x[j] of
                  #0: liMessage(p.info, errXExpected, '}'+'');
                  '{': begin
                    inc(j);
                    inc(curly);
                    LLStreamWrite(p.outp, '{'+'');
                  end;
                  '}': begin
                    inc(j);
                    if curly = 0 then break;
                    if curly > 0 then dec(curly);
                    LLStreamWrite(p.outp, '}'+'');
                  end;
                  else begin
                    LLStreamWrite(p.outp, p.x[j]);
                    inc(j)
                  end
                end
              end;
              LLStreamWrite(p.outp, ') & "')
            end;
            'A'..'Z', 'a'..'z', '_': begin
              LLStreamWrite(p.outp, '" & $');
              while p.x[j] in PatternChars do begin
                LLStreamWrite(p.outp, p.x[j]);
                inc(j)
              end;
              LLStreamWrite(p.outp, ' & "')
            end;
            else if p.x[j] = p.subsChar then begin
              LLStreamWrite(p.outp, p.subsChar);
              inc(j);
            end
            else begin
              p.info.col := int16(j);
              liMessage(p.info, errInvalidExpression, '$'+'');
            end
          end;
        end
        else begin
          LLStreamWrite(p.outp, p.x[j]);
          inc(j);
        end
      end
    end;
    LLStreamWrite(p.outp, '\n"');
  end
end;

function ParseTmpl(var p: TTmplParser): PNode;
var
  q: TParser;
begin
  while not LLStreamAtEnd(p.inp) do begin
    p.x := LLStreamReadLine(p.inp) {@ignore} + #0 {@emit};
    p.info.line := p.info.line + int16(1);
    parseLine(p);
  end;
  newLine(p);
  if gVerbosity >= 2 then begin
    rawMessage(hintCodeBegin);
    messageOut(p.outp.s);
    rawMessage(hintCodeEnd);
  end;
  openParser(q, toFilename(p.info), p.outp);
  result := ParseModule(q);
  closeParser(q);
end;

procedure openTmplParser(var p: TTmplParser; const filename: string;
                         inputStream: PLLStream);
begin
{@ignore}
  FillChar(p, sizeof(p), 0);
{@emit}
  p.info := newLineInfo(filename, 0, 0);
  p.outp := LLStreamOpen('');
  p.inp := inputStream;
  p.subsChar := '$';
end;

procedure CloseTmplParser(var p: TTmplParser);
begin
  LLStreamClose(p.inp);
end;

function ParseTmplFile(const filename: string): PNode;
var
  p: TTmplParser;
  f: TBinaryFile;
begin
  if not OpenFile(f, filename) then begin
    rawMessage(errCannotOpenFile, filename);
    result := nil;
    exit
  end;
  OpenTmplParser(p, filename, LLStreamOpen(f));
  result := ParseTmpl(p);
  CloseTmplParser(p);
end;

end.
