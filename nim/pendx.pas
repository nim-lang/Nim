//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit pendx;

{$include config.inc}

interface

uses
  nsystem, llstream, scanner, idents, strutils, ast, msgs, pnimsyn;

function ParseAll(var p: TParser): PNode;

function parseTopLevelStmt(var p: TParser): PNode;
// implements an iterator. Returns the next top-level statement or nil if end
// of stream.

implementation

function ParseAll(var p: TParser): PNode;
begin
  result := nil
end;

function parseTopLevelStmt(var p: TParser): PNode;
begin
  result := nil
end;

end.
