//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit trees;

// tree helper routines

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, scanner, msgs, strutils;

function getMagic(op: PNode): TMagic;

// function getConstExpr(const t: TNode; out res: TNode): Boolean;

function isConstExpr(node: PNode): Boolean;


function flattenTree(root: PNode; op: TMagic): PNode;

function TreeToSym(t: PNode): PSym;

procedure SwapOperands(op: PNode);
function getOpSym(op: PNode): PSym;

function getProcSym(call: PNode): PSym;

function ExprStructuralEquivalent(a, b: PNode): Boolean;

function sameTree(a, b: PNode): boolean;

implementation

function ExprStructuralEquivalent(a, b: PNode): Boolean;
var
  i: int;
begin
  result := false;
  if a = b then begin
    result := true
  end
  else if (a <> nil) and (b <> nil) and (a.kind = b.kind) then
    case a.kind of
      nkSym: // don't go nuts here: same symbol as string is enough:
        result := a.sym.name.id = b.sym.name.id;
      nkIdent:
        result := a.ident.id = b.ident.id;
      nkCharLit..nkInt64Lit:
        result := a.intVal = b.intVal;
      nkFloatLit..nkFloat64Lit:
        result := a.floatVal = b.floatVal;
      nkStrLit..nkTripleStrLit:
        result := a.strVal = b.strVal;
      nkEmpty, nkNilLit, nkType: result := true;
      else if sonsLen(a) = sonsLen(b) then begin
        for i := 0 to sonsLen(a)-1 do
          if not ExprStructuralEquivalent(a.sons[i], b.sons[i]) then exit;
        result := true
      end
    end
end;

function sameTree(a, b: PNode): Boolean;
var
  i: int;
begin
  result := false;
  if a = b then begin
    result := true
  end
  else if (a <> nil) and (b <> nil) and (a.kind = b.kind) then begin
    if a.base <> b.base then exit;
    if a.info.line <> int(b.info.line) then exit;
    if a.info.col <> int(b.info.col) then exit;
    //if a.info.fileIndex <> b.info.fileIndex then exit;
    case a.kind of
      nkSym: // don't go nuts here: same symbol as string is enough:
        result := a.sym.name.id = b.sym.name.id;
      nkIdent:
        result := a.ident.id = b.ident.id;
      nkCharLit..nkInt64Lit:
        result := a.intVal = b.intVal;
      nkFloatLit..nkFloat64Lit:
        result := a.floatVal = b.floatVal;
      nkStrLit..nkTripleStrLit:
        result := a.strVal = b.strVal;
      nkEmpty, nkNilLit, nkType: result := true;
      else if sonsLen(a) = sonsLen(b) then begin
        for i := 0 to sonsLen(a)-1 do
          if not sameTree(a.sons[i], b.sons[i]) then exit;
        result := true
      end
    end
  end
end;

function getProcSym(call: PNode): PSym;
begin
  result := call.sons[0].sym;
end;

function getOpSym(op: PNode): PSym;
begin
  if not (op.kind in [nkCall, nkGenericCall]) then
    result := nil
  else begin
    assert(sonsLen(op) > 0);
    case op.sons[0].Kind of
      nkSym, nkQualified: result := op.sons[0].sym;
      else result := nil
    end
  end
end;

function getMagic(op: PNode): TMagic;
begin
  case op.kind of
    nkCall: begin
      case op.sons[0].Kind of
        nkSym, nkQualified: begin
          assert(op.sons[0].sym <> nil); // BUGFIX
          result := op.sons[0].sym.magic;
        end;
        else result := mNone
      end
    end;
    nkExplicitTypeListCall, nkGenericCall: begin
      result := getMagic(op.sons[sonsLen(op)-1]);
    end;
    else
      result := mNone
  end
end;

function TreeToSym(t: PNode): PSym;
begin
  result := t.sym
end;

function isConstExpr(node: PNode): Boolean;
begin
  result := (node.kind in [nkCharLit..nkInt64Lit, nkStrLit..nkTripleStrLit,
                           nkFloatLit..nkFloat64Lit,
                           nkConstSetConstr,
                           nkConstArrayConstr, nkConstRecordConstr])
end;

procedure flattenTreeAux(d, a: PNode; op: TMagic);
var
  i: int;
begin
  if (getMagic(a) = op) then // BUGFIX
    for i := 1 to sonsLen(a)-1 do // BUGFIX
      flattenTreeAux(d, a.sons[i], op)
  else
    // a is a "leaf", so add it:
    addSon(d, copyTree(a))
end;

function flattenTree(root: PNode; op: TMagic): PNode;
begin
  result := copyNode(root);
  if (getMagic(root) = op) then begin // BUGFIX: forget to copy prc
    addSon(result, copyNode(root.sons[0]));
    flattenTreeAux(result, root, op)
  end
end;

procedure SwapOperands(op: PNode);
var
  tmp: PNode;
begin
  tmp := op.sons[1];
  op.sons[1] := op.sons[2];
  op.sons[2] := tmp;
end;

end.
