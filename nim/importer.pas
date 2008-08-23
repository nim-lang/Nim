//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module implements the symbol importing mechanism.

function findModule(const info: TLineInfo; const modulename: string): string;
// returns path to module
begin
  result := options.FindFile(AppendFileExt(modulename, nimExt));
  if result = '' then
    liMessage(info, errCannotOpenFile, modulename);
end;

function getModuleFile(n: PNode): string;
begin
  case n.kind of
    nkStrLit, nkRStrLit, nkTripleStrLit: begin
      result := findModule(n.info, UnixToNativePath(n.strVal));
    end;
    nkIdent: begin
      result := findModule(n.info, n.ident.s);
    end;
    nkSym: begin
      result := findModule(n.info, n.sym.name.s);
    end;
    else begin
      internalError(n.info, 'getModuleFile()');
      result := '';
    end
  end
end;

procedure rawImportSymbol(c: PContext; s: PSym);
var
  check, copy, e: PSym;
  j: int;
  etyp: PType; // enumeration type
begin
  //copy := copySym(s, true);
  //copy.ast := s.ast;
  copy := s; // do not copy symbols when importing!
  // check if we have already a symbol of the same name:
  check := StrTableGet(c.tab.stack[importTablePos], s.name);
  if check <> nil then begin
    if not (s.kind in OverloadableSyms) then begin
      {@discard} StrTableIncl(c.AmbigiousSymbols, copy);
      {@discard} StrTableIncl(c.AmbigiousSymbols, check);
        // s and check need to be qualified
    end
  end;
  StrTableAdd(c.tab.stack[importTablePos], copy);
  if s.kind = skType then begin
    etyp := s.typ;
    if etyp.kind = tyEnum then begin
      for j := 0 to sonsLen(etyp.n)-1 do begin
        e := etyp.n.sons[j].sym;
        if (e.Kind = skEnumField) then rawImportSymbol(c, e)
        else InternalError(s.info, 'rawImportSymbol');
      end
    end
  end
  else if s.kind = skConverter then
    addConverter(c, s);
end;

procedure importSymbol(c: PContext; ident: PNode; fromMod: PSym);
var
  s, e: PSym;
  it: TIdentIter;
begin
  if (ident.kind <> nkIdent) then InternalError(ident.info, 'importSymbol');
  s := StrTableGet(fromMod.tab, ident.ident);
  if s = nil then
    liMessage(ident.info, errUndeclaredIdentifier, ident.ident.s);
  if not (s.Kind in ExportableSymKinds) then
    InternalError(ident.info, 'importSymbol: 2');
  // for an enumeration we have to add all identifiers
  case s.Kind of
    skProc, skIterator, skMacro, skTemplate, skConverter: begin
      // for a overloadable syms add all overloaded routines
      e := InitIdentIter(it, fromMod.tab, s.name);
      while e <> nil do begin
        if (e.name.id <> s.Name.id) then
          InternalError(ident.info, 'importSymbol: 3');
        rawImportSymbol(c, e);
        e := NextIdentIter(it, fromMod.tab);
      end
    end;
    else rawImportSymbol(c, s)
  end
end;

procedure importAllSymbols(c: PContext; fromMod: PSym);
var
  i: TTabIter;
  s: PSym;
begin
  s := InitTabIter(i, fromMod.tab);
  while s <> nil do begin
    if s.kind <> skModule then begin
      if s.kind <> skEnumField then begin
        if not (s.Kind in ExportableSymKinds) then
          InternalError(s.info, 'importAllSymbols');
        rawImportSymbol(c, s); // this is correct!
      end
    end;
    s := NextIter(i, fromMod.tab)
  end
end;

function evalImport(c: PContext; n: PNode): PNode;
var
  m: PSym;
  i: int;
begin
  result := copyNode(n);
  for i := 0 to sonsLen(n)-1 do begin
    m := c.ImportModule(getModuleFile(n.sons[i]), c.b);
    // ``addDecl`` needs to be done before ``importAllSymbols``!
    addDecl(c, m); // add symbol to symbol table of module
    importAllSymbols(c, m);
    addSon(result, newSymNode(m));
  end;
end;

function evalFrom(c: PContext; n: PNode): PNode;
var
  m: PSym;
  i: int;
begin
  result := n;
  checkMinSonsLen(n, 2);
  m := c.ImportModule(getModuleFile(n.sons[0]), c.b);
  n.sons[0] := newSymNode(m);
  addDecl(c, m); // add symbol to symbol table of module
  for i := 1 to sonsLen(n)-1 do importSymbol(c, n.sons[i], m);
end;

function evalInclude(c: PContext; n: PNode): PNode;
var
  i: int;
  x: PNode;
begin
  result := newNodeI(nkStmtList, n.info);
  for i := 0 to sonsLen(n)-1 do begin
    x := c.includeFile(getModuleFile(n.sons[i]));
    x := semStmt(c, x);
    addSon(result, x);
  end;
end;
