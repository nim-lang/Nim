//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit filters;

// This module implements Nimrod's simple filters and helpers for filters.

{$include config.inc}

interface

uses
  nsystem, llstream, nos, charsets, wordrecg, idents, strutils,
  ast, astalgo, msgs, options, rnimsyn;

function filterReplace(input: PLLStream; const filename: string;
                       call: PNode): PLLStream;
function filterStrip(input: PLLStream; const filename: string;
                     call: PNode): PLLStream;

// helpers to retrieve arguments:
function charArg(n: PNode; const name: string; pos: int; default: Char): Char;
function strArg(n: PNode; const name: string; pos: int;
                const default: string): string;
function boolArg(n: PNode; const name: string; pos: int; default: bool): bool;

implementation

procedure invalidPragma(n: PNode);
begin
  liMessage(n.info, errXNotAllowedHere, renderTree(n, {@set}[renderNoComments]));
end;

function getArg(n: PNode; const name: string; pos: int): PNode;
var
  i: int;
begin
  result := nil;
  if n.kind in [nkEmpty..nkNilLit] then exit;
  for i := 1 to sonsLen(n)-1 do
    if n.sons[i].kind = nkExprEqExpr then begin
      if n.sons[i].sons[0].kind <> nkIdent then invalidPragma(n);
      if IdentEq(n.sons[i].sons[0].ident, name) then begin
        result := n.sons[i].sons[1];
        exit
      end
    end
    else if i = pos then begin
      result := n.sons[i]; exit
    end
end;

function charArg(n: PNode; const name: string; pos: int; default: Char): Char;
var
  x: PNode;
begin
  x := getArg(n, name, pos);
  if x = nil then result := default
  else if x.kind = nkCharLit then result := chr(int(x.intVal))
  else invalidPragma(n);
end;

function strArg(n: PNode; const name: string; pos: int;
                const default: string): string;
var
  x: PNode;
begin
  x := getArg(n, name, pos);
  if x = nil then result := default
  else if x.kind in [nkStrLit..nkTripleStrLit] then result := x.strVal
  else invalidPragma(n);
end;

function boolArg(n: PNode; const name: string; pos: int; default: bool): bool;
var
  x: PNode;
begin
  x := getArg(n, name, pos);
  if x = nil then result := default
  else if (x.kind = nkIdent) and IdentEq(x.ident, 'true') then result := true
  else if (x.kind = nkIdent) and IdentEq(x.ident, 'false') then result := false
  else invalidPragma(n);
end;

// -------------------------- strip filter -----------------------------------

function filterStrip(input: PLLStream; const filename: string;
                     call: PNode): PLLStream;
var
  line, pattern, stripped: string;
  leading, trailing: bool;
begin
  pattern := strArg(call, 'startswith', 1, '');
  leading := boolArg(call, 'leading', 2, true);
  trailing := boolArg(call, 'trailing', 3, true);
  
  result := LLStreamOpen('');
  while not LLStreamAtEnd(input) do begin
    line := LLStreamReadLine(input);
  {@ignore}
    stripped := strip(line);
  {@emit
    stripped := strip(line, leading, trailing);
  }
    if (length(pattern) = 0) or startsWith(stripped, pattern) then 
      LLStreamWriteln(result, stripped)
    else
      LLStreamWriteln(result, line)
  end;
  LLStreamClose(input);
end;

// -------------------------- replace filter ---------------------------------

function filterReplace(input: PLLStream; const filename: string;
                       call: PNode): PLLStream;
var
  line, sub, by: string;
begin
  sub := strArg(call, 'sub', 1, '');
  if length(sub) = 0 then invalidPragma(call);
  by := strArg(call, 'by', 2, '');

  result := LLStreamOpen('');  
  while not LLStreamAtEnd(input) do begin
    line := LLStreamReadLine(input);
    LLStreamWriteln(result, replace(line, sub, by))
  end;
  LLStreamClose(input);    
end;

end.
