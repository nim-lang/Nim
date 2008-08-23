//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module implements lookup helpers.

function getSymRepr(s: PSym): string;
begin
  case s.kind of
    skProc, skConverter, skIterator: result := getProcHeader(s);
    else result := s.name.s
  end
end;

procedure CloseScope(var tab: TSymTab);
var
  it: TTabIter;
  s: PSym;
begin
  // check if all symbols have been used and defined:
  if (tab.tos > length(tab.stack)) then InternalError('CloseScope');
  s := InitTabIter(it, tab.stack[tab.tos-1]);
  while s <> nil do begin
    if sfForward in s.flags then
      liMessage(s.info, errImplOfXexpected, getSymRepr(s))
    else if ([sfUsed, sfInInterface] * s.flags = []) and
            (optHints in s.options) then // BUGFIX: check options in s!
      if not (s.kind in [skForVar, skParam]) then
        liMessage(s.info, hintXDeclaredButNotUsed, getSymRepr(s));
    s := NextIter(it, tab.stack[tab.tos-1]);
  end;
  astalgo.rawCloseScope(tab);
end;

procedure AddSym(var t: TStrTable; n: PSym);
begin
  if StrTableIncl(t, n) then liMessage(n.info, errAttemptToRedefine, n.name.s);
end;

procedure addDecl(c: PContext; sym: PSym);
begin
  if SymTabAddUnique(c.tab, sym) = Failure then
    liMessage(sym.info, errAttemptToRedefine, sym.Name.s);
end;

procedure addDeclAt(c: PContext; sym: PSym; at: Natural);
begin
  if SymTabAddUniqueAt(c.tab, sym, at) = Failure then
    liMessage(sym.info, errAttemptToRedefine, sym.Name.s);
end;

procedure addOverloadableSymAt(c: PContext; fn: PSym; at: Natural);
var
  check: PSym;
begin
  if not (fn.kind in OverloadableSyms) then
    InternalError(fn.info, 'addOverloadableSymAt');
  check := StrTableGet(c.tab.stack[at], fn.name);
  if (check <> nil) and (check.Kind <> fn.kind) then
    liMessage(fn.info, errAttemptToRedefine, fn.Name.s);
  SymTabAddAt(c.tab, fn, at);
end;

procedure AddInterfaceDeclAux(c: PContext; sym: PSym);
begin
  if (sfInInterface in sym.flags) then begin
    // add to interface:
    if c.module = nil then InternalError(sym.info, 'AddInterfaceDeclAux');
    StrTableAdd(c.module.tab, sym);
  end;
  if getCurrOwner(c).kind = skModule then
    include(sym.flags, sfGlobal)
end;

procedure addInterfaceDecl(c: PContext; sym: PSym);
begin  // it adds the symbol to the interface if appropriate
  addDecl(c, sym);
  AddInterfaceDeclAux(c, sym);
end;

procedure addInterfaceOverloadableSymAt(c: PContext; sym: PSym; at: int);
begin  // it adds the symbol to the interface if appropriate
  addOverloadableSymAt(c, sym, at);
  AddInterfaceDeclAux(c, sym);
end;

function lookUp(c: PContext; n: PNode): PSym;
// Looks up a symbol. Generates an error in case of nil.
begin
  case n.kind of
    nkAccQuoted: result := lookup(c, n.sons[0]);
    nkSym: begin
      result := SymtabGet(c.Tab, n.sym.name);
      if result = nil then
        liMessage(n.info, errUndeclaredIdentifier, n.sym.name.s);
      include(result.flags, sfUsed);
    end;
    nkIdent: begin
      result := SymtabGet(c.Tab, n.ident);
      if result = nil then
        liMessage(n.info, errUndeclaredIdentifier, n.ident.s);
      include(result.flags, sfUsed);
    end
    else InternalError(n.info, 'lookUp');
  end
end;

function QualifiedLookUp(c: PContext; n: PNode; ambigiousCheck: bool): PSym;
var
  m: PSym;
  ident: PIdent;
begin
  case n.kind of
    nkIdent: begin
      result := SymtabGet(c.Tab, n.ident);
      if result = nil then
        liMessage(n.info, errUndeclaredIdentifier, n.ident.s)
      else if ambigiousCheck
          and StrTableContains(c.AmbigiousSymbols, result) then
        liMessage(n.info, errUseQualifier, n.ident.s)
    end;
    nkSym: begin
      result := SymtabGet(c.Tab, n.sym.name);
      if result = nil then
        liMessage(n.info, errUndeclaredIdentifier, n.sym.name.s)
      else if ambigiousCheck
          and StrTableContains(c.AmbigiousSymbols, result) then
        liMessage(n.info, errUseQualifier, n.sym.name.s)
    end;    
    nkDotExpr, nkQualified: begin
      result := nil;
      m := qualifiedLookUp(c, n.sons[0], false);
      if (m <> nil) and (m.kind = skModule) then begin
        if (n.sons[1].kind = nkIdent) then begin
          ident := n.sons[1].ident;
          if m = c.module then
            // a module may access its private members:
            result := StrTableGet(c.tab.stack[ModuleTablePos], ident)
          else
            result := StrTableGet(m.tab, ident);
          if result = nil then
            liMessage(n.sons[1].info, errUndeclaredIdentifier, ident.s)
        end
        else
          liMessage(n.sons[1].info, errIdentifierExpected, '');
      end
    end;
    nkAccQuoted: result := QualifiedLookup(c, n.sons[0], ambigiousCheck);
    else begin
      result := nil;
      //liMessage(n.info, errIdentifierExpected, '')
    end;
  end;
end;

type
  TOverloadIterMode = (oimNoQualifier, oimSelfModule, oimOtherModule);
  TOverloadIter = record
    stackPtr: int;
    it: TIdentIter;
    m: PSym;
    mode: TOverloadIterMode;
  end;

function InitOverloadIter(out o: TOverloadIter; c: PContext; n: PNode): PSym;
var
  ident: PIdent;
begin
  result := nil;
  case n.kind of
    nkIdent: begin
      o.stackPtr := c.tab.tos;
      o.mode := oimNoQualifier;
      while (result = nil) do begin
        dec(o.stackPtr);
        if o.stackPtr < 0 then break;
        result := InitIdentIter(o.it, c.tab.stack[o.stackPtr], n.ident);
      end;
    end;
    nkSym: begin
      o.stackPtr := c.tab.tos;
      o.mode := oimNoQualifier;
      while (result = nil) do begin
        dec(o.stackPtr);
        if o.stackPtr < 0 then break;
        result := InitIdentIter(o.it, c.tab.stack[o.stackPtr], n.sym.name);
      end;
    end;
    nkDotExpr, nkQualified: begin
      o.mode := oimOtherModule;
      o.m := qualifiedLookUp(c, n.sons[0], false);
      if (o.m <> nil) and (o.m.kind = skModule) then begin
        if (n.sons[1].kind = nkIdent) then begin
          ident := n.sons[1].ident;
          if o.m = c.module then begin
            // a module may access its private members:
            result := InitIdentIter(o.it, c.tab.stack[ModuleTablePos], ident);
            o.mode := oimSelfModule;
          end
          else
            result := InitIdentIter(o.it, o.m.tab, ident);
        end
        else
          liMessage(n.sons[1].info, errIdentifierExpected, '');
      end
    end;
    nkAccQuoted: result := InitOverloadIter(o, c, n.sons[0]);
    else begin end
  end
end;

function nextOverloadIter(var o: TOverloadIter; c: PContext; n: PNode): PSym;
begin
  case o.mode of
    oimNoQualifier: begin
      if n.kind = nkAccQuoted then 
        result := nextOverloadIter(o, c, n.sons[0]) // BUGFIX
      else if o.stackPtr >= 0 then begin
        result := nextIdentIter(o.it, c.tab.stack[o.stackPtr]);
        while (result = nil) do begin
          dec(o.stackPtr);
          if o.stackPtr < 0 then break;
          result := InitIdentIter(o.it, c.tab.stack[o.stackPtr], o.it.name);
          // BUGFIX: o.it.name <-> n.ident
        end
      end
      else result := nil;
    end;
    oimSelfModule:  result := nextIdentIter(o.it, c.tab.stack[ModuleTablePos]);
    oimOtherModule: result := nextIdentIter(o.it, o.m.tab);
  end
end;
