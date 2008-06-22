//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit options;

interface

{$include 'config.inc'}

uses
  nsystem, nos, lists, strutils;

type
  // please make sure we have under 32 options
  // (improves code efficiency a lot!)
  TOption = (optNone, optRangeCheck,
    optBoundsCheck, optOverflowCheck, optNilCheck, optAssert, optLineDir,
    optWarns, optHints,
    optOptimizeSpeed,
    optOptimizeSize,
    optStackTrace,     // stack tracing support
    optLineTrace,      // line tracing support (includes stack tracing)
    optEndb,           // embedded debugger
    optByRef,          // use pass by ref for records (for interfacing with C)
    optCheckpoints     // check for checkpoints (used for debugging)
  );
  TOptions = set of TOption;

  TGlobalOption = (gloptNone, optForceFullMake, optBoehmGC,
    optRefcGC, optDeadCodeElim, optListCmd, optCompileOnly, optNoLinking,
    optSafeCode,       // only allow safe code
                       // a new comment line
    optCDebug,         // turn on debugging information
    optGenDynLib,
    optGenGuiApp,
    optVerbose,        // be verbose
    optGenScript,      // generate a script file to compile the *.c files
    optGenMapping,     // generate a mapping file
    optRun,            // run the compiled project
    optCompileSys,     // compile system files

    optMergeOutput,    // generate only one C output file
    optSkipConfigFile, // skip the general config file
    optSkipProjConfigFile, // skip the project's config file
    optAstCache,
    optCFileCache
  );
  TGlobalOptions = set of TGlobalOption;

  TCommands = ( // Nimrod's commands
    cmdNone,
    cmdCompileToC,
    cmdCompileToCpp,
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
    cmdRst2html    // convert a reStructuredText file to HTML
  );

  TNumericalBase = (base10, // base10 is listed as the first element,
                            // so that it is the correct default value
                    base2,
                    base8,
                    base16);


const
  ChecksOptions = {@set}[optRangeCheck, optNilCheck, optOverflowCheck,
                         optBoundsCheck, optAssert];
  optionToStr: array [TOption] of string = (
    'optNone', 'optRangeCheck',
    'optBoundsCheck', 'optOverflowCheck', 'optNilCheck', 'optAssert',
    'optLineDir', 'optWarns', 'optHints', 'optOptimizeSpeed',
    'optOptimizeSize', 'optStackTrace', 'optLineTrace', 'optEmdb',
    'optByRef', 'optCheckpoints'
  );
var
  gOptions: TOptions = {@set}[optRangeCheck, optBoundsCheck, optOverflowCheck,
                              optAssert, optWarns, optHints, optLineDir,
                              optStackTrace, optLineTrace];

  gGlobalOptions: TGlobalOptions = {@set}[optRefcGC];

  compilerArgs: int;
  gExitcode: Byte;
  searchPaths: TLinkedList;
  outFile: string = '';
  gIndexFile: string = '';

  gCmd: TCommands = cmdNone; // the command

  debugState: int; // a global switch used for better debugging...
                   // not used for any program logic


function FindFile(const f: string): string;

const
  genSubDir = 'rod_gen';
  NimExt = 'nim';
  RodExt = 'rod';
  HtmlExt = 'html';

function completeGeneratedFilePath(const f: string;
                                   createSubDir: bool = true): string;

function toGeneratedFile(const path, ext: string): string;
// converts "/home/a/mymodule.nim", "rod" to "/home/a/rod_gen/mymodule.rod"

function getPrefixDir: string;
// gets the application directory

// additional configuration variables:
type
  TPair = record
    key, val: string;
  end;
  TPairs = array of TPair;

  TStringSeq = array of string;
var
  gConfigVars: TPairs = {@ignore} nil {@emit []};
  libpath: string = '';
  gKeepComments: boolean = true; // whether the parser needs to keep comments
  gImplicitMods: TStringSeq = {@ignore} nil {@emit []};
    // modules that are to be implicitly imported

procedure setConfigVar(const key, val: string);
function getConfigVar(const key: string): string;

procedure addImplicitMod(const filename: string);

function getOutFile(const filename, ext: string): string;

function binaryStrSearch(const x: array of string; const y: string): int;

implementation

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

function getConfigIdx(const key: string): int;
var
  i: int;
begin
  for i := 0 to high(gConfigVars) do
    if cmpIgnoreStyle(gConfigVars[i].key, key) = 0 then begin
      result := i; exit end;
  result := -1
end;

function getConfigVar(const key: string): string;
var
  i: int;
begin
  i := getConfigIdx(key);
  if i >= 0 then result := gConfigVars[i].val
  else result := ''
end;

procedure setConfigVar(const key, val: string);
var
  i: int;
begin
  i := getConfigIdx(key);
  if i < 0 then begin
    i := length(gConfigVars);
    setLength(gConfigVars, i+1);
    gConfigVars[i].key := key
  end;
  gConfigVars[i].val := val
end;

function toGeneratedFile(const path, ext: string): string;
var
  head, tail: string;
begin
  splitPath(path, head, tail);
  result := joinPath([head, genSubDir, changeFileExt(tail, ext)])
end;

function completeGeneratedFilePath(const f: string;
                                   createSubDir: bool = true): string;
var
  head, tail, subdir: string;
begin
  splitPath(f, head, tail);
  subdir := joinPath(head, genSubDir);
  if createSubDir then
    createDir(subdir);
  result := joinPath(subdir, tail)
end;

function FindFile(const f: string): string;
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

end.
