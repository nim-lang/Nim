//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit options;

interface

{$include 'config.inc'}

uses
  nsystem, nos, lists, strutils, nstrtabs;

type
  // please make sure we have under 32 options
  // (improves code efficiency a lot!)
  TOption = (  // **keep binary compatible**
    optNone,
    optObjCheck,
    optFieldCheck, optRangeCheck,
    optBoundsCheck, optOverflowCheck, optNilCheck, optAssert, optLineDir,
    optWarns, optHints,
    optOptimizeSpeed,
    optOptimizeSize,
    optStackTrace,     // stack tracing support
    optLineTrace,      // line tracing support (includes stack tracing)
    optEndb,           // embedded debugger
    optByRef,          // use pass by ref for records (for interfacing with C)
    optCheckpoints,    // check for checkpoints (used for debugging)
    optProfiler        // profiler turned on
  );
  TOptions = set of TOption;

  TGlobalOption = (gloptNone, optForceFullMake, optBoehmGC,
    optRefcGC, optDeadCodeElim, optListCmd, optCompileOnly, optNoLinking,
    optSafeCode,       // only allow safe code
    optCDebug,         // turn on debugging information
    optGenDynLib,      // generate a dynamic library
    optGenGuiApp,      // generate a GUI application
    optGenScript,      // generate a script file to compile the *.c files
    optGenMapping,     // generate a mapping file
    optRun,            // run the compiled project
    optSymbolFiles,    // use symbol files for speeding up compilation
    optSkipConfigFile, // skip the general config file
    optSkipProjConfigFile, // skip the project's config file
    optNoMain          // do not generate a "main" proc
  );
  TGlobalOptions = set of TGlobalOption;

  TCommands = ( // Nimrod's commands
    cmdNone,
    cmdCompileToC,
    cmdCompileToCpp,
    cmdCompileToEcmaScript,
    cmdCompileToLLVM,
    cmdInterpret,
    cmdPretty,
    cmdDoc,
    cmdPas,
    cmdBoot,
    cmdGenDepend,
    cmdListDef,
    cmdCheck,      // semantic checking for whole project
    cmdParse,      // parse a single file (for debugging)
    cmdScan,       // scan a single file (for debugging)
    cmdDebugTrans, // debug a transformation pass
    cmdRst2html,   // convert a reStructuredText file to HTML
    cmdRst2tex,    // convert a reStructuredText file to TeX
    cmdInteractive // start interactive session
  );
  TStringSeq = array of string;

const
  ChecksOptions = {@set}[optObjCheck, optFieldCheck, optRangeCheck,
                         optNilCheck, optOverflowCheck, optBoundsCheck,
                         optAssert];
  optionToStr: array [TOption] of string = (
    'optNone', 'optObjCheck', 'optFieldCheck', 'optRangeCheck',
    'optBoundsCheck', 'optOverflowCheck', 'optNilCheck', 'optAssert',
    'optLineDir', 'optWarns', 'optHints', 'optOptimizeSpeed',
    'optOptimizeSize', 'optStackTrace', 'optLineTrace', 'optEmdb',
    'optByRef', 'optCheckpoints', 'optProfiler'
  );
var
  gOptions: TOptions = {@set}[optObjCheck, optFieldCheck, optRangeCheck,
                              optBoundsCheck, optOverflowCheck,
                              optAssert, optWarns, optHints,
                              optStackTrace, optLineTrace];

  gGlobalOptions: TGlobalOptions = {@set}[optRefcGC];

  gExitcode: Byte;
  searchPaths: TLinkedList;
  outFile: string = '';
  gIndexFile: string = '';

  gCmd: TCommands = cmdNone; // the command

  gVerbosity: int; // how verbose the compiler is

function FindFile(const f: string): string;

const
  genSubDir = 'nimcache';
  NimExt = 'nim';
  RodExt = 'rod';
  HtmlExt = 'html';
  TexExt = 'tex';
  IniExt = 'ini';
  TmplExt = 'tmpl';
  DocConfig = 'nimdoc.cfg';
  DocTexConfig = 'nimdoc.tex.cfg';

function completeGeneratedFilePath(const f: string;
                                   createSubDir: bool = true): string;

function toGeneratedFile(const path, ext: string): string;
// converts "/home/a/mymodule.nim", "rod" to "/home/a/nimcache/mymodule.rod"

function getPrefixDir: string;
// gets the application directory

function getFileTrunk(const filename: string): string;

// additional configuration variables:
var
  gConfigVars: PStringTable;
  libpath: string = '';
  projectPath: string = '';
  gKeepComments: boolean = true; // whether the parser needs to keep comments
  gImplicitMods: TStringSeq = {@ignore} nil {@emit @[]};
    // modules that are to be implicitly imported

function existsConfigVar(const key: string): bool;
function getConfigVar(const key: string): string;
procedure setConfigVar(const key, val: string);

procedure addImplicitMod(const filename: string);

function getOutFile(const filename, ext: string): string;

function binaryStrSearch(const x: array of string; const y: string): int;

implementation

function existsConfigVar(const key: string): bool;
begin
  result := hasKey(gConfigVars, key)
end;

function getConfigVar(const key: string): string;
begin
  result := nstrtabs.get(gConfigVars, key);
end;

procedure setConfigVar(const key, val: string);
begin
  nstrtabs.put(gConfigVars, key, val);
end;

function getOutFile(const filename, ext: string): string;
begin
  if options.outFile <> '' then result := options.outFile
  else result := changeFileExt(filename, ext)
end;

procedure addImplicitMod(const filename: string);
var
  len: int;
begin
  len := length(gImplicitMods);
  setLength(gImplicitMods, len+1);
  gImplicitMods[len] := filename;
end;

function getPrefixDir: string;
var
  appdir, bin: string;
begin
  appdir := getApplicationDir();
  SplitPath(appdir, result, bin);
end;

function getFileTrunk(const filename: string): string;
var
  f, e, dir: string;
begin
  splitPath(filename, dir, f);
  splitFilename(f, result, e);
end;

function shortenDir(const dir: string): string;
var 
  prefix: string;
begin
  // returns the interesting part of a dir
  prefix := getPrefixDir() +{&} dirSep;
  if startsWith(dir, prefix) then begin
    result := ncopy(dir, length(prefix) + strStart); exit
  end;
  prefix := getCurrentDir() +{&} dirSep;
  if startsWith(dir, prefix) then begin
    result := ncopy(dir, length(prefix) + strStart); exit
  end;
  prefix := projectPath +{&} dirSep;
  //writeln(output, prefix);
  //writeln(output, dir);
  if startsWith(dir, prefix) then begin
    result := ncopy(dir, length(prefix) + strStart); exit
  end;
  result := dir;
end;

function removeTrailingDirSep(const path: string): string;
begin
  if (length(path) > 0) and (path[length(path)+strStart-1] = dirSep) then
    result := ncopy(path, strStart, length(path)+strStart-2)
  else
    result := path
end;

function toGeneratedFile(const path, ext: string): string;
var
  head, tail: string;
begin
  splitPath(path, head, tail);
  if length(head) > 0 then head := shortenDir(head +{&} dirSep);
  result := joinPath([projectPath, genSubDir, head, 
                      changeFileExt(tail, ext)])
end;

function completeGeneratedFilePath(const f: string;
                                   createSubDir: bool = true): string;
var
  head, tail, subdir: string;
begin
  splitPath(f, head, tail);
  if length(head) > 0 then
    head := removeTrailingDirSep(shortenDir(head +{&} dirSep));
  subdir := joinPath([projectPath, genSubDir, head]);
  if createSubDir then begin
    try
      createDir(subdir);
    except
      on EOS do begin
        writeln(output, 'cannot create directory: ' + subdir);
        halt(1)
      end
    end
  end;
  result := joinPath(subdir, tail)
end;

function rawFindFile(const f: string): string;
var
  it: PStrEntry;
begin
  if ExistsFile(f) then result := f
  else begin
    it := PStrEntry(SearchPaths.head);
    while it <> nil do begin
      result := JoinPath(it.data, f);
      if ExistsFile(result) then exit;
      it := PStrEntry(it.Next)
    end;
    result := ''
  end
end;

function FindFile(const f: string): string;
begin
  result := rawFindFile(f);
  if length(result) = 0 then
    result := rawFindFile(toLower(f));
end;

function binaryStrSearch(const x: array of string; const y: string): int;
var
  a, b, mid, c: int;
begin
  a := 0;
  b := length(x)-1;
  while a <= b do begin
    mid := (a + b) div 2;
    c := cmpIgnoreCase(x[mid], y);
    if c < 0 then
      a := mid + 1
    else if c > 0 then
      b := mid - 1
    else begin
      result := mid;
      exit
    end
  end;
  result := -1
end;

initialization
  gConfigVars := newStringTable([], modeStyleInsensitive);
end.
