//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ptmplsyn;

// This module implements Nimrod's standard template filter.

{$include config.inc}

interface

uses
  nsystem, llstream, nos, charsets, wordrecg, idents, strutils,
  ast, astalgo, msgs, options, rnimsyn, filters;

function filterTmpl(input: PLLStream; const filename: string;
                    call: PNode): PLLStream;
// #! template(subsChar='$', metaChar='#') | standard(version="0.7.2")

implementation

type
  TParseState = (psDirective, psTempl);
  TTmplParser = record
    inp: PLLStream;
    state: TParseState;
    info: TLineInfo;
    indent, par: int;
    x: string; // the current input line
    outp: PLLStream; // the ouput will be parsed by pnimsyn
    subsChar, NimDirective: Char;
    emit, conc, toStr: string;
  end;

const
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
  if (p.x[strStart] = p.NimDirective) and (p.x[strStart+1] = '!') then
    newLine(p)
  else if (p.x[j] = p.NimDirective) then begin
    newLine(p);
    inc(j);
    while p.x[j] = ' ' do inc(j);
    d := j;
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
      wIf, wWhen, wTry, wWhile, wFor, wBlock, wCase, wProc, wIterator,
      wConverter, wMacro, wTemplate, wMethod: begin
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
    p.state := psDirective
  end
  else begin
    // data line
    j := strStart;
    case p.state of
      psTempl: begin
        // next line of string literal:
        LLStreamWrite(p.outp, p.conc);
        LLStreamWrite(p.outp, nl);
        LLStreamWrite(p.outp, repeatChar(p.indent + 2));
        LLStreamWrite(p.outp, '"'+'');
      end;
      psDirective: begin
        newLine(p);
        LLStreamWrite(p.outp, repeatChar(p.indent));
        LLStreamWrite(p.outp, p.emit);
        LLStreamWrite(p.outp, '("');
        inc(p.par);
      end
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
              LLStreamWrite(p.outp, '"');
              LLStreamWrite(p.outp, p.conc);
              LLStreamWrite(p.outp, p.toStr);
              LLStreamWrite(p.outp, '(');
              inc(j);
              curly := 0;
              while true do begin
                case p.x[j] of
                  #0: liMessage(p.info, errXExpected, '}'+'');
                  '{': begin
                    inc(j);
                    inc(curly);
                    LLStreamWrite(p.outp, '{');
                  end;
                  '}': begin
                    inc(j);
                    if curly = 0 then break;
                    if curly > 0 then dec(curly);
                    LLStreamWrite(p.outp, '}');
                  end;
                  else begin
                    LLStreamWrite(p.outp, p.x[j]);
                    inc(j)
                  end
                end
              end;
              LLStreamWrite(p.outp, ')');
              LLStreamWrite(p.outp, p.conc);
              LLStreamWrite(p.outp, '"');
            end;
            'a'..'z', 'A'..'Z', #128..#255: begin
              LLStreamWrite(p.outp, '"');
              LLStreamWrite(p.outp, p.conc);
              LLStreamWrite(p.outp, p.toStr);
              LLStreamWrite(p.outp, '(');
              while p.x[j] in PatternChars do begin
                LLStreamWrite(p.outp, p.x[j]);
                inc(j)
              end;
              LLStreamWrite(p.outp, ')');
              LLStreamWrite(p.outp, p.conc);
              LLStreamWrite(p.outp, '"')
            end;
            else if p.x[j] = p.subsChar then begin
              LLStreamWrite(p.outp, p.subsChar);
              inc(j);
            end
            else begin
              p.info.col := int16(j);
              liMessage(p.info, errInvalidExpression, '$'+'');
            end
          end
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

function filterTmpl(input: PLLStream; const filename: string;
                    call: PNode): PLLStream;
var
  p: TTmplParser; 
begin
{@ignore}
  FillChar(p, sizeof(p), 0);
{@emit}
  p.info := newLineInfo(filename, 0, 0);
  p.outp := LLStreamOpen('');
  p.inp := input;
  p.subsChar := charArg(call, 'subschar', 1, '$');
  p.nimDirective := charArg(call, 'metachar', 2, '#');
  p.emit := strArg(call, 'emit', 3, 'result.add');
  p.conc := strArg(call, 'conc', 4, ' & ');
  p.toStr := strArg(call, 'tostring', 5, '$'+'');
  while not LLStreamAtEnd(p.inp) do begin
    p.x := LLStreamReadLine(p.inp) {@ignore} + #0 {@emit};
    p.info.line := p.info.line + int16(1);
    parseLine(p);
  end;
  newLine(p);
  result := p.outp;
  LLStreamClose(p.inp);
end;

end.
