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
  nimconf, msgs; // some things are read in from the configuration file

type
  TSystemCC = (ccNone, ccGcc, ccLLVM_Gcc, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc, 
               ccTcc, ccPcc, ccUcc, ccIcc, ccGpp);

  TInfoCCProp = ( // properties of the C compiler:
    hasSwitchRange,  // CC allows ranges in switch statements (GNU C extension)
    hasComputedGoto, // CC has computed goto (GNU C extension)
    hasCpp           // CC is/contains a C++ compiler
  );
  TInfoCCProps = set of TInfoCCProp;
  TInfoCC = record
    name: string;            // the short name of the compiler
    objExt: string;          // the compiler's object file extenstion
    optSpeed: string;        // the options for optimization for speed
    optSize: string;         // the options for optimization for size
    compile: string;         // the compile command template
    buildGui: string;        // command to build a GUI application
    buildDll: string;        // command to build a shared library
    link: string;            // command to link files to produce an executable
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
      compile: 'gcc -c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      link: 'gcc $options $buildgui $builddll -o $exefile $objfiles';
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
      compile: 'llvm-gcc -c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      link: 'llvm-gcc $options $buildgui $builddll -o $exefile $objfiles';
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
      compile: 'lcc -e1 $options $include -Fo$objfile $file';
      buildGui: ' -subsystem windows';
      buildDll: ' -dll';
      link: 'lcclnk $options $buildgui $builddll -O $exefile $objfiles';
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
      compile: 'bcc32 -c $options $include -o$objfile $file';
      buildGui: ' -tW';
      buildDll: ' -tWD';
      link: 'bcc32 $options $buildgui $builddll -e$exefile $objfiles';
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
      compile: 'dmc -c $options $include -o$objfile $file';
      buildGui: ' -L/exet:nt/su:windows';
      buildDll: ' -WD';
      link: 'dmc $options $buildgui $builddll -o$exefile $objfiles';
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
      compile: 'wcl386 -c $options $include -fo=$objfile $file';
      buildGui: ' -bw';
      buildDll: ' -bd';
      link: 'wcl386 $options $buildgui $builddll -fe=$exefile $objfiles ';
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
      compile: 'cl /c $options $include /Fo$objfile $file';
      buildGui: ' /link /SUBSYSTEM:WINDOWS ';
      buildDll: ' /LD';
      link: 'cl $options $builddll /Fe$exefile $objfiles $buildgui';
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
      compile: 'tcc -c $options $include -o $objfile $file';
      buildGui: 'UNAVAILABLE!';
      buildDll: ' -shared';
      link: 'tcc -o $exefile $options $buildgui $builddll $objfiles';
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
      compile: 'cc -c $options $include -Fo$objfile $file';
      buildGui: ' -SUBSYSTEM:WINDOWS';
      buildDll: ' -DLL';
      link: 'cc $options $buildgui $builddll -OUT:$exefile $objfiles';
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
      compile: 'cc -c $options $include -o $objfile $file';
      buildGui: '';
      buildDll: ' -shared ';
      link: 'cc -o $exefile $options $buildgui $builddll $objfiles';
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
      compile: 'icc -c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      link: 'icc $options $buildgui $builddll -o $exefile $objfiles';
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
      compile: 'g++ -c $options $include -o $objfile $file';
      buildGui: ' -mwindows';
      buildDll: ' -mdll';
      link: 'g++ $options $buildgui $builddll -o $exefile $objfiles';
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

implementation

uses
  nsystem, charsets,
  lists, options, ropes, nos, strutils, platform, condsyms;

var
  toLink, toCompile, externalToCompile: TLinkedList;
  linkOptions: string = '';
  compileOptions: string = '';

  ccompilerpath: string = '';

procedure initVars;
begin
  // BUGFIX: '.' forgotten
  compileOptions := getConfigVar(CC[ccompiler].name + '.options.always');
  // have the variables not been initialized?
  ccompilerpath := getConfigVar(CC[ccompiler].name + '.path');
  // we need to define the symbol here, because ``CC`` may have never been set!
  setCC(CC[ccompiler].name);
  if gCmd = cmdCompileToCpp then
    cExt := '.cpp';
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


procedure setCC(const ccname: string);
var
  i: TSystemCC;
begin
  ccompiler := nameToCC(ccname);
  if ccompiler = ccNone then
    rawMessage(errUnknownCcompiler, ccname);
  for i := low(CC) to high(CC) do
    undefSymbol(CC[i].name);
  defineSymbol(CC[ccompiler].name)
end;

procedure addCompileOption(const option: string);
begin
  if strutils.findSubStr(option, compileOptions, strStart) < strStart then
    compileOptions := compileOptions + ' ' +{&} option
end;

procedure addLinkOption(const option: string);
begin
  if findSubStr(option, linkOptions, strStart) < strStart then
    linkOptions := linkOptions + ' ' +{&} option
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
  if optListCmd in gGlobalOptions then
    MessageOut('Executing: ' +{&} nl +{&} cmd);
  if ExecuteProcess(cmd) <> 0 then
    rawMessage(errExecutionOfProgramFailed);
end;

procedure generateScript(const projectFile: string; script: PRope);
var
  path, scriptname, name, ext: string;
begin
  splitPath(projectFile, path, scriptname);
  SplitFilename(scriptname, name, ext);
  name := appendFileExt('compile_' + name, platform.os[targetOS].scriptExt);
  WriteRope(script, joinPath([path, genSubDir, name]));
end;

procedure addStr(var dest: string; const src: string);
begin
  dest := dest +{&} src;
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

procedure CompileCFile(const list: TLinkedList;
                       var script: PRope; isExternal: Boolean);
var
  it: PStrEntry;
  compileCmd, cfile, objfile, options, includeCmd, compilePattern: string;
  c: TSystemCC; // an alias to ccompiler
begin
  c := ccompiler;
  it := PStrEntry(list.head);

  options := compileOptions;
  if optCDebug in gGlobalOptions then addStr(options, ' ' + getDebug(c));
  if optOptimizeSpeed in gOptions then addStr(options, ' ' + getOptSpeed(c))
  else if optOptimizeSize in gOptions then addStr(options, ' ' + getOptSize(c));

  if (optGenDynLib in gGlobalOptions)
  and (ospNeedsPIC in platform.OS[targetOS].props) then
    addStr(options, ' ' + cc[c].pic);

  if targetOS = hostOS then begin
    // compute include paths:
    includeCmd := cc[c].includeCmd; // this is more complex than needed, but
    // a workaround of a FPC bug...
    addStr(includeCmd, libpath);
    compilePattern := JoinPath(ccompilerpath, cc[c].compile);
  end
  else begin
    includeCmd := '';
    compilePattern := cc[c].compile
  end;

  while it <> nil do begin
    // call the C compiler for the .c file:
    if targetOS = hostOS then
      cfile := it.data
    else
      cfile := extractFileName(it.data);

    if not isExternal or (targetOS <> hostOS) then
      objfile := toObjFile(cfile)
    else
      objfile := completeCFilePath(toObjFile(cfile));

    compileCmd := format(compilePattern,
      ['file', AppendFileExt(cfile, cExt),
       'objfile', objfile,
       'options', options,
       'include', includeCmd
      ]);
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
  linkCmd, objfiles, exefile, buildgui, builddll: string;
  c: TSystemCC; // an alias to ccompiler
  script: PRope;
begin
  if (gGlobalOptions * [optCompileOnly, optGenScript] = [optCompileOnly]) then
    exit; // speed up that call if only compiling and no script shall be
  // generated
  initVars();
  if (toCompile.head = nil) and (externalToCompile.head = nil) then exit;
  //initVars();
  c := ccompiler;
  script := nil;
  CompileCFile(toCompile, script, false);
  CompileCFile(externalToCompile, script, true);

  if not (optNoLinking in gGlobalOptions) then begin
    // call the linker:
    if (hostOS <> targetOS) then
      linkCmd := cc[c].link
    else
      linkCmd := JoinPath(ccompilerpath, cc[c].link);

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
    if targetOS = hostOS then
      addStr(exefile, projectFile)
    else
      addStr(exefile, extractFileName(projectFile));
    if optGenDynLib in gGlobalOptions then
      addStr(exefile, platform.os[targetOS].dllExt)
    else
      addStr(exefile, platform.os[targetOS].exeExt);

    it := PStrEntry(toLink.head);
    objfiles := '';
    while it <> nil do begin
      addStr(objfiles, ' '+'');
      if targetOS = hostOS then
        addStr(objfiles, toObjfile(it.data))
      else
        addStr(objfiles, toObjfile(extractFileName(it.data)));
      it := PStrEntry(it.next);
    end;

    linkCmd := format(linkCmd, [
      'builddll', builddll,
      'buildgui', buildgui,
      'options', linkOptions,
      'objfiles', objfiles,
      'exefile', exefile
    ]);
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

end.
