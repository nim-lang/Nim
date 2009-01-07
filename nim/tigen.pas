//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit tigen;

// Type information generator. It transforms types into the AST of walker
// procs. This is used by the code generators.

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, strutils, hashes, trees, treetab, platform, magicsys,
  options, msgs, crc, idents, lists, types, rnimsyn;
  
function gcWalker(t: PType): PNode;
function initWalker(t: PType): PNode;
function asgnWalker(t: PType): PNode;
function reprWalker(t: PType): PNode;

implementation

function gcWalker(t: PType): PNode;
begin
end;

function initWalker(t: PType): PNode;
begin
end;

function asgnWalker(t: PType): PNode;
begin
end;

function reprWalker(t: PType): PNode;
begin
end;

end.

