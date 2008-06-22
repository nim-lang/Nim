//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// Virtual instruction set for Nimrod. Has been designed to support: 
// * efficient C code generation (most important goal)
// * efficient LLVM code generation (second goal)
// * interpretation 
// So it supports a typed virtual instruction set.

type
  TInstrKind = (
    insNone,      // invalid instruction
    insLabel,     // a label
    insTemp,      
    insGoto,      // a goto
    insTjmp,
    insFjmp, 
    insBin,       // ordinary binary operator
    insLast
  
  );
  TInstr = record
    Kind: TInstrKind;
    
  end;
  
  
