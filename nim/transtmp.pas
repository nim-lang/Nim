//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module implements a transformator. It transforms the syntax tree 
// to ease the work of the code generators. Does the transformation to 
// introduce temporaries to split up complex expressions.
// THIS MODULE IS NOT USED!

procedure transInto(c: PContext; var dest: PNode; father, src: PNode); forward;
// transforms the expression `src` into the destination `dest`. Uses `father`
// for temorary statements. If dest = nil, the expression is put into a 
// temporary.

function transTmp(c: PContext; father, src: PNode): PNode; 
// convienence proc
begin
  result := nil;
  transInto(c, result, father, src);
end;

function newLabel(c: PContext): PSym;
begin
  inc(gTmpId);
  result := newSym(skLabel, getIdent(genPrefix +{&} ToString(gTmpId), 
                   c.transCon.owner));
end;

function fewCmps(s: PNode): bool;
// this function estimates whether it is better to emit code
// for constructing the set or generating a bunch of comparisons directly
begin
  assert(s.kind in [nkSetConstr, nkConstSetConstr]);
  if (s.typ.size <= platform.intSize) and
      (s.kind = nkConstSetConstr) then
    result := false      // it is better to emit the set generation code
  else if skipRange(s.typ.sons[0]).Kind in [tyInt..tyInt64] then
    result := true       // better not emit the set if int is basetype!
  else
    result := sonsLen(s) <= 8 // 8 seems to be a good value
end;

function transformIn(c: PContext; father, n: PNode): PNode;
var
  a, b, e, setc: PNode;
  destLabel, label2: PSym;
begin
  if (n.sons[1].kind = nkSetConstr) and fewCmps(n.sons[1]) then begin
    // a set constructor but not a constant set:
    // do not emit the set, but generate a bunch of comparisons
    result := newSymNode(newTemp(c, n.typ, n.info));
    e := transTmp(c, father, n.sons[2]);
    setc := n.sons[1];
    destLabel := newLabel(c);
    for i := 0 to sonsLen(setc)-1 do begin
      if setc.sons[i].kind = nkRange then begin
        a := transTmp(c, father, setc.sons[i].sons[0]);
        b := transTmp(c, father, setc.sons[i].sons[1]);
        label2 := newLabel(c);
        addSon(father, newLt(result, e, a)); // e < a? --> goto end
        addSon(father, newCondJmp(result, label2));
        addSon(father, newLe(result, e, b)); // e <= b? --> goto set end
        addSon(father, newCondJmp(result, destLabel));
        addSon(father, newLabelNode(label2));
      end
      else begin
        a := transTmp(c, father, setc.sons[i]);
        addSon(father, newEq(result, e, a));
        addSon(father, newCondJmp(result, destLabel));
      end
    end;
    addSon(father, newLabelNode(destLabel));
  end
  else begin
    result := n;
  end
end;

procedure transformOp2(c: PContext; var dest: PNode; father, n: PNode);
var
  a, b: PNode;
begin
  if dest = nil then dest := newSymNode(newTemp(c, n.typ, n.info));
  a := transTmp(c, father, n.sons[1]);
  b := transTmp(c, father, n.sons[2]);
  addSon(father, newAsgnStmt(dest, newOp2(n, a, b)));
end;

procedure transformOp1(c: PContext; var dest: PNode; father, n: PNode);
var
  a: PNode;
begin
  if dest = nil then dest := newSymNode(newTemp(c, n.typ, n.info));
  a := transTmp(c, father, n.sons[1]);
  addSon(father, newAsgnStmt(dest, newOp1(n, a)));
end;

procedure genTypeInfo(c: PContext; initSection: PNode);
begin
  
end;

procedure genNew(c: PContext; father, n: PNode);
begin
  // how do we handle compilerprocs?
  
end;

function transformCase(c: PContext; father, n: PNode): PNode;
var
  ty: PType;
  e: PNode;
begin
  ty := skipGeneric(n.sons[0].typ);
  if ty.kind = tyString then begin
    // transform a string case to a bunch of comparisons:
    result := newNodeI(nkIfStmt, n);
    e := transTmp(c, father, n.sons[0]);
    
  end
  else result := n
end;


procedure transInto(c: PContext; var dest: PNode; father, src: PNode); 
begin
  if src = nil then exit;
  if (src.typ <> nil) and (src.typ.kind = tyGenericInst) then 
    src.typ := skipGeneric(src.typ);
  case src.kind of 
    nkIdent..nkNilLit: begin
      if dest = nil then dest := copyTree(src)
      else begin
        // generate assignment:
        addSon(father, newAsgnStmt(dest, src));
      end
    end;
    nkCall: begin
    
    end;
    
  
  end;
end;
