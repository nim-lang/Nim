//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit syntaxes;

// Defines the common interface of all parsers & renderers.
// All parsers and renderers need to register here!
// This file is currently unused.
{$include 'config.inc'}

interface

uses
  nsystem, strutils, ast, scanner, pnimsyn, rnimsyn, options, msgs,
  nos, lists, condsyms, paslex, pasparse, rodgen, ropes, trees;

// how to handle the different keyword sets?
// PIdent does not support multiple ids! But I want to allow
// constant expressions, else the case-statement wouldn't work
// resulting in ugly code -> let the build system deal with it!
// IDEA: the scanner changes the IDs for its keywords: Won't work!
// How to deal with the `` operator?

type
  TSyntaxes = (synStandard, synCurly, synLisp);

function parseFile(const filename: string): PNode;

implementation

type
  TFileParser = function (const filename: string): PNode;
  TBufferParser = function (const buf, filename: string; 
                            line, column: int): PNode;
  TRenderer = function (n: PNode): string;
  THeadParser = function (const line: string): bool;
  TSyntax = record
    name: string;            // name of the syntax
    headParser: THeadParser; // the head parser
    parser: TParser;         // the parser for the syntax
    renderer: TRenderer;     // renderer of the syntax; may be nil
  end;

var
  syntaxes: array [TSyntaxes] of TSyntax;

procedure addSyntax(const s: TSyntax);
var
  len: int;
begin
  len := length(syntaxes);
  setLength(syntaxes, len+1);
  syntaxes[len] := s;
end;

initialization
  syntaxes[synStandard].name = 'Standard';
  
end.
