//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit syntaxes;

// Implements the dispatcher for the different parsers.
{$include 'config.inc'}

interface

uses
  nsystem, strutils, llstream, ast, astalgo, idents, scanner, options, msgs, 
  pnimsyn, pbraces, ptmplsyn, filters, rnimsyn;

type
  TFilterKind = (filtNone, filtTemplate, filtReplace, filtStrip);
  TParserKind = (skinStandard, skinBraces, skinEndX);
  
const
  parserNames: array [TParserKind] of string = ('standard', 'braces', 'endx');
  filterNames: array [TFilterKind] of string = ('none', 'stdtmpl', 'replace',
                                                'strip');
  
type
  TParsers = record
    skin: TParserKind;
    parser: TParser;
  end;

{@ignore} 
function ParseFile(const filename: string): PNode;
{@emit
function ParseFile(const filename: string): PNode; procvar;
}

procedure openParsers(var p: TParsers; const filename: string;
                     inputstream: PLLStream);
procedure closeParsers(var p: TParsers);
function parseAll(var p: TParsers): PNode;

function parseTopLevelStmt(var p: TParsers): PNode;
// implements an iterator. Returns the next top-level statement or nil if end
// of stream.


implementation

function ParseFile(const filename: string): PNode;
var
  p: TParsers;
  f: TBinaryFile;
begin
  if not OpenFile(f, filename) then begin
    rawMessage(errCannotOpenFile, filename);
    exit
  end;
  OpenParsers(p, filename, LLStreamOpen(f));
  result := ParseAll(p);
  CloseParsers(p);
end;

function parseAll(var p: TParsers): PNode;
begin
  case p.skin of
    skinStandard: result := pnimsyn.parseAll(p.parser);
    skinBraces: result := pbraces.parseAll(p.parser);
    skinEndX: InternalError('parser to implement');
    // skinEndX: result := pendx.parseAll(p.parser);
  end
end;

function parseTopLevelStmt(var p: TParsers): PNode;
begin
  case p.skin of
    skinStandard: result := pnimsyn.parseTopLevelStmt(p.parser);
    skinBraces: result := pbraces.parseTopLevelStmt(p.parser); 
    skinEndX: InternalError('parser to implement');
    //skinEndX: result := pendx.parseTopLevelStmt(p.parser);
  end
end;

function UTF8_BOM(const s: string): int;
begin
  if (s[strStart] = #239) and (s[strStart+1] = #187) 
  and (s[strStart+2] = #191) then result := 3
  else result := 0
end;

function containsShebang(const s: string; i: int): bool;
var
  j: int;
begin
  result := false;
  if (s[i] = '#') and (s[i+1] = '!') then begin
    j := i+2;
    while s[j] in WhiteSpace do inc(j);
    result := s[j] = '/'
  end
end;

function parsePipe(const filename: string; inputStream: PLLStream): PNode;
var
  line: string;
  s: PLLStream;
  i: int;
  q: TParser;
begin
  result := nil;
  s := LLStreamOpen(filename, fmRead);
  if s <> nil then begin
    line := LLStreamReadLine(s) {@ignore} + #0 {@emit};
    i := UTF8_Bom(line) + strStart;
    if containsShebang(line, i) then begin
      line := LLStreamReadLine(s) {@ignore} + #0 {@emit};
      i := strStart;
    end;
    if (line[i] = '#') and (line[i+1] = '!') then begin
      inc(i, 2);
      while line[i] in WhiteSpace do inc(i);
      OpenParser(q, filename, LLStreamOpen(ncopy(line, i)));
      result := pnimsyn.parseAll(q);
      CloseParser(q);
    end;
    LLStreamClose(s);
  end
end;

function getFilter(ident: PIdent): TFilterKind;
var
  i: TFilterKind;
begin
  for i := low(TFilterKind) to high(TFilterKind) do
    if IdentEq(ident, filterNames[i]) then begin
      result := i; exit
    end;
  result := filtNone
end;

function getParser(ident: PIdent): TParserKind;
var
  i: TParserKind;
begin
  for i := low(TParserKind) to high(TParserKind) do
    if IdentEq(ident, parserNames[i]) then begin
      result := i; exit
    end;
  rawMessage(errInvalidDirectiveX, ident.s);
end;

function getCallee(n: PNode): PIdent;
begin
  if (n.kind = nkCall) and (n.sons[0].kind = nkIdent) then
    result := n.sons[0].ident
  else if n.kind = nkIdent then result := n.ident
  else rawMessage(errXNotAllowedHere, renderTree(n));
end;

function applyFilter(var p: TParsers; n: PNode; const filename: string; 
                     input: PLLStream): PLLStream;
var
  ident: PIdent;
  f: TFilterKind;
begin
  ident := getCallee(n);
  f := getFilter(ident); 
  case f of
    filtNone: begin
      p.skin := getParser(ident);
      result := input
    end;
    filtTemplate: result := filterTmpl(input, filename, n);
    filtStrip: result := filterStrip(input, filename, n);
    filtReplace: result := filterReplace(input, filename, n);
  end;
  if f <> filtNone then begin
    if gVerbosity >= 2 then begin
      rawMessage(hintCodeBegin);
      messageOut(result.s);
      rawMessage(hintCodeEnd);
    end
  end
end;

function evalPipe(var p: TParsers; n: PNode; const filename: string;
                  start: PLLStream): PLLStream;
var 
  i: int;
begin
  result := start;
  if n = nil then exit;
  if (n.kind = nkInfix) and (n.sons[0].kind = nkIdent)
  and IdentEq(n.sons[0].ident, '|'+'') then begin
    for i := 1 to 2 do begin
      if n.sons[i].kind = nkInfix then
        result := evalPipe(p, n.sons[i], filename, result)
      else
        result := applyFilter(p, n.sons[i], filename, result)
    end
  end
  else if n.kind = nkStmtList then 
    result := evalPipe(p, n.sons[0], filename, result)
  else
    result := applyFilter(p, n, filename, result)
end;

procedure openParsers(var p: TParsers; const filename: string;
                     inputstream: PLLStream);
var
  pipe: PNode;
  s: PLLStream;
begin
  p.skin := skinStandard;
  pipe := parsePipe(filename, inputStream);
  if pipe <> nil then 
    s := evalPipe(p, pipe, filename, inputStream)
  else
    s := inputStream;
  case p.skin of
    skinStandard, skinBraces, skinEndX:
      pnimsyn.openParser(p.parser, filename, s);
  end
end;

procedure closeParsers(var p: TParsers);
begin
  pnimsyn.closeParser(p.parser);
end;

end.
