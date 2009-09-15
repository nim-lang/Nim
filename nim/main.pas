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
  nsystem, llstream, strutils, ast, astalgo, scanner, pnimsyn, rnimsyn, 
  options, msgs, nos, lists, condsyms, paslex, pasparse, rodread, rodwrite,
  ropes, trees, wordrecg, sem, semdata, idents, passes, docgen,
  extccomp, cgen, ecmasgen, platform, ptmplsyn, interact, nimconf, importer,
  passaux, depends, transf, evals, types;

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
  compMods: TFileModuleMap = {@ignore} nil {@emit @[]};
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

function newModule(const filename: string): PSym;
begin
  // We cannot call ``newSym`` here, because we have to circumvent the ID
  // mechanism, which we do in order to assign each module a persistent ID. 
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.id := -1; // for better error checking
  result.kind := skModule;
  result.name := getIdent(getFileTrunk(filename));
  result.owner := result; // a module belongs to itself
  result.info := newLineInfo(filename, 1, 1);
  include(result.flags, sfUsed);
  initStrTable(result.tab);
  RegisterModule(filename, result);

  StrTableAdd(result.tab, result); // a module knows itself
end;

function CompileModule(const filename: string;
                       isMainFile, isSystemFile: bool): PSym; forward;

function importModule(const filename: string): PSym;
// this is called by the semantic checking phase
begin
  result := getModule(filename);
  if result = nil then begin
    // compile the module
    result := compileModule(filename, false, false);
  end
  else if sfSystemModule in result.flags then
    liMessage(result.info, errAttemptToRedefine, result.Name.s);
end;

function CompileModule(const filename: string;
                       isMainFile, isSystemFile: bool): PSym;
var
  rd: PRodReader;
  f: string;
begin
  rd := nil;
  f := appendFileExt(filename, nimExt);
  result := newModule(filename);
  if isMainFile then include(result.flags, sfMainModule);
  if isSystemFile then include(result.flags, sfSystemModule);
  if (gCmd = cmdCompileToC) or (gCmd = cmdCompileToCpp) then begin
    rd := handleSymbolFile(result, f);
    if result.id < 0 then
      InternalError('handleSymbolFile should have set the module''s ID');
  end
  else
    result.id := getID();
  processModule(result, f, nil, rd);
end;

procedure CompileProject(const filename: string);
begin
  {@discard} CompileModule(
    JoinPath(options.libpath, appendFileExt('system', nimExt)), false, true);
  {@discard} CompileModule(appendFileExt(filename, nimExt), true, false);
end;

procedure semanticPasses;
begin
  registerPass(verbosePass());
  registerPass(sem.semPass());
  registerPass(transf.transfPass());
end;

procedure CommandGenDepend(const filename: string);
begin
  semanticPasses();
  registerPass(genDependPass());
  registerPass(cleanupPass());
  compileProject(filename);
  generateDot(filename);
  execExternalProgram('dot -Tpng -o' +{&} changeFileExt(filename, 'png') +{&}
                      ' ' +{&} changeFileExt(filename, 'dot'));
end;

procedure CommandCheck(const filename: string);
begin
  semanticPasses();
  // use an empty backend for semantic checking only
  compileProject(filename);
end;

procedure CommandCompileToC(const filename: string);
begin
  semanticPasses();
  registerPass(cgen.cgenPass());
  registerPass(rodwrite.rodwritePass());
  //registerPass(cleanupPass());
  compileProject(filename);
  //for i := low(TTypeKind) to high(TTypeKind) do
  //  MessageOut('kind: ' +{&} typeKindToStr[i] +{&} ' = ' +{&} toString(sameTypeA[i]));
  extccomp.CallCCompiler(changeFileExt(filename, ''));
end;

procedure CommandCompileToEcmaScript(const filename: string);
begin
  include(gGlobalOptions, optSafeCode);
  setTarget(osEcmaScript, cpuEcmaScript);
  initDefines();

  semanticPasses();
  registerPass(ecmasgenPass());
  compileProject(filename);
end;

procedure CommandInteractive();
var
  m: PSym;
begin
  include(gGlobalOptions, optSafeCode);
  setTarget(osNimrodVM, cpuNimrodVM);
  initDefines();

  registerPass(verbosePass());
  registerPass(sem.semPass());
  registerPass(transf.transfPass());
  registerPass(evals.evalPass());
  
  // load system module:
  {@discard} CompileModule(
    JoinPath(options.libpath, appendFileExt('system', nimExt)), false, true);

  m := newModule('stdin');
  m.id := getID();
  include(m.flags, sfMainModule);
  processModule(m, 'stdin', LLStreamOpenStdIn(), nil);
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
  f: string;
  stream: PLLStream;
begin
{@ignore}
  fillChar(tok, sizeof(tok), 0);
  fillChar(L, sizeof(L), 0);
{@emit}
  f := appendFileExt(filename, 'pas');
  stream := LLStreamOpen(f, fmRead);
  if stream <> nil then begin
    OpenLexer(L, f, stream);
    getPasTok(L, tok);
    while tok.xkind <> pxEof do begin
      printPasTok(tok);
      getPasTok(L, tok);
    end
  end
  else
    rawMessage(errCannotOpenFile, f);
  closeLexer(L);
end;

procedure CommandPas(const filename: string);
var
  p: TPasParser;
  module: PNode;
  f: string;
  stream: PLLStream;
begin
  f := appendFileExt(filename, 'pas');
  stream := LLStreamOpen(f, fmRead);
  if stream <> nil then begin
    OpenPasParser(p, f, stream);
    module := parseUnit(p);
    closePasParser(p);
    renderModule(module, getOutFile(filename, NimExt));
  end
  else
    rawMessage(errCannotOpenFile, f);
end;

procedure CommandScan(const filename: string);
var
  L: TLexer;
  tok: PToken;
  f: string;
  stream: PLLStream;
begin
  new(tok);
{@ignore}
  fillChar(tok^, sizeof(tok^), 0);
{@emit}
  f := appendFileExt(filename, nimExt);
  stream := LLStreamOpen(f, fmRead);
  if stream <> nil then begin 
    openLexer(L, f, stream);
    repeat
      rawGetTok(L, tok^);
      PrintTok(tok);
    until tok.tokType = tkEof;
    CloseLexer(L);
  end
  else
    rawMessage(errCannotOpenFile, f);
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
  appendStr(searchPaths, options.libpath);
  if filename <> '' then begin
    splitPath(filename, dir, f);
    // current path is always looked first for modules
    prependStr(searchPaths, dir);
  end;
  setID(100);
  passes.gIncludeFile := parseFile;
  passes.gIncludeTmplFile := ptmplsyn.parseTmplFile;
  passes.gImportModule := importModule;

  case whichKeyword(cmd) of
    wCompile, wCompileToC, wC, wCC: begin
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
    wCompileToLLVM: begin
      gCmd := cmdCompileToLLVM;
      wantFile(filename);
      CommandCompileToC(filename);
    end;
    wPretty: begin
      gCmd := cmdPretty;
      wantFile(filename);
      //CommandExportSymbols(filename);
      CommandPretty(filename);
    end;
    wDoc: begin
      gCmd := cmdDoc;
      LoadSpecialConfig(DocConfig);
      wantFile(filename);
      CommandDoc(filename);
    end;
    wRst2html: begin
      gCmd := cmdRst2html;
      LoadSpecialConfig(DocConfig);
      wantFile(filename);
      CommandRst2Html(filename);
    end;
    wRst2tex: begin
      gCmd := cmdRst2tex;
      LoadSpecialConfig(DocTexConfig);
      wantFile(filename);
      CommandRst2TeX(filename);
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
    wI: begin
      gCmd := cmdInteractive;
      CommandInteractive();
    end;
    else rawMessage(errInvalidCommandX, cmd);
  end
end;

end.
