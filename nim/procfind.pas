//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
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
  nsystem, ast, astalgo, msgs, semdata, types, trees;

function SearchForProc(c: PContext; fn: PSym; tos: int): PSym;
// Searchs for the fn in the symbol table. If the parameter lists are exactly
// the same the sym in the symbol table is returned, else nil.

function SearchForBorrowProc(c: PContext; fn: PSym; tos: int): PSym;
// Searchs for the fn in the symbol table. If the parameter lists are suitable
// for borrowing the sym in the symbol table is returned, else nil.

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
    if (a.name.id <> b.name.id) or not sameTypeOrNil(a.typ, b.typ) then exit;
    if (a.ast <> nil) and (b.ast <> nil) then
      if not ExprStructuralEquivalent(a.ast, b.ast) then exit;
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

function paramsFitBorrow(a, b: PNode): bool;
var
  i, len: int;
  m, n: PSym;
begin
  len := sonsLen(a);
  result := false;
  if len = sonsLen(b) then begin
    for i := 1 to len-1 do begin
      m := a.sons[i].sym;
      n := b.sons[i].sym;
      assert((m.kind = skParam) and (n.kind = skParam));
      if not equalOrDistinctOf(m.typ, n.typ) then exit;
    end;
    // return type:
    if not equalOrDistinctOf(a.sons[0].typ, b.sons[0].typ) then exit;
    result := true
  end
end;

function SearchForBorrowProc(c: PContext; fn: PSym; tos: int): PSym;
// Searchs for the fn in the symbol table. If the parameter lists are suitable
// for borrowing the sym in the symbol table is returned, else nil.
var
  it: TIdentIter;
  scope: int;
begin
  for scope := tos downto 0 do begin
    result := initIdentIter(it, c.tab.stack[scope], fn.Name);
    while result <> nil do begin
      // watchout! result must not be the same as fn!
      if (result.Kind = fn.kind) and (result.id <> fn.id) then begin
        if equalGenericParams(result.ast.sons[genericParamsPos], 
                              fn.ast.sons[genericParamsPos]) then begin
          if paramsFitBorrow(fn.typ.n, result.typ.n) then exit;
        end
      end;
      result := NextIdentIter(it, c.tab.stack[scope])
    end
  end
end;

end.
