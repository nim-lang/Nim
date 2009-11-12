//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit vis;

// Virtual instruction set for Nimrod. This is used for LLVM code generation.

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, strutils, nhashes, trees, platform, magicsys,
  extccomp, options, nversion, nimsets, msgs, crc, bitsets, idents,
  lists, types, ccgutils, nos, ntime, ropes, nmath, passes, rodread,
  wordrecg, rnimsyn, treetab;
  
type
  TInstrKind = (
    insAddi,
  
  );
  TInstruction = record
    
  end;
  

implementation

end.
