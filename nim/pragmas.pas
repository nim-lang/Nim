//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit pragmas;

// This module implements semantic checking for pragmas

interface

{$include 'config.inc'}

uses
  nsystem, nos, platform, condsyms, ast, astalgo, idents, semdata, msgs,
  rnimsyn, wordrecg, ropes, options, strutils, lists, extccomp, nmath,
  magicsys;

const
  FirstCallConv = wNimcall;
  LastCallConv  = wNoconv;

const
  procPragmas = {@set}[FirstCallConv..LastCallConv,
    wImportc, wExportc, wNodecl, wMagic, wNosideEffect, wSideEffect,
    wNoreturn, wDynLib, wHeader, wCompilerProc, wPure,
    wCppMethod, wDeprecated, wVarargs, wCompileTime, wMerge,
    wBorrow];
  converterPragmas = procPragmas;
  macroPragmas = {@set}[FirstCallConv..LastCallConv,
    wImportc, wExportc, wNodecl, wMagic, wNosideEffect,
    wCompilerProc, wDeprecated, wTypeCheck];
  iteratorPragmas = {@set}[FirstCallConv..LastCallConv, 
    wNosideEffect, wSideEffect,
    wImportc, wExportc, wNodecl, wMagic, wDeprecated, wBorrow];
  stmtPragmas = {@set}[wChecks, wObjChecks, wFieldChecks, wRangechecks,
    wBoundchecks, wOverflowchecks, wNilchecks, wAssertions, wWarnings,
    wHints, wLinedir, wStacktrace, wLinetrace, wOptimization,
    wHint, wWarning, wError, wFatal, wDefine, wUndef,
    wCompile, wLink, wLinkSys, wPure,
    wPush, wPop, wBreakpoint, wCheckpoint,
    wPassL, wPassC, wDeadCodeElim];
  lambdaPragmas = {@set}[FirstCallConv..LastCallConv,
    wImportc, wExportc, wNodecl, wNosideEffect, wSideEffect, 
    wNoreturn, wDynLib, wHeader, wPure, wDeprecated];
  typePragmas = {@set}[wImportc, wExportc, wDeprecated, wMagic, wAcyclic,
                      wNodecl, wPure, wHeader, wCompilerProc, wFinal];
  fieldPragmas = {@set}[wImportc, wExportc, wDeprecated];
  varPragmas = {@set}[wImportc, wExportc, wVolatile, wRegister, wThreadVar,
                      wNodecl, wMagic, wHeader, wDeprecated, wCompilerProc,
                      wDynLib];
  constPragmas = {@set}[wImportc, wExportc, wHeader, wDeprecated,
                        wMagic, wNodecl];
  procTypePragmas = [FirstCallConv..LastCallConv, wVarargs, wNosideEffect];

procedure pragma(c: PContext; sym: PSym; n: PNode;
                 const validPragmas: TSpecialWords);

function pragmaAsm(c: PContext; n: PNode): char;

implementation

procedure invalidPragma(n: PNode);
begin
  liMessage(n.info, errInvalidPragmaX, renderTree(n, {@set}[renderNoComments]));
end;

function pragmaAsm(c: PContext; n: PNode): char;
var
  i: int;
  it: PNode;
begin
  result := #0;
  if n <> nil then begin
    for i := 0 to sonsLen(n)-1 do begin
      it := n.sons[i];
      if (it.kind = nkExprColonExpr) and (it.sons[0].kind = nkIdent) then begin
        case whichKeyword(it.sons[0].ident) of
          wSubsChar: begin
            if it.sons[1].kind = nkCharLit then
              result := chr(int(it.sons[1].intVal))
            else invalidPragma(it)
          end
          else
            invalidPragma(it)
        end
      end
      else
        invalidPragma(it);
    end
  end
end;

const
  FirstPragmaWord = wMagic;
  LastPragmaWord = wNoconv;

procedure MakeExternImport(s: PSym; const extname: string);
begin
  s.loc.r := toRope(extname);
  Include(s.flags, sfImportc);
  Exclude(s.flags, sfForward);
end;

procedure MakeExternExport(s: PSym; const extname: string);
begin
  s.loc.r := toRope(extname);
  Include(s.flags, sfExportc);
end;

function expectStrLit(c: PContext; n: PNode): string;
begin
  if n.kind <> nkExprColonExpr then begin
    liMessage(n.info, errStringLiteralExpected);
    result := ''
  end
  else begin
    n.sons[1] := c.semConstExpr(c, n.sons[1]);
    case n.sons[1].kind of
      nkStrLit, nkRStrLit, nkTripleStrLit: result := n.sons[1].strVal;
      else begin
        liMessage(n.info, errStringLiteralExpected);
        result := ''
      end
    end
  end
end;

function expectIntLit(c: PContext; n: PNode): int;
begin
  if n.kind <> nkExprColonExpr then begin
    liMessage(n.info, errIntLiteralExpected);
    result := 0
  end
  else begin
    n.sons[1] := c.semConstExpr(c, n.sons[1]);
    case n.sons[1].kind of
      nkIntLit..nkInt64Lit: result := int(n.sons[1].intVal);
      else begin
        liMessage(n.info, errIntLiteralExpected);
        result := 0
      end
    end
  end
end;

function getOptionalStr(c: PContext; n: PNode;
                        const defaultStr: string): string;
begin
  if n.kind = nkExprColonExpr then
    result := expectStrLit(c, n)
  else
    result := defaultStr
end;

procedure processMagic(c: PContext; n: PNode; s: PSym);
var
  v: string;
  m: TMagic;
begin
  //if not (sfSystemModule in c.module.flags) then
  //  liMessage(n.info, errMagicOnlyInSystem);
  if n.kind <> nkExprColonExpr then
    liMessage(n.info, errStringLiteralExpected);
  if n.sons[1].kind = nkIdent then v := n.sons[1].ident.s
  else v := expectStrLit(c, n);
  Include(s.flags, sfImportc); // magics don't need an implementation, so we
  // treat them as imported, instead of modifing a lot of working code
  // BUGFIX: magic does not imply ``lfNoDecl`` anymore!
  for m := low(TMagic) to high(TMagic) do
    if magicToStr[m] = v then begin
      s.magic := m; exit
    end;
  // else: no magic found; make this a warning!
  liMessage(n.info, warnUnknownMagic, v);
end;

function wordToCallConv(sw: TSpecialWord): TCallingConvention;
begin
  // this assumes that the order of special words and calling conventions is
  // the same
  result := TCallingConvention(ord(ccDefault) + ord(sw) - ord(wNimcall));
end;

procedure onOff(c: PContext; n: PNode; op: TOptions);
begin
  if (n.kind = nkExprColonExpr) and (n.sons[1].kind = nkIdent) then begin
    case whichKeyword(n.sons[1].ident) of
      wOn:  gOptions := gOptions + op;
      wOff: gOptions := gOptions - op;
      else  liMessage(n.info, errOnOrOffExpected)
    end
  end
  else
    liMessage(n.info, errOnOrOffExpected)
end;

procedure pragmaDeadCodeElim(c: PContext; n: PNode); 
begin
  if (n.kind = nkExprColonExpr) and (n.sons[1].kind = nkIdent) then begin
    case whichKeyword(n.sons[1].ident) of
      wOn:  include(c.module.flags, sfDeadCodeElim);
      wOff: exclude(c.module.flags, sfDeadCodeElim);
      else  liMessage(n.info, errOnOrOffExpected)
    end
  end
  else
    liMessage(n.info, errOnOrOffExpected)
end;

procedure processCallConv(c: PContext; n: PNode);
var
  sw: TSpecialWord;
begin
  if (n.kind = nkExprColonExpr) and (n.sons[1].kind = nkIdent) then begin
    sw := whichKeyword(n.sons[1].ident);
    case sw of
      firstCallConv..lastCallConv:
        POptionEntry(c.optionStack.tail).defaultCC := wordToCallConv(sw);
      else
        liMessage(n.info, errCallConvExpected)
    end
  end
  else
    liMessage(n.info, errCallConvExpected)
end;

function getLib(c: PContext; kind: TLibKind; const path: string): PLib;
var
  it: PLib;
begin
  it := PLib(c.libs.head);
  while it <> nil do begin
    if it.kind = kind then begin
      if ospCaseInsensitive in platform.OS[targetOS].props then begin
        if cmpIgnoreCase(it.path, path) = 0 then begin result := it; exit end;
      end
      else begin
        if it.path = path then begin result := it; exit end;
      end
    end;
    it := PLib(it.next)
  end;
  // not found --> we need a new one:
  result := newLib(kind);
  result.path := path;
  Append(c.libs, result)
end;

procedure processDynLib(c: PContext; n: PNode; sym: PSym);
var
  lib: PLib;
begin
  if (sym = nil) or (sym.kind = skModule) then
    POptionEntry(c.optionStack.tail).dynlib := getLib(c, libDynamic,
                                                      expectStrLit(c, n))
  else begin
    lib := getLib(c, libDynamic, expectStrLit(c, n));
    addToLib(lib, sym);
    include(sym.loc.flags, lfDynamicLib)
  end
end;

procedure processNote(c: PContext; n: PNode);
var
  x: int;
  nk: TNoteKind;
begin
  if (n.kind = nkExprColonExpr) and (sonsLen(n) = 2)
  and (n.sons[0].kind = nkBracketExpr) and (n.sons[0].sons[1].kind = nkIdent)
  and (n.sons[0].sons[0].kind = nkIdent) and (n.sons[1].kind = nkIdent) then begin
    case whichKeyword(n.sons[0].sons[0].ident) of
      wHint: begin
        x := findStr(msgs.HintsToStr, n.sons[0].sons[1].ident.s);
        if x >= 0 then nk := TNoteKind(x + ord(hintMin))
        else invalidPragma(n)
      end;
      wWarning: begin
        x := findStr(msgs.WarningsToStr, n.sons[0].sons[1].ident.s);
        if x >= 0 then nk := TNoteKind(x + ord(warnMin))
        else InvalidPragma(n)
      end;
      else begin
        invalidPragma(n); exit
      end
    end;
    case whichKeyword(n.sons[1].ident) of
      wOn: include(gNotes, nk);
      wOff: exclude(gNotes, nk);
      else liMessage(n.info, errOnOrOffExpected)
    end
  end
  else
    invalidPragma(n);
end;

procedure processOption(c: PContext; n: PNode);
var
  sw: TSpecialWord;
begin
  if n.kind <> nkExprColonExpr then invalidPragma(n)
  else if n.sons[0].kind = nkBracketExpr then
    processNote(c, n)
  else if n.sons[0].kind <> nkIdent then
    invalidPragma(n)
  else begin
    sw := whichKeyword(n.sons[0].ident);
    case sw of
      wChecks: OnOff(c, n, checksOptions);
      wObjChecks: OnOff(c, n, {@set}[optObjCheck]);
      wFieldchecks: OnOff(c, n, {@set}[optFieldCheck]);
      wRangechecks: OnOff(c, n, {@set}[optRangeCheck]);
      wBoundchecks: OnOff(c, n, {@set}[optBoundsCheck]);
      wOverflowchecks: OnOff(c, n, {@set}[optOverflowCheck]);
      wNilchecks: OnOff(c, n, {@set}[optNilCheck]);
      wAssertions: OnOff(c, n, {@set}[optAssert]);
      wWarnings: OnOff(c, n, {@set}[optWarns]);
      wHints: OnOff(c, n, {@set}[optHints]);
      wCallConv: processCallConv(c, n);
      // ------ these are not in the Nimrod spec: -------------
      wLinedir: OnOff(c, n, {@set}[optLineDir]);
      wStacktrace: OnOff(c, n, {@set}[optStackTrace]);
      wLinetrace: OnOff(c, n, {@set}[optLineTrace]);
      wDebugger: OnOff(c, n, {@set}[optEndb]);
      wProfiler: OnOff(c, n, {@set}[optProfiler]);
      wByRef: OnOff(c, n, {@set}[optByRef]);
      wDynLib: processDynLib(c, n, nil);
      // -------------------------------------------------------
      wOptimization: begin
        if n.sons[1].kind <> nkIdent then
          invalidPragma(n)
        else begin
          case whichKeyword(n.sons[1].ident) of
            wSpeed: begin
              include(gOptions, optOptimizeSpeed);
              exclude(gOptions, optOptimizeSize);
            end;
            wSize: begin
              exclude(gOptions, optOptimizeSpeed);
              include(gOptions, optOptimizeSize);
            end;
            wNone: begin
              exclude(gOptions, optOptimizeSpeed);
              exclude(gOptions, optOptimizeSize);
            end;
            else
              liMessage(n.info, errNoneSpeedOrSizeExpected);
          end
        end
      end;
      else liMessage(n.info, errOptionExpected);
    end
  end;
  // BUGFIX this is a little hack, but at least it works:
  //getCurrOwner(c).options := gOptions;
end;

procedure processPush(c: PContext; n: PNode; start: int);
var
  i: int;
  x, y: POptionEntry;
begin
  x := newOptionEntry();
  y := POptionEntry(c.optionStack.tail);
  x.options := gOptions;
  x.defaultCC := y.defaultCC;
  x.dynlib := y.dynlib;
  x.notes := gNotes;
  append(c.optionStack, x);
  for i := start to sonsLen(n)-1 do
    processOption(c, n.sons[i]);
  //liMessage(n.info, warnUser, ropeToStr(optionsToStr(gOptions)));
end;

procedure processPop(c: PContext; n: PNode);
begin
  if c.optionStack.counter <= 1 then
    liMessage(n.info, errAtPopWithoutPush)
  else begin
    gOptions := POptionEntry(c.optionStack.tail).options;
    //liMessage(n.info, warnUser, ropeToStr(optionsToStr(gOptions)));
    gNotes := POptionEntry(c.optionStack.tail).notes;
    remove(c.optionStack, c.optionStack.tail);
  end
end;

procedure processDefine(c: PContext; n: PNode);
begin
  if (n.kind = nkExprColonExpr) and (n.sons[1].kind = nkIdent) then begin
    DefineSymbol(n.sons[1].ident.s);
    liMessage(n.info, warnDeprecated, 'define');
  end
  else
    invalidPragma(n)
end;

procedure processUndef(c: PContext; n: PNode);
begin
  if (n.kind = nkExprColonExpr) and (n.sons[1].kind = nkIdent) then begin
    UndefSymbol(n.sons[1].ident.s);
    liMessage(n.info, warnDeprecated, 'undef');
  end
  else
    invalidPragma(n)
end;

type
  TLinkFeature = (linkNormal, linkSys);

procedure processCompile(c: PContext; n: PNode);
var
  s, found, trunc, ext: string;
begin
  s := expectStrLit(c, n);
  found := findFile(s);
  if found = '' then found := s;
  splitFilename(found, trunc, ext);
  extccomp.addExternalFileToCompile(trunc);
  extccomp.addFileToLink(completeCFilePath(trunc, false));
end;

procedure processCommonLink(c: PContext; n: PNode; feature: TLinkFeature);
var
  f, tmp, ext, found: string;
begin
  f := expectStrLit(c, n);
  splitFilename(f, tmp, ext);
  if (ext = '') then
    f := toObjFile(tmp);
  found := findFile(f);
  if found = '' then
    found := f; // use the default
  case feature of
    linkNormal: extccomp.addFileToLink(found);
    linkSys: begin
      extccomp.addFileToLink(joinPath(libpath,
        completeCFilePath(found, false)));
    end
    else internalError(n.info, 'processCommonLink');
  end
end;

procedure PragmaBreakpoint(c: PContext; n: PNode);
begin
  {@discard} getOptionalStr(c, n, '');
end;

procedure PragmaCheckpoint(c: PContext; n: PNode);
// checkpoints can be used to debug the compiler; they are not documented
var
  info: TLineInfo;
begin
  info := n.info;
  inc(info.line); // next line is affected!
  msgs.addCheckpoint(info);
end;

procedure noVal(n: PNode);
begin
  if n.kind = nkExprColonExpr then invalidPragma(n)
end;

procedure pragma(c: PContext; sym: PSym; n: PNode;
                 const validPragmas: TSpecialWords);
var
  i: int;
  key, it: PNode;
  k: TSpecialWord;
  lib: PLib;
begin
  if n = nil then exit;
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if it.kind = nkExprColonExpr then begin
      key := it.sons[0];
    end
    else begin
      key := it;
    end;
    if key.kind = nkIdent then begin
      k := whichKeyword(key.ident);
      if k in validPragmas then begin
        case k of
          wExportc: begin
            makeExternExport(sym, getOptionalStr(c, it, sym.name.s));
            include(sym.flags, sfUsed); // avoid wrong hints
          end;
          wImportc: begin
            makeExternImport(sym, getOptionalStr(c, it, sym.name.s));
          end;
          wAlign: begin
            if sym.typ = nil then invalidPragma(it);
            sym.typ.align := expectIntLit(c, it);
            if not IsPowerOfTwo(sym.typ.align) and (sym.typ.align <> 0) then
              liMessage(it.info, errPowerOfTwoExpected);
          end;
          wNodecl: begin noVal(it); Include(sym.loc.Flags, lfNoDecl); end;
          wPure: begin
            noVal(it);
            if sym <> nil then include(sym.flags, sfPure);
          end;
          wVolatile: begin noVal(it); Include(sym.flags, sfVolatile); end;
          wRegister: begin noVal(it); include(sym.flags, sfRegister); end;
          wThreadVar: begin noVal(it); include(sym.flags, sfThreadVar); end;
          wDeadCodeElim: pragmaDeadCodeElim(c, it);
          wMagic: processMagic(c, it, sym);
          wCompileTime: begin
            noVal(it);
            include(sym.flags, sfCompileTime);
            include(sym.loc.Flags, lfNoDecl);
          end;
          wMerge: begin
            noval(it);
            include(sym.flags, sfMerge);
          end;
          wHeader: begin
            lib := getLib(c, libHeader, expectStrLit(c, it));
            addToLib(lib, sym);
            include(sym.flags, sfImportc);
            include(sym.loc.flags, lfHeader);
            include(sym.loc.Flags, lfNoDecl); // implies nodecl, because
            // otherwise header would not make sense
            if sym.loc.r = nil then sym.loc.r := toRope(sym.name.s)
          end;
          wNosideeffect: begin 
            noVal(it); Include(sym.flags, sfNoSideEffect); 
            if sym.typ <> nil then include(sym.typ.flags, tfNoSideEffect);
          end;
          wSideEffect: begin noVal(it); Include(sym.flags, sfSideEffect); end;
          wNoReturn: begin noVal(it); Include(sym.flags, sfNoReturn); end;
          wDynLib: processDynLib(c, it, sym);
          wCompilerProc: begin
            noVal(it); // compilerproc may not get a string!
            makeExternExport(sym, sym.name.s);
            include(sym.flags, sfCompilerProc);
            include(sym.flags, sfUsed); // suppress all those stupid warnings
            registerCompilerProc(sym);
          end;
          wCppMethod: begin
            makeExternImport(sym, getOptionalStr(c, it, sym.name.s));
            include(sym.flags, sfCppMethod);
          end;
          wDeprecated: begin
            noVal(it);
            include(sym.flags, sfDeprecated);
          end;
          wVarargs: begin
            noVal(it);
            if sym.typ = nil then invalidPragma(it);
            include(sym.typ.flags, tfVarargs);
          end;
          wBorrow: begin
            noVal(it);
            include(sym.flags, sfBorrow);
          end;
          wFinal: begin
            noVal(it);
            if sym.typ = nil then invalidPragma(it);
            include(sym.typ.flags, tfFinal);
          end;
          wAcyclic: begin
            noVal(it);
            if sym.typ = nil then invalidPragma(it);
            include(sym.typ.flags, tfAcyclic);
          end;
          wTypeCheck: begin
            noVal(it);
            include(sym.flags, sfTypeCheck);
          end;

          // statement pragmas:
          wHint: liMessage(it.info, hintUser, expectStrLit(c, it));
          wWarning: liMessage(it.info, warnUser, expectStrLit(c, it));
          wError: liMessage(it.info, errUser, expectStrLit(c, it));
          wFatal: begin
            liMessage(it.info, errUser, expectStrLit(c, it));
            halt(1);
          end;
          wDefine: processDefine(c, it);
          wUndef: processUndef(c, it);
          wCompile: processCompile(c, it);
          wLink: processCommonLink(c, it, linkNormal);
          wLinkSys: processCommonLink(c, it, linkSys);
          wPassL: extccomp.addLinkOption(expectStrLit(c, it));
          wPassC: extccomp.addCompileOption(expectStrLit(c, it));

          wBreakpoint: PragmaBreakpoint(c, it);
          wCheckpoint: PragmaCheckpoint(c, it);

          wPush: begin processPush(c, n, i+1); break end;
          wPop: processPop(c, it);
          wChecks, wObjChecks, wFieldChecks,
          wRangechecks, wBoundchecks, wOverflowchecks, wNilchecks,
          wAssertions, wWarnings, wHints, wLinedir, wStacktrace,
          wLinetrace, wOptimization, wByRef, wCallConv, wDebugger, wProfiler:
            processOption(c, it);
          // calling conventions (boring...):
          firstCallConv..lastCallConv: begin
            assert(sym <> nil);
            if sym.typ = nil then invalidPragma(it);
            sym.typ.callConv := wordToCallConv(k)
          end
          else invalidPragma(it);
        end
      end
      else invalidPragma(it);
    end
    else begin
      processNote(c, n)
    end;
  end;
  if (sym <> nil) and (sym.kind <> skModule) then begin
    lib := POptionEntry(c.optionstack.tail).dynlib;
    if ([lfDynamicLib, lfHeader] * sym.loc.flags = []) and
         (sfImportc in sym.flags) and
         (lib <> nil) then begin
      include(sym.loc.flags, lfDynamicLib);
      addToLib(lib, sym);
      if sym.loc.r = nil then sym.loc.r := toRope(sym.name.s)
    end
  end
end;

end.
