//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit optast;

// Optimizations that can be done by AST transformations. The code generators
// should work without the optimizer. The optimizer does the following:

// - cross-module constant merging
// - cross-module generic merging
// - lowers set operations to bit operations
// - inlining of procs
// - ``s == ""`` --> ``len(s) == 0``
// - optimization of ``&`` string operator

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, strutils, hashes, trees, treetab, platform, magicsys,
  options, msgs, crc, idents, lists, types, ropes, nmath, wordrecg, rnimsyn;
  
implementation


end.

