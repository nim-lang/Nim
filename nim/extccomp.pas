//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit extccomp;

// module for calling the different external C compilers

interface

{$include 'config.inc'}

uses
  nsystem, charsets, lists, ropes, nos, strutils, osproc, platform, condsyms, 
  options, msgs;

// some things are read in from the configuration file

type
  TSystemCC = (ccNone, ccGcc, ccLLVM_Gcc, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc,
               ccTcc, ccPcc, ccUcc, ccIcc, ccGpp);

  TInfoCCProp = ( // properties of the C compiler:
    hasSwitchRange,  // CC allows ranges in switch statements (GNU C extension)
    hasComputedGoto, // CC has computed goto (GNU C extension)
    hasCpp           // CC is/contains a C++ compiler
  );
  TInfoCCProps = set of TInfoCCProp;
  TInfoCC = record{@tuple}
    name: string;            // the short name of the compiler
    objExt: string;          // the compiler's object file extenstion
    optSpeed: string;        // the options for optimization for speed
    optSize: string;         // the options for optimization for size
    compilerExe: string;     // the compiler's executable
    compileTmpl: string;     // the compile command template
    buildGui: string;        // command to build a GUI application
    buildDll: string;        // command to build a shared library
    linkerExe: string;       // the linker's executable
    linkTmpl: string;        // command to link files to produce an executable
    includeCmd: string;      // command to add an include directory path
    debug: string;           // flags for debug build
    pic: string;             // command for position independent code
                             // used on some platforms
    asmStmtFrmt: string;     // format of ASM statement
    props: TInfoCCProps;     // properties of the C compiler
  end;
const
  CC: array [succ(low(TSystemCC))..high(TSystemCC)] of TInfoCC = (
    (
      name: 'gcc';
      objExt: 'o'+'';
      optSpeed: ' -O3 -ffast-math ';
      optSize: ' -Os -ffast-math ';
      compilerExe: 'gcc';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      linkerExe: 'gcc';
      linkTmpl: '$options $buildgui $builddll -o $exefile $objfiles';
      includeCmd: ' -I';
      debug: '';
      pic: '-fPIC';
      asmStmtFrmt: 'asm($1);$n';
      props: {@set}[hasSwitchRange, hasComputedGoto, hasCpp];
    ),
    (
      name: 'llvm_gcc';
      objExt: 'o'+'';
      optSpeed: ' -O3 -ffast-math ';
      optSize: ' -Os -ffast-math ';
      compilerExe: 'llvm-gcc';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      linkerExe: 'llvm-gcc';
      linkTmpl: '$options $buildgui $builddll -o $exefile $objfiles';
      includeCmd: ' -I';
      debug: '';
      pic: '-fPIC';
      asmStmtFrmt: 'asm($1);$n';
      props: {@set}[hasSwitchRange, hasComputedGoto, hasCpp];
    ),
    (
      name: 'lcc';
      objExt: 'obj';
      optSpeed: ' -O -p6 ';
      optSize: ' -O -p6 ';
      compilerExe: 'lcc';
      compileTmpl: '$options $include -Fo$objfile $file';
      buildGui: ' -subsystem windows';
      buildDll: ' -dll';
      linkerExe: 'lcclnk';
      linkTmpl: '$options $buildgui $builddll -O $exefile $objfiles';
      includeCmd: ' -I';
      debug: ' -g5 ';
      pic: '';
      asmStmtFrmt: '_asm{$n$1$n}$n';
      props: {@set}[];
    ),
    (
      name: 'bcc';
      objExt: 'obj';
      optSpeed: ' -O2 -6 ';
      optSize: ' -O1 -6 ';
      compilerExe: 'bcc32';
      compileTmpl: '-c $options $include -o$objfile $file';
      buildGui: ' -tW';
      buildDll: ' -tWD';
      linkerExe: 'bcc32';
      linkTmpl: '$options $buildgui $builddll -e$exefile $objfiles';
      includeCmd: ' -I';
      debug: '';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[hasCpp];
    ),
    (
      name: 'dmc';
      objExt: 'obj';
      optSpeed: ' -ff -o -6 ';
      optSize: ' -ff -o -6 ';
      compilerExe: 'dmc';
      compileTmpl: '-c $options $include -o$objfile $file';
      buildGui: ' -L/exet:nt/su:windows';
      buildDll: ' -WD';
      linkerExe: 'dmc';
      linkTmpl: '$options $buildgui $builddll -o$exefile $objfiles';
      includeCmd: ' -I';
      debug: ' -g ';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[hasCpp];
    ),
    (
      name: 'wcc';
      objExt: 'obj';
      optSpeed: ' -ox -on -6 -d0 -fp6 -zW ';
      optSize: '';
      compilerExe: 'wcl386';
      compileTmpl: '-c $options $include -fo=$objfile $file';
      buildGui: ' -bw';
      buildDll: ' -bd';
      linkerExe: 'wcl386';
      linkTmpl: '$options $buildgui $builddll -fe=$exefile $objfiles ';
      includeCmd: ' -i=';
      debug: ' -d2 ';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[hasCpp];
    ),
    (
      name: 'vcc';
      objExt: 'obj';
      optSpeed: ' /Ogityb2 /G7 /arch:SSE2 ';
      optSize: ' /O1 /G7 ';
      compilerExe: 'cl';
      compileTmpl: '/c $options $include /Fo$objfile $file';
      buildGui: ' /link /SUBSYSTEM:WINDOWS ';
      buildDll: ' /LD';
      linkerExe: 'cl';
      linkTmpl: '$options $builddll /Fe$exefile $objfiles $buildgui';
      includeCmd: ' /I';
      debug: ' /GZ /Zi ';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[hasCpp];
    ),
    (
      name: 'tcc';
      objExt: 'o'+'';
      optSpeed: '';
      optSize: '';
      compilerExe: 'tcc';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: 'UNAVAILABLE!';
      buildDll: ' -shared';
      linkerExe: 'tcc';
      linkTmpl: '-o $exefile $options $buildgui $builddll $objfiles';
      includeCmd: ' -I';
      debug: ' -g ';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[hasSwitchRange, hasComputedGoto];
    ),
    (
      name: 'pcc'; // Pelles C
      objExt: 'obj';
      optSpeed: ' -Ox ';
      optSize: ' -Os ';
      compilerExe: 'cc';
      compileTmpl: '-c $options $include -Fo$objfile $file';
      buildGui: ' -SUBSYSTEM:WINDOWS';
      buildDll: ' -DLL';
      linkerExe: 'cc';
      linkTmpl: '$options $buildgui $builddll -OUT:$exefile $objfiles';
      includeCmd: ' -I';
      debug: ' -Zi ';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[];
    ),
    (
      name: 'ucc';
      objExt: 'o'+'';
      optSpeed: ' -O3 ';
      optSize: ' -O1 ';
      compilerExe: 'cc';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: '';
      buildDll: ' -shared ';
      linkerExe: 'cc';
      linkTmpl: '-o $exefile $options $buildgui $builddll $objfiles';
      includeCmd: ' -I';
      debug: '';
      pic: '';
      asmStmtFrmt: '__asm{$n$1$n}$n';
      props: {@set}[];
    ), (
      name: 'icc';
      objExt: 'o'+'';
      optSpeed: ' -O3 ';
      optSize: ' -Os ';
      compilerExe: 'icc';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      linkerExe: 'icc';
      linkTmpl: '$options $buildgui $builddll -o $exefile $objfiles';
      includeCmd: ' -I';
      debug: '';
      pic: '-fPIC';
      asmStmtFrmt: 'asm($1);$n';
      props: {@set}[hasSwitchRange, hasComputedGoto, hasCpp];
    ), (
      name: 'gpp';
      objExt: 'o'+'';
      optSpeed: ' -O3 -ffast-math ';
      optSize: ' -Os -ffast-math ';
      compilerExe: 'g++';
      compileTmpl: '-c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      linkerExe: 'g++';
      linkTmpl: '$options $buildgui $builddll -o $exefile $objfiles';
      includeCmd: ' -I';
      debug: ' -g ';
      pic: '-fPIC';
      asmStmtFrmt: 'asm($1);$n';
      props: {@set}[hasSwitchRange, hasComputedGoto, hasCpp];
    )
  );

var
  ccompiler: TSystemCC = ccGcc; // the used compiler

const
  hExt = 'h'+'';

var
  cExt: string = 'c'+''; // extension of generated C/C++ files
  // (can be changed to .cpp later)

function completeCFilePath(const cfile: string;
  createSubDir: Boolean = true): string;

function getCompileCFileCmd(const cfilename: string;
                            isExternal: bool = false): string;

procedure addFileToCompile(const filename: string);
procedure addExternalFileToCompile(const filename: string);
procedure addFileToLink(const filename: string);

procedure addCompileOption(const option: string);
procedure addLinkOption(const option: string);

function toObjFile(const filenameWithoutExt: string): string;

procedure CallCCompiler(const projectFile: string);

procedure execExternalProgram(const cmd: string);

function NameToCC(const name: string): TSystemCC;

procedure initVars;

procedure setCC(const ccname: string);
procedure writeMapping(gSymbolMapping: PRope);

implementation

var
  toLink, toCompile, externalToCompile: TLinkedList;
  linkOptions: string = '';
  compileOptions: string = '';

  ccompilerpath: string = '';

procedure setCC(const ccname: string);
var
  i: TSystemCC;
begin
  linkOptions := '';
  ccompiler := nameToCC(ccname);
  if ccompiler = ccNone then rawMessage(errUnknownCcompiler, ccname);
  compileOptions := getConfigVar(CC[ccompiler].name + '.options.always');
  ccompilerpath := getConfigVar(CC[ccompiler].name + '.path');
  for i := low(CC) to high(CC) do undefSymbol(CC[i].name);
  defineSymbol(CC[ccompiler].name);
end;

procedure initVars;
var
  i: TSystemCC;
begin
  // we need to define the symbol here, because ``CC`` may have never been set!
  for i := low(CC) to high(CC) do undefSymbol(CC[i].name);
  defineSymbol(CC[ccompiler].name);
  if gCmd = cmdCompileToCpp then
    cExt := '.cpp';
  addCompileOption(getConfigVar(CC[ccompiler].name + '.options.always'));
  if length(ccompilerPath) = 0 then
    ccompilerpath := getConfigVar(CC[ccompiler].name + '.path');
end;

function completeCFilePath(const cfile: string;
  createSubDir: Boolean = true): string;
begin
  result := completeGeneratedFilePath(cfile, createSubDir);
end;

function NameToCC(const name: string): TSystemCC;
var
  i: TSystemCC;
begin
  for i := succ(ccNone) to high(TSystemCC) do
    if cmpIgnoreStyle(name, CC[i].name) = 0 then begin
      result := i; exit
    end;
  result := ccNone
end;

procedure addOpt(var dest: string; const src: string);
begin
  if (length(dest) = 0) or (dest[length(dest)-1+strStart] <> ' ') then
    add(dest, ' '+'');
  add(dest, src);
end;

procedure addCompileOption(const option: string);
begin
  if strutils.find(compileOptions, option, strStart) < strStart then
    addOpt(compileOptions, option)
end;

procedure addLinkOption(const option: string);
begin
  if find(linkOptions, option, strStart) < strStart then
    addOpt(linkOptions, option)
end;

function toObjFile(const filenameWithoutExt: string): string;
begin
  result := changeFileExt(filenameWithoutExt, cc[ccompiler].objExt)
end;

procedure addFileToCompile(const filename: string);
begin
  appendStr(toCompile, filename);
end;

procedure addExternalFileToCompile(const filename: string);
begin
  appendStr(externalToCompile, filename);
end;

procedure addFileToLink(const filename: string);
begin
  prependStr(toLink, filename); // BUGFIX
  //appendStr(toLink, filename);
end;

procedure execExternalProgram(const cmd: string);
begin
  if (optListCmd in gGlobalOptions) or (gVerbosity > 0) then
    MessageOut('Executing: ' +{&} nl +{&} cmd);
  if executeCommand(cmd) <> 0 then
    rawMessage(errExecutionOfProgramFailed);
end;

procedure generateScript(const projectFile: string; script: PRope);
var
  path, scriptname, name, ext: string;
begin
  splitPath(projectFile, path, scriptname);
  SplitFilename(scriptname, name, ext);
  name := appendFileExt('compile_' + name, platform.os[targetOS].scriptExt);
  WriteRope(script, joinPath(path, name));
end;

function getOptSpeed(c: TSystemCC): string;
begin
  result := getConfigVar(cc[c].name + '.options.speed');
  if result = '' then
    result := cc[c].optSpeed // use default settings from this file
end;

function getDebug(c: TSystemCC): string;
begin
  result := getConfigVar(cc[c].name + '.options.debug');
  if result = '' then
    result := cc[c].debug // use default settings from this file
end;

function getOptSize(c: TSystemCC): string;
begin
  result := getConfigVar(cc[c].name + '.options.size');
  if result = '' then
    result := cc[c].optSize // use default settings from this file
end;

const
  specialFileA = 42;
  specialFileB = 42;
var
  fileCounter: int;

function getCompileCFileCmd(const cfilename: string;
                            isExternal: bool = false): string;
var
  cfile, objfile, options, includeCmd, compilePattern, key, trunk, exe: string;
  c: TSystemCC; // an alias to ccompiler
begin
  c := ccompiler;
  options := compileOptions;
  trunk := getFileTrunk(cfilename);
  if optCDebug in gGlobalOptions then begin
    key := trunk + '.debug';
    if existsConfigVar(key) then
      addOpt(options, getConfigVar(key))
    else
      addOpt(options, getDebug(c))
  end;
  if (optOptimizeSpeed in gOptions) then begin
    //if ((fileCounter >= specialFileA) and (fileCounter <= specialFileB)) then
    key := trunk + '.speed';
    if existsConfigVar(key) then
      addOpt(options, getConfigVar(key))
    else
      addOpt(options, getOptSpeed(c))
  end
  else if optOptimizeSize in gOptions then begin
    key := trunk + '.size';
    if existsConfigVar(key) then
      addOpt(options, getConfigVar(key))
    else
      addOpt(options, getOptSize(c))
  end;
  key := trunk + '.always';
  if existsConfigVar(key) then
    addOpt(options, getConfigVar(key));

  exe := cc[c].compilerExe;
  key := cc[c].name + '.exe';
  if existsConfigVar(key) then
    exe := getConfigVar(key);
  if targetOS = osWindows then exe := appendFileExt(exe, 'exe');

  if (optGenDynLib in gGlobalOptions)
  and (ospNeedsPIC in platform.OS[targetOS].props) then
    add(options, ' ' + cc[c].pic);

  if targetOS = platform.hostOS then begin
    // compute include paths:
    includeCmd := cc[c].includeCmd; // this is more complex than needed, but
    // a workaround of a FPC bug...
    add(includeCmd, quoteIfContainsWhite(libpath));
    compilePattern := JoinPath(ccompilerpath, exe);
  end
  else begin
    includeCmd := '';
    compilePattern := cc[c].compilerExe
  end;
  if targetOS = platform.hostOS then
    cfile := cfilename
  else
    cfile := extractFileName(cfilename);

  if not isExternal or (targetOS <> platform.hostOS) then
    objfile := toObjFile(cfile)
  else
    objfile := completeCFilePath(toObjFile(cfile));
  cfile := quoteIfContainsWhite(AppendFileExt(cfile, cExt));
  objfile := quoteIfContainsWhite(objfile);
  
  result := quoteIfContainsWhite(format(compilePattern,
    ['file', cfile,
     'objfile', objfile,
     'options', options,
     'include', includeCmd,
     'nimrod', getPrefixDir(),
     'lib', libpath
    ]));
  add(result, ' ');
  add(result, format(cc[c].compileTmpl,
    ['file', cfile,
     'objfile', objfile,
     'options', options,
     'include', includeCmd,
     'nimrod', quoteIfContainsWhite(getPrefixDir()),
     'lib', quoteIfContainsWhite(libpath)
    ]));
end;

procedure CompileCFile(const list: TLinkedList;
                       var script: PRope; isExternal: Boolean);
var
  it: PStrEntry;
  compileCmd: string;
begin
  it := PStrEntry(list.head);
  while it <> nil do begin
    inc(fileCounter);
    // call the C compiler for the .c file:
    compileCmd := getCompileCFileCmd(it.data, isExternal);
    if not (optCompileOnly in gGlobalOptions) then
      execExternalProgram(compileCmd);
    if (optGenScript in gGlobalOptions) then begin
      app(script, compileCmd);
      app(script, tnl);
    end;
    it := PStrEntry(it.next);
  end;
end;

procedure CallCCompiler(const projectfile: string);
var
  it: PStrEntry;
  linkCmd, objfiles, exefile, buildgui, builddll, linkerExe: string;
  c: TSystemCC; // an alias to ccompiler
  script: PRope;
begin
  if (gGlobalOptions * [optCompileOnly, optGenScript] = [optCompileOnly]) then
    exit; // speed up that call if only compiling and no script shall be
  // generated
  if (toCompile.head = nil) and (externalToCompile.head = nil) then exit;
  fileCounter := 0;
  c := ccompiler;
  script := nil;
  CompileCFile(toCompile, script, false);
  CompileCFile(externalToCompile, script, true);

  if not (optNoLinking in gGlobalOptions) then begin
    // call the linker:
    linkerExe := getConfigVar(cc[c].name + '.linkerexe');
    if length(linkerExe) = 0 then linkerExe := cc[c].linkerExe;
    if targetOS = osWindows then linkerExe := appendFileExt(linkerExe, 'exe');

    if (platform.hostOS <> targetOS) then
      linkCmd := quoteIfContainsWhite(linkerExe)
    else
      linkCmd := quoteIfContainsWhite(JoinPath(ccompilerpath, linkerExe));

    if optGenDynLib in gGlobalOptions then
      buildDll := cc[c].buildDll
    else
      buildDll := '';
    if optGenGuiApp in gGlobalOptions then
      buildGui := cc[c].buildGui
    else
      buildGui := '';

    if optGenDynLib in gGlobalOptions then
      exefile := platform.os[targetOS].dllPrefix
    else
      exefile := '';
    if targetOS = platform.hostOS then
      add(exefile, projectFile)
    else
      add(exefile, extractFileName(projectFile));
    if optGenDynLib in gGlobalOptions then
      add(exefile, platform.os[targetOS].dllExt)
    else
      add(exefile, platform.os[targetOS].exeExt);
    exefile := quoteIfContainsWhite(exefile);

    it := PStrEntry(toLink.head);
    objfiles := '';
    while it <> nil do begin
      add(objfiles, ' '+'');
      if targetOS = platform.hostOS then
        add(objfiles, quoteIfContainsWhite(toObjfile(it.data)))
      else
        add(objfiles, quoteIfContainsWhite(
                            toObjfile(extractFileName(it.data))));
      it := PStrEntry(it.next);
    end;

    linkCmd := quoteIfContainsWhite(format(linkCmd, [
      'builddll', builddll,
      'buildgui', buildgui,
      'options', linkOptions,
      'objfiles', objfiles,
      'exefile', exefile,
      'nimrod', getPrefixDir(),
      'lib', libpath
    ]));
    add(linkCmd, ' ');
    add(linkCmd, format(cc[c].linkTmpl, [
      'builddll', builddll,
      'buildgui', buildgui,
      'options', linkOptions,
      'objfiles', objfiles,
      'exefile', exefile,
      'nimrod', quoteIfContainsWhite(getPrefixDir()),
      'lib', quoteIfContainsWhite(libpath)
    ]));

    if not (optCompileOnly in gGlobalOptions) then
      execExternalProgram(linkCmd);
  end // end if not noLinking
  else
    linkCmd := '';
  if (optGenScript in gGlobalOptions) then begin
    app(script, linkCmd);
    app(script, tnl);
    generateScript(projectFile, script)
  end
end;

function genMappingFiles(const list: TLinkedList): PRope;
var
  it: PStrEntry;
begin
  result := nil;
  it := PStrEntry(list.head);
  while it <> nil do begin
    appf(result, '--file:r"$1"$n', [toRope(AppendFileExt(it.data, cExt))]);
    it := PStrEntry(it.next);
  end;
end;

procedure writeMapping(gSymbolMapping: PRope);
var
  code: PRope;
begin
  if not (optGenMapping in gGlobalOptions) then exit;
  code := toRope('[C_Files]'+nl);
  app(code, genMappingFiles(toCompile));
  app(code, genMappingFiles(externalToCompile));
  appf(code, '[Symbols]$n$1', [gSymbolMapping]);
  WriteRope(code, joinPath(projectPath, 'mapping.txt'));
end;

end.
