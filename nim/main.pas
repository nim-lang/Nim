//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit main;

// implements the command dispatcher and several commands as well as the
// module handling
{$include 'config.inc'}

interface

uses
  nsystem, strutils, ast, astalgo, scanner, pnimsyn, rnimsyn, options, msgs,
  nos, lists, condsyms, paslex, pasparse, rodgen, ropes, trees,
  wordrecg, sem, idents, magicsys, backends, docgen, extccomp, cgen,
  platform, ecmasgen;

procedure MainCommand(const cmd, filename: string);

implementation

// ------------------ module handling -----------------------------------------

type
  TFileModuleRec = record
    filename: string;
    module: PSym;
  end;
  TFileModuleMap = array of TFileModuleRec;
var
  compMods: TFileModuleMap = {@ignore} nil {@emit []};
    // all compiled modules

procedure registerModule(const filename: string; module: PSym);
var
  len: int;
begin
  len := length(compMods);
  setLength(compMods, len+1);
  compMods[len].filename := filename;
  compMods[len].module := module;
end;

function getModule(const filename: string): PSym;
var
  i: int;
begin
  for i := 0 to high(compMods) do
    if sameFile(compMods[i].filename, filename) then begin
      result := compMods[i].module; exit end;
  result := nil;
end;

// ----------------------------------------------------------------------------

function getFileTrunk(const filename: string): string;
var
  f, e, dir: string;
begin
  splitPath(filename, dir, f);
  splitFilename(f, result, e);
end;

function newIsMainModuleSym(module: PSym; isMainModule: bool): PSym;
begin
  result := newSym(skConst, getIdent('isMainModule'), module);
  result.info := module.info;
  result.typ := getSysType(tyBool);
  result.ast := newIntNode(nkIntLit, ord(isMainModule));
  result.ast.typ := result.typ;
  StrTableAdd(module.tab, result);
  if isMainModule then include(module.flags, sfMainModule);
end;

function newModule(const filename: string): PSym;
begin
  result := newSym(skModule, getIdent(getFileTrunk(filename)), nil);
  result.owner := result; // a module belongs to itself
  result.info := newLineInfo(filename, 1, 1);
  include(result.flags, sfUsed);
  initStrTable(result.tab);
  RegisterModule(filename, result);

  StrTableAdd(result.tab, result); // a module knows itself
end;

procedure msgCompiling(const modname: string);
begin
  if optVerbose in gGlobalOptions then MessageOut('compiling: ' + modname);
end;

procedure msgCompiled(const modname: string);
begin
  if optVerbose in gGlobalOptions then MessageOut('compiled: ' + modname);
end;

function CompileModule(const filename: string; backend: PBackend;
                       isMainFile, isSystemFile: bool): PSym; forward;

function importModule(const filename: string; backend: PBackend): PSym;
// this is called by the semantic checking phase
begin
  result := getModule(filename);
  if result = nil then begin
    // compile the module
    // XXX: here caching could be implemented
    result := compileModule(filename, backend, false, false);
  end
  else if sfSystemModule in result.flags then
    liMessage(result.info, errAttemptToRedefine, result.Name.s);
end;

function CompileModule(const filename: string; backend: PBackend;
                       isMainFile, isSystemFile: bool): PSym;
var
  ast: PNode;
  c: PContext;
begin
  result := newModule(filename);
  result.info := newLineInfo(filename, 1, 1);
  msgCompiling(result.name.s);
  ast := parseFile(appendFileExt(filename, nimExt));
  if ast = nil then exit;
  c := newContext(filename);
  c.b := backend.backendCreator(backend, result, filename);
  c.module := result;
  c.includeFile := parseFile;
  c.importModule := importModule;
  openScope(c.tab); // scope for imported symbols
  SymTabAdd(c.tab, result);
  if not isSystemFile then begin
    SymTabAdd(c.tab, magicsys.SystemModule); // import the "System" identifier
    importAllSymbols(c, magicsys.SystemModule);
    SymTabAdd(c.tab, newIsMainModuleSym(result, isMainFile));
  end
  else begin
    include(result.flags, sfSystemModule);
    magicsys.SystemModule := result; // set global variable!
    InitSystem(c.tab); // adds magics like "int", "ord" to the system module
  end;
  {@discard} semModule(c, ast);
  rawCloseScope(c.tab); // imported symbols; don't check for unused ones!
  msgCompiled(result.name.s);
end;

procedure CompileProject(const filename: string; backend: PBackend);
begin
  {@discard} CompileModule(
    JoinPath(options.libpath, appendFileExt('system', nimExt)),
    backend, false, true);
  {@discard} CompileModule(filename, backend, true, false);
end;

// ------------ dependency generator ----------------------------------------

var
  gDotGraph: PRope; // the generated DOT file; we need a global variable

procedure addDependencyAux(importing, imported: PSym);
begin
  appf(gDotGraph, '$1 -> $2;$n', [toRope(importing.name.s),
                                  toRope(imported.name.s)]);
  //    s1 -> s2_4 [label="[0-9]"];
end;

procedure addDotDependency(b: PBackend; n: PNode);
var
  i: int;
begin
  if n = nil then exit;
  case n.kind of
    nkEmpty..nkNilLit: begin end; // atom
    nkImportStmt: begin
      for i := 0 to sonsLen(n)-1 do begin
        assert(n.sons[i].kind = nkSym);
        addDependencyAux(b.module, n.sons[i].sym);
      end
    end;
    nkFromStmt: begin
      assert(n.sons[0].kind = nkSym);
      addDependencyAux(b.module, n.sons[0].sym);
    end;
    nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr: begin
      for i := 0 to sonsLen(n)-1 do addDotDependency(b, n.sons[i]);
    end
    else begin end
  end
end;

procedure generateDot(const project: string);
begin
  writeRope(
    ropef('digraph $1 {$n$2}$n', [
      toRope(changeFileExt(extractFileName(project), '')), gDotGraph]),
    changeFileExt(project, 'dot') );
end;

function genDependCreator(b: PBackend; module: PSym;
                          const filename: string): PBackend;
begin
  result := newBackend(module, filename);
  include(result.eventMask, eAfterModule);
  result.afterModuleEvent := addDotDependency;
  result.backendCreator := genDependCreator;
end;

procedure CommandGenDepend(const filename: string);
var
  b: PBackend;
begin
  b := genDependCreator(nil, nil, filename);
  compileProject(filename, b);
  generateDot(filename);
  execExternalProgram('dot -Tpng -o' +{&} changeFileExt(filename, 'png') +{&}
                      ' ' +{&} changeFileExt(filename, 'dot'));
end;

// --------------------------------------------------------------------------

procedure genDebugTrans(b: PBackend; module: PNode);
begin
  if module <> nil then
    renderModule(module, getOutFile(b.filename, 'pretty.'+NimExt));
end;

function genDebugTransCreator(b: PBackend; module: PSym;
                              const filename: string): PBackend;
begin
  result := newBackend(module, filename);
  include(result.eventMask, eAfterModule);
  result.backendCreator := genDebugTransCreator;
  result.afterModuleEvent := genDebugTrans;
end;

procedure CommandDebugTrans(const filename: string);
var
  b: PBackend;
begin
  b := genDebugTransCreator(nil, nil, filename);
  compileProject(filename, b);
end;

// --------------------------------------------------------------------------

procedure CommandCheck(const filename: string);
begin
  // use an empty backend for semantic checking only
  compileProject(filename, newBackend(nil, filename));
end;

procedure CommandCompileToC(const filename: string);
begin
  compileProject(filename, CBackend(nil, nil, filename));
  extccomp.CallCCompiler(changeFileExt(filename, ''));
end;

procedure CommandCompileToEcmaScript(const filename: string);
begin
  include(gGlobalOptions, optSafeCode);
  setTarget(osEcmaScript, cpuEcmaScript);
  initDefines();
  compileProject(filename, EcmasBackend(nil, nil, filename));
end;

// --------------------------------------------------------------------------

procedure exSymbols(n: PNode);
var
  i: int;
begin
  case n.kind of
    nkEmpty..nkNilLit: begin end; // atoms
    nkProcDef..nkIteratorDef: begin
      exSymbol(n.sons[namePos]);
    end;
    nkWhenStmt, nkStmtList: begin
      for i := 0 to sonsLen(n)-1 do exSymbols(n.sons[i])
    end;
    nkVarSection, nkConstSection: begin
      for i := 0 to sonsLen(n)-1 do
        exSymbol(n.sons[i].sons[0]);
    end;
    nkTypeSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        exSymbol(n.sons[i].sons[0]);
        if (n.sons[i].sons[2] <> nil) and
            (n.sons[i].sons[2].kind = nkObjectTy) then
          fixRecordDef(n.sons[i].sons[2])
      end
    end;
    else begin end
  end
end;

procedure CommandExportSymbols(const filename: string);
// now unused!
var
  module: PNode;
begin
  module := parseFile(appendFileExt(filename, NimExt));
  if module <> nil then begin
    exSymbols(module);
    renderModule(module, getOutFile(filename, 'pretty.'+NimExt));
  end
end;

procedure CommandPretty(const filename: string);
var
  module: PNode;
begin
  module := parseFile(appendFileExt(filename, NimExt));
  if module <> nil then
    renderModule(module, getOutFile(filename, 'pretty.'+NimExt));
end;

procedure CommandLexPas(const filename: string);
var
  L: TPasLex;
  tok: TPasTok;
begin
{@ignore}
  fillChar(tok, sizeof(tok), 0);
  fillChar(L, sizeof(L), 0);
{@emit}
  if OpenLexer(L, appendFileExt(filename, 'pas')) = success then begin
    getPasTok(L, tok);
    while tok.xkind <> pxEof do begin
      printPasTok(tok);
      getPasTok(L, tok);
    end
  end
  else
    rawMessage(errCannotOpenFile, appendFileExt(filename, 'pas'));
  closeLexer(L);
end;

procedure CommandPas(const filename: string);
var
  p: TPasParser;
  module: PNode;
begin
  if OpenPasParser(p, appendFileExt(filename, 'pas')) = failure then begin
    rawMessage(errCannotOpenFile, appendFileExt(filename, 'pas'));
    exit
  end;
  module := parseUnit(p);
  closePasParser(p);
  renderModule(module, getOutFile(filename, NimExt));
end;

procedure CommandTestRod(const filename: string);
var
  module, rod: PNode;
begin
  module := parseFile(appendFileExt(filename, nimExt));
  if module <> nil then begin
    generateRod(module, changeFileExt(filename, rodExt));
    rod := readRod(changeFileExt(filename, rodExt), {@set}[]);
    assert(rod <> nil);
    assert(sameTree(module, rod));
  end
end;

procedure CommandScan(const filename: string);
var
  L: TLexer;
  tok: PToken;
begin
  new(tok);
{@ignore}
  fillChar(tok^, sizeof(tok^), 0);
{@emit}
  if openLexer(L, appendFileExt(filename, nimExt)) = Success then begin
    repeat
      rawGetTok(L, tok^);
      PrintTok(tok)
    until tok.tokType = tkEof;
    CloseLexer(L)
  end
  else
    rawMessage(errCannotOpenFile, appendFileExt(filename, nimExt));
end;

procedure WantFile(const filename: string);
begin
  if filename = '' then
    liMessage(newLineInfo('command line', 1, 1), errCommandExpectsFilename);
end;

procedure MainCommand(const cmd, filename: string);
var
  dir, f: string;
begin
  if filename <> '' then begin
    appendStr(searchPaths, options.libpath);

    splitPath(filename, dir, f);
    // current path is always looked first for modules
    prependStr(searchPaths, dir);
  end;

  case whichKeyword(cmd) of
    wCompile, wCompileToC: begin
      // compile means compileToC currently
      gCmd := cmdCompileToC;
      wantFile(filename);
      CommandCompileToC(filename);
    end;
    wCompileToCpp: begin
      gCmd := cmdCompileToCpp;
      wantFile(filename);
      CommandCompileToC(filename);
    end;
    wCompileToEcmaScript: begin
      gCmd := cmdCompileToEcmaScript;
      wantFile(filename);
      CommandCompileToEcmaScript(filename);
    end;
    wPretty: begin
      // compile means compileToC currently
      gCmd := cmdPretty;
      wantFile(filename);
      //CommandExportSymbols(filename);
      CommandPretty(filename);
    end;
    wDoc: begin
      gCmd := cmdDoc;
      wantFile(filename);
      CommandDoc(filename);
    end;
    wPas: begin
      gCmd := cmdPas;
      wantFile(filename);
      CommandPas(filename);
    end;
    wBoot: begin
      gCmd := cmdBoot;
      wantFile(filename);
      CommandPas(filename);
    end;
    wGenDepend: begin
      gCmd := cmdGenDepend;
      wantFile(filename);
      CommandGenDepend(filename);
    end;
    wListDef: begin
      gCmd := cmdListDef;
      condsyms.ListSymbols();
    end;
    wCheck: begin
      gCmd := cmdCheck;
      wantFile(filename);
      CommandCheck(filename);
    end;
    wParse: begin
      gCmd := cmdParse;
      wantFile(filename);
      {@discard} parseFile(appendFileExt(filename, nimExt));
    end;
    wScan: begin
      gCmd := cmdScan;
      wantFile(filename);
      CommandScan(filename);
      MessageOut('Beware: Indentation tokens depend on the parser''s state!');
    end;
    wDebugTrans: begin
      gCmd := cmdDebugTrans;
      wantFile(filename);
      CommandDebugTrans(filename);
    end;
    wRst2html: begin
      gCmd := cmdRst2html;
      wantFile(filename);
      CommandRst2Html(filename);
    end
    else rawMessage(errInvalidCommandX, cmd);
  end
end;

end.
