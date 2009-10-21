//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit commands;

// This module handles the parsing of command line arguments.

interface

{$include 'config.inc'}

uses
  nsystem, charsets, nos, msgs, options, nversion, condsyms, strutils, extccomp, 
  platform, lists, wordrecg;

procedure writeCommandLineUsage;

type
  TCmdLinePass = (
    passCmd1,                // first pass over the command line
    passCmd2,                // second pass over the command line
    passPP                   // preprocessor called ProcessCommand()
  );

procedure ProcessCommand(const switch: string; pass: TCmdLinePass);
procedure processSwitch(const switch, arg: string; pass: TCmdlinePass;
                        const info: TLineInfo);

implementation

{@ignore}
const
{$ifdef fpc}
  compileDate = {$I %date%};
{$else}
  compileDate = '2009-0-0';
{$endif}
{@emit}

const
  HelpMessage = 'Nimrod Compiler Version $1 (' +{&}
    compileDate +{&} ') [$2: $3]' +{&} nl +{&}
    'Copyright (c) 2004-2009 by Andreas Rumpf' +{&} nl;

const
  Usage = ''
//[[[cog
//from string import replace
//def f(x): return "+{&} '" + replace(x, "'", "''")[:-1] + "' +{&} nl"
//for line in open("data/basicopt.txt").readlines():
//  cog.outl(f(line))
//]]]
+{&} 'Usage::' +{&} nl
+{&} '  nimrod command [options] inputfile [arguments]' +{&} nl
+{&} 'Command::' +{&} nl
+{&} '  compile, c                compile project with default code generator (C)' +{&} nl
+{&} '  compile_to_c, cc          compile project with C code generator' +{&} nl
+{&} '  doc                       generate the documentation for inputfile' +{&} nl
+{&} '  rst2html                  converts a reStructuredText file to HTML' +{&} nl
+{&} '  rst2tex                   converts a reStructuredText file to TeX' +{&} nl
+{&} 'Arguments:' +{&} nl
+{&} '  arguments are passed to the program being run (if --run option is selected)' +{&} nl
+{&} 'Options:' +{&} nl
+{&} '  -p, --path:PATH           add path to search paths' +{&} nl
+{&} '  -o, --out:FILE            set the output filename' +{&} nl
+{&} '  -d, --define:SYMBOL       define a conditional symbol' +{&} nl
+{&} '  -u, --undef:SYMBOL        undefine a conditional symbol' +{&} nl
+{&} '  -f, --force_build         force rebuilding of all modules' +{&} nl
+{&} '  --symbol_files:on|off     use symbol files to speed up compilation (buggy!)' +{&} nl
+{&} '  --stack_trace:on|off      code generation for stack trace ON|OFF' +{&} nl
+{&} '  --line_trace:on|off       code generation for line trace ON|OFF' +{&} nl
+{&} '  --debugger:on|off         turn Embedded Nimrod Debugger ON|OFF' +{&} nl
+{&} '  -x, --checks:on|off       code generation for all runtime checks ON|OFF' +{&} nl
+{&} '  --obj_checks:on|off       code generation for obj conversion checks ON|OFF' +{&} nl
+{&} '  --field_checks:on|off     code generation for case variant fields ON|OFF' +{&} nl
+{&} '  --range_checks:on|off     code generation for range checks ON|OFF' +{&} nl
+{&} '  --bound_checks:on|off     code generation for bound checks ON|OFF' +{&} nl
+{&} '  --overflow_checks:on|off  code generation for over-/underflow checks ON|OFF' +{&} nl
+{&} '  -a, --assertions:on|off   code generation for assertions ON|OFF' +{&} nl
+{&} '  --dead_code_elim:on|off   whole program dead code elimination ON|OFF' +{&} nl
+{&} '  --opt:none|speed|size     optimize not at all or for speed|size' +{&} nl
+{&} '  --app:console|gui|lib     generate a console|GUI application|dynamic library' +{&} nl
+{&} '  -r, --run                 run the compiled program with given arguments' +{&} nl
+{&} '  --advanced                show advanced command line switches' +{&} nl
+{&} '  -h, --help                show this help' +{&} nl
//[[[end]]]
  ;

  AdvancedUsage = ''
//[[[cog
//for line in open("data/advopt.txt").readlines():
//  cog.outl(f(line))
//]]]
+{&} 'Advanced commands::' +{&} nl
+{&} '  pas                       convert a Pascal file to Nimrod syntax' +{&} nl
+{&} '  pretty                    pretty print the inputfile' +{&} nl
+{&} '  gen_depend                generate a DOT file containing the' +{&} nl
+{&} '                            module dependency graph' +{&} nl
+{&} '  list_def                  list all defined conditionals and exit' +{&} nl
+{&} '  check                     checks the project for syntax and semantic' +{&} nl
+{&} '  parse                     parses a single file (for debugging Nimrod)' +{&} nl
+{&} 'Advanced options:' +{&} nl
+{&} '  -w, --warnings:on|off     warnings ON|OFF' +{&} nl
+{&} '  --warning[X]:on|off       specific warning X ON|OFF' +{&} nl
+{&} '  --hints:on|off            hints ON|OFF' +{&} nl
+{&} '  --hint[X]:on|off          specific hint X ON|OFF' +{&} nl
+{&} '  --lib:PATH                set the system library path' +{&} nl
+{&} '  -c, --compile_only        compile only; do not assemble or link' +{&} nl
+{&} '  --no_linking              compile but do not link' +{&} nl
+{&} '  --no_main                 do not generate a main procedure' +{&} nl
+{&} '  --gen_script              generate a compile script (in the ''nimcache''' +{&} nl
+{&} '                            subdirectory named ''compile_$project$scriptext'')' +{&} nl
+{&} '  --os:SYMBOL               set the target operating system (cross-compilation)' +{&} nl
+{&} '  --cpu:SYMBOL              set the target processor (cross-compilation)' +{&} nl
+{&} '  --debuginfo               enables debug information' +{&} nl
+{&} '  -t, --passc:OPTION        pass an option to the C compiler' +{&} nl
+{&} '  -l, --passl:OPTION        pass an option to the linker' +{&} nl
+{&} '  --gen_mapping             generate a mapping file containing' +{&} nl
+{&} '                            (Nimrod, mangled) identifier pairs' +{&} nl
+{&} '  --line_dir:on|off         generation of #line directive ON|OFF' +{&} nl
+{&} '  --checkpoints:on|off      turn on|off checkpoints; for debugging Nimrod' +{&} nl
+{&} '  --skip_cfg                do not read the general configuration file' +{&} nl
+{&} '  --skip_proj_cfg           do not read the project''s configuration file' +{&} nl
+{&} '  --gc:refc|boehm|none      use Nimrod''s native GC|Boehm GC|no GC' +{&} nl
+{&} '  --index:FILE              use FILE to generate a documenation index file' +{&} nl
+{&} '  --putenv:key=value        set an environment variable' +{&} nl
+{&} '  --list_cmd                list the commands used to execute external programs' +{&} nl
+{&} '  --parallel_build=0|1|...  perform a parallel build' +{&} nl
+{&} '                            value = number of processors (0 for auto-detect)' +{&} nl
+{&} '  --verbosity:0|1|2|3       set Nimrod''s verbosity level (0 is default)' +{&} nl
+{&} '  -v, --version             show detailed version information' +{&} nl
//[[[end]]]
  ;

function getCommandLineDesc: string;
begin
  result := format(HelpMessage, [VersionAsString, 
    platform.os[platform.hostOS].name, cpu[platform.hostCPU].name]) +{&} Usage
end;

var
  helpWritten: boolean;  // BUGFIX 19
  versionWritten: boolean;
  advHelpWritten: boolean;

procedure HelpOnError(pass: TCmdLinePass);
begin
  if (pass = passCmd1) and not helpWritten then begin
    // BUGFIX 19
    MessageOut(getCommandLineDesc());
    helpWritten := true;
    halt(0);
  end
end;

procedure writeAdvancedUsage(pass: TCmdLinePass);
begin
  if (pass = passCmd1) and not advHelpWritten then begin
    // BUGFIX 19
    MessageOut(format(HelpMessage, [VersionAsString, 
                                    platform.os[platform.hostOS].name,
                                    cpu[platform.hostCPU].name]) +{&}
                                    AdvancedUsage);
    advHelpWritten := true;
    helpWritten := true;
    halt(0);
  end
end;

procedure writeVersionInfo(pass: TCmdLinePass);
begin
  if (pass = passCmd1) and not versionWritten then begin
    versionWritten := true;
    helpWritten := true;
    messageOut(format(HelpMessage, [VersionAsString, 
                                    platform.os[platform.hostOS].name,
                                    cpu[platform.hostCPU].name]))
  end
end;

procedure writeCommandLineUsage;
begin
  if not helpWritten then begin
    messageOut(getCommandLineDesc());
    helpWritten := true
  end
end;

procedure InvalidCmdLineOption(pass: TCmdLinePass; const switch: string;
                               const info: TLineInfo);
begin
  liMessage(info, errInvalidCmdLineOption, switch)
end;

procedure splitSwitch(const switch: string; out cmd, arg: string;
                      pass: TCmdLinePass; const info: TLineInfo);
var
  i: int;
begin
  cmd := '';
  i := strStart;
  if (i < length(switch)+strStart) and (switch[i] = '-') then inc(i);
  if (i < length(switch)+strStart) and (switch[i] = '-') then inc(i);
  while i < length(switch) + strStart do begin
    case switch[i] of
      'a'..'z', 'A'..'Z', '0'..'9', '_', '.':
        addChar(cmd, switch[i]);
      else break;
    end;
    inc(i);
  end;
  if i >= length(switch) + strStart then
    arg := ''
  else if switch[i] in [':', '=', '['] then
    arg := ncopy(switch, i + 1)
  else
    InvalidCmdLineOption(pass, switch, info)
end;

procedure ProcessOnOffSwitch(const op: TOptions; const arg: string;
                             pass: TCmdlinePass; const info: TLineInfo);
begin
  case whichKeyword(arg) of
    wOn:  gOptions := gOptions + op;
    wOff: gOptions := gOptions - op;
    else  liMessage(info, errOnOrOffExpectedButXFound, arg)
  end
end;

procedure ProcessOnOffSwitchG(const op: TGlobalOptions; const arg: string;
                              pass: TCmdlinePass; const info: TLineInfo);
begin
  case whichKeyword(arg) of
    wOn:  gGlobalOptions := gGlobalOptions + op;
    wOff: gGlobalOptions := gGlobalOptions - op;
    else  liMessage(info, errOnOrOffExpectedButXFound, arg)
  end
end;

procedure ExpectArg(const switch, arg: string; pass: TCmdLinePass;
                    const info: TLineInfo);
begin
  if (arg = '') then
    liMessage(info, errCmdLineArgExpected, switch)
end;

procedure ExpectNoArg(const switch, arg: string; pass: TCmdLinePass;
                      const info: TLineInfo);
begin
  if (arg <> '') then
    liMessage(info, errCmdLineNoArgExpected, switch)
end;

procedure ProcessSpecificNote(const arg: string; state: TSpecialWord;
                              pass: TCmdlinePass; const info: TLineInfo);
var
  i, x: int;
  n: TNoteKind;
  id: string;
begin
  id := '';
  // arg = "X]:on|off"
  i := strStart;
  n := hintMin;
  while (i < length(arg)+strStart) and (arg[i] <> ']') do begin
    addChar(id, arg[i]);
    inc(i)
  end;
  if (i < length(arg)+strStart) and (arg[i] = ']') then
    inc(i)
  else
    InvalidCmdLineOption(pass, arg, info);
  if (i < length(arg)+strStart) and (arg[i] in [':', '=']) then
    inc(i)
  else
    InvalidCmdLineOption(pass, arg, info);
  if state = wHint then begin
    x := findStr(msgs.HintsToStr, id);
    if x >= 0 then
      n := TNoteKind(x + ord(hintMin))
    else
      InvalidCmdLineOption(pass, arg, info)
  end
  else begin
    x := findStr(msgs.WarningsToStr, id);
    if x >= 0 then
      n := TNoteKind(x + ord(warnMin))
    else
      InvalidCmdLineOption(pass, arg, info)
  end;
  case whichKeyword(ncopy(arg, i)) of
    wOn: include(gNotes, n);
    wOff: exclude(gNotes, n);
    else liMessage(info, errOnOrOffExpectedButXFound, arg)
  end
end;

function processPath(const path: string): string;
begin
  result := UnixToNativePath(format(path,
    ['nimrod', getPrefixDir(), 'lib', libpath]))
end;

procedure processCompile(const filename: string);
var
  found, trunc, ext: string;
begin
  found := findFile(filename);
  if found = '' then found := filename;
  splitFilename(found, trunc, ext);
  extccomp.addExternalFileToCompile(trunc);
  extccomp.addFileToLink(completeCFilePath(trunc, false));
end;

procedure processSwitch(const switch, arg: string; pass: TCmdlinePass;
                        const info: TLineInfo);
var
  theOS: TSystemOS;
  cpu: TSystemCPU;
  key, val, path: string;
begin
  case whichKeyword(switch) of
    wPath, wP: begin
      expectArg(switch, arg, pass, info);
      path := processPath(arg);
      {@discard} lists.IncludeStr(options.searchPaths, path)
    end;
    wOut, wO: begin
      expectArg(switch, arg, pass, info);
      options.outFile := arg;
    end;
    wDefine, wD: begin
      expectArg(switch, arg, pass, info);
      DefineSymbol(arg)
    end;
    wUndef, wU: begin
      expectArg(switch, arg, pass, info);
      UndefSymbol(arg)
    end;
    wCompile: begin
      expectArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        processCompile(arg);
    end;
    wLink: begin
      expectArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        addFileToLink(arg);
    end;
    wDebuginfo: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optCDebug);
    end;
    wCompileOnly, wC: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optCompileOnly);
    end;
    wNoLinking: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optNoLinking);
    end;
    wNoMain: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optNoMain);    
    end;
    wForceBuild, wF: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optForceFullMake);
    end;
    wGC: begin
      expectArg(switch, arg, pass, info);
      case whichKeyword(arg) of
        wBoehm: begin
          include(gGlobalOptions, optBoehmGC);
          exclude(gGlobalOptions, optRefcGC);
          DefineSymbol('boehmgc');
        end;
        wRefc: begin
          exclude(gGlobalOptions, optBoehmGC);
          include(gGlobalOptions, optRefcGC)
        end;
        wNone: begin
          exclude(gGlobalOptions, optRefcGC);
          exclude(gGlobalOptions, optBoehmGC);
          defineSymbol('nogc');
        end
        else
          liMessage(info, errNoneBoehmRefcExpectedButXFound, arg)
      end
    end;
    wWarnings, wW: ProcessOnOffSwitch({@set}[optWarns], arg, pass, info);
    wWarning: ProcessSpecificNote(arg, wWarning, pass, info);
    wHint: ProcessSpecificNote(arg, wHint, pass, info);
    wHints: ProcessOnOffSwitch({@set}[optHints], arg, pass, info);
    wCheckpoints: ProcessOnOffSwitch({@set}[optCheckpoints], arg, pass, info);
    wStackTrace: ProcessOnOffSwitch({@set}[optStackTrace], arg, pass, info);
    wLineTrace: ProcessOnOffSwitch({@set}[optLineTrace], arg, pass, info);
    wDebugger: begin
      ProcessOnOffSwitch({@set}[optEndb], arg, pass, info);
      if optEndb in gOptions then
        DefineSymbol('endb')
      else
        UndefSymbol('endb')
    end;
    wProfiler: begin
      ProcessOnOffSwitch({@set}[optProfiler], arg, pass, info);
      if optProfiler in gOptions then DefineSymbol('profiler')
      else UndefSymbol('profiler')
    end;
    wChecks, wX: ProcessOnOffSwitch(checksOptions, arg, pass, info);
    wObjChecks: ProcessOnOffSwitch({@set}[optObjCheck], arg, pass, info);
    wFieldChecks: ProcessOnOffSwitch({@set}[optFieldCheck], arg, pass, info);
    wRangeChecks: ProcessOnOffSwitch({@set}[optRangeCheck], arg, pass, info);
    wBoundChecks: ProcessOnOffSwitch({@set}[optBoundsCheck], arg, pass, info);
    wOverflowChecks: ProcessOnOffSwitch({@set}[optOverflowCheck], arg, pass, info);
    wLineDir: ProcessOnOffSwitch({@set}[optLineDir], arg, pass, info);
    wAssertions, wA: ProcessOnOffSwitch({@set}[optAssert], arg, pass, info);
    wDeadCodeElim: ProcessOnOffSwitchG({@set}[optDeadCodeElim], arg, pass, info);
    wOpt: begin
      expectArg(switch, arg, pass, info);
      case whichKeyword(arg) of
        wSpeed: begin
          include(gOptions, optOptimizeSpeed);
          exclude(gOptions, optOptimizeSize)
        end;
        wSize: begin
          exclude(gOptions, optOptimizeSpeed);
          include(gOptions, optOptimizeSize)
        end;
        wNone: begin
          exclude(gOptions, optOptimizeSpeed);
          exclude(gOptions, optOptimizeSize)
        end
        else
          liMessage(info, errNoneSpeedOrSizeExpectedButXFound, arg)
      end
    end;
    wApp: begin
      expectArg(switch, arg, pass, info);
      case whichKeyword(arg) of
        wGui: begin
          include(gGlobalOptions, optGenGuiApp);
          defineSymbol('guiapp')
        end;
        wConsole:
          exclude(gGlobalOptions, optGenGuiApp);
        wLib: begin
          include(gGlobalOptions, optGenDynLib);
          exclude(gGlobalOptions, optGenGuiApp);
          defineSymbol('library')
        end;
        else
          liMessage(info, errGuiConsoleOrLibExpectedButXFound, arg)
      end
    end;
    wListDef: begin
      expectNoArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        condsyms.listSymbols();
    end;
    wPassC, wT: begin
      expectArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        extccomp.addCompileOption(arg)
    end;
    wPassL, wL: begin
      expectArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        extccomp.addLinkOption(arg)
    end;
    wIndex: begin
      expectArg(switch, arg, pass, info);
      if pass in {@set}[passCmd2, passPP] then
        gIndexFile := arg
    end;
    wImport: begin
      expectArg(switch, arg, pass, info);
      options.addImplicitMod(arg);
    end;
    wListCmd: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optListCmd);
    end;
    wGenMapping: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optGenMapping);
    end;
    wOS: begin
      expectArg(switch, arg, pass, info);
      if (pass = passCmd1) then begin
        theOS := platform.NameToOS(arg);
        if theOS = osNone then
          liMessage(info, errUnknownOS, arg);
        if theOS <> platform.hostOS then begin
          setTarget(theOS, targetCPU);
          include(gGlobalOptions, optCompileOnly);
          condsyms.InitDefines()
        end
      end
    end;
    wCPU: begin
      expectArg(switch, arg, pass, info);
      if (pass = passCmd1) then begin
        cpu := platform.NameToCPU(arg);
        if cpu = cpuNone then
          liMessage(info, errUnknownCPU, arg);
        if cpu <> platform.hostCPU then begin
          setTarget(targetOS, cpu);
          include(gGlobalOptions, optCompileOnly);
          condsyms.InitDefines()
        end
      end
    end;
    wRun, wR: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optRun);
    end;
    wVerbosity: begin
      expectArg(switch, arg, pass, info);
      gVerbosity := parseInt(arg);
    end;
    wParallelBuild: begin
      expectArg(switch, arg, pass, info);      
      gNumberOfProcessors := parseInt(arg);
    end;
    wVersion, wV: begin
      expectNoArg(switch, arg, pass, info);
      writeVersionInfo(pass);
    end;
    wAdvanced: begin
      expectNoArg(switch, arg, pass, info);
      writeAdvancedUsage(pass);
    end;
    wHelp, wH: begin
      expectNoArg(switch, arg, pass, info);
      helpOnError(pass);
    end;
    wSymbolFiles: ProcessOnOffSwitchG({@set}[optSymbolFiles], arg, pass, info);
    wSkipCfg: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optSkipConfigFile);
    end;
    wSkipProjCfg: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optSkipProjConfigFile);
    end;
    wGenScript: begin
      expectNoArg(switch, arg, pass, info);
      include(gGlobalOptions, optGenScript);
    end;
    wLib: begin
      expectArg(switch, arg, pass, info);
      libpath := processPath(arg)
    end;
    wPutEnv: begin
      expectArg(switch, arg, pass, info);
      splitSwitch(arg, key, val, pass, info);
      nos.putEnv(key, val);
    end;
    wCC: begin
      expectArg(switch, arg, pass, info);
      setCC(arg)
    end;
    else if strutils.find(switch, '.') >= strStart then
      options.setConfigVar(switch, arg)
    else
      InvalidCmdLineOption(pass, switch, info)
  end
end;

procedure ProcessCommand(const switch: string; pass: TCmdLinePass);
var
  cmd, arg: string;
  info: TLineInfo;
begin
  info := newLineInfo('command line', 1, 1);
  splitSwitch(switch, cmd, arg, pass, info);
  ProcessSwitch(cmd, arg, pass, info)
end;

end.
