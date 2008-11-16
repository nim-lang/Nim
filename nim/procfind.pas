//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit procfind;

// This module implements the searching for procs and iterators.
// This is needed for proper handling of forward declarations.

interface

{$include 'config.inc'}

uses 
  nsystem, ast, astalgo, msgs, semdata, types;

function SearchForProc(c: PContext; fn: PSym; tos: int): PSym;
// Searchs for the fn in the symbol table. If the parameter lists are exactly
// the same the sym in the symbol table is returned, else nil.

implementation

function equalGenericParams(procA, procB: PNode): Boolean;
var
  a, b: PSym;
  i: int;
begin
  result := procA = procB;
  if result then exit;
  if (procA = nil) or (procB = nil) then exit;
  
  if sonsLen(procA) <> sonsLen(procB) then exit;
  for i := 0 to sonsLen(procA)-1 do begin
    if procA.sons[i].kind <> nkSym then
      InternalError(procA.info, 'equalGenericParams');
    if procB.sons[i].kind <> nkSym then
      InternalError(procB.info, 'equalGenericParams');
    a := procA.sons[i].sym;
    b := procB.sons[i].sym;
    if (a.name.id <> b.name.id) or not sameType(a.typ, b.typ) then exit;
  end;
  result := true
end;

function SearchForProc(c: PContext; fn: PSym; tos: int): PSym;
var
  it: TIdentIter;
begin
  result := initIdentIter(it, c.tab.stack[tos], fn.Name);
  while result <> nil do begin
    if (result.Kind = fn.kind) then begin
      if equalGenericParams(result.ast.sons[genericParamsPos], 
                            fn.ast.sons[genericParamsPos]) then begin
        case equalParams(result.typ.n, fn.typ.n) of
          paramsEqual: exit;
          paramsIncompatible: begin
            liMessage(fn.info, errNotOverloadable, fn.name.s);
            exit
          end;
          paramsNotEqual: begin end; // continue search
        end;
      end
    end;
    result := NextIdentIter(it, c.tab.stack[tos])
  end
end;

end.
