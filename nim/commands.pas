//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module handles the parsing of command line arguments.

unit commands;

interface

{$include 'config.inc'}

uses
  nsystem, charsets, msgs;

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

uses
  options, nversion, condsyms, strutils, extccomp, platform, nos, lists,
  wordrecg;

{@ignore}
const
{$ifdef fpc}
  compileDate = {$I %date%};
  compileTime = {$I %time%};
{$else}
  compileDate = '2008-0-0';
  compileTime = '00:00:00';
{$endif}
{@emit}

const
  HelpMessage = 'Nimrod Compiler Version $1 (' +{&}
    compileDate +{&} ' ' +{&} compileTime +{&} ') [$2: $3]' +{&} nl +{&}
    'Copyright (c) 2004-2008 by Andreas Rumpf' +{&} nl;

const
  Usage = ''
//[[[cog
//def f(x): return "+{&} '" + x.replace("'", "''")[:-1] + "' +{&} nl"
//for line in file("data/basicopt.txt"):
//  cog.outl(f(line))
//]]]
+{&} 'Usage::' +{&} nl
+{&} '  nimrod command [options] inputfile [arguments]' +{&} nl
+{&} 'Command::' +{&} nl
+{&} '  compile                   compile project with default code generator (C)' +{&} nl
+{&} '  compile_to_c              compile project with C code generator' +{&} nl
+{&} '  compile_to_cpp            compile project with C++ code generator' +{&} nl
+{&} '  doc                       generate the documentation for inputfile; ' +{&} nl
+{&} '                            with --run switch opens it with $BROWSER' +{&} nl
+{&} 'Arguments:' +{&} nl
+{&} '  arguments are passed to the program being run (if --run option is selected)' +{&} nl
+{&} 'Options:' +{&} nl
+{&} '  -p, --path:PATH           add path to search paths' +{&} nl
+{&} '  -o, --out:FILE            set the output filename' +{&} nl
+{&} '  -d, --define:SYMBOL       define a conditional symbol' +{&} nl
+{&} '  -u, --undef:SYMBOL        undefine a conditional symbol' +{&} nl
+{&} '  -b, --force_build         force rebuilding of all modules' +{&} nl
+{&} '  --stack_trace:on|off      code generation for stack trace ON|OFF' +{&} nl
+{&} '  --line_trace:on|off       code generation for line trace ON|OFF' +{&} nl
+{&} '  --debugger:on|off         turn Embedded Nimrod Debugger ON|OFF' +{&} nl
+{&} '  -x, --checks:on|off       code generation for all runtime checks ON|OFF' +{&} nl
+{&} '  --range_checks:on|off     code generation for range checks ON|OFF' +{&} nl
+{&} '  --bound_checks:on|off     code generation for bound checks ON|OFF' +{&} nl
+{&} '  --overflow_checks:on|off  code generation for over-/underflow checks ON|OFF' +{&} nl
+{&} '  -a, --assertions:on|off   code generation for assertions ON|OFF' +{&} nl
+{&} '  --opt:none|speed|size     optimize not at all or for speed|size' +{&} nl
+{&} '  --app:console|gui|lib     generate a console|GUI application or a shared lib' +{&} nl
+{&} '  -r, --run                 run the compiled program with given arguments' +{&} nl
+{&} '  --advanced                show advanced command line switches' +{&} nl
+{&} '  -h, --help                show this help' +{&} nl
//[[[end]]]
  ;

  AdvancedUsage = ''
//[[[cog
//for line in file("data/advopt.txt"):
//  cog.outl(f(line))
//]]]
+{&} 'Advanced commands::' +{&} nl
+{&} '  pas                       convert a Pascal file to Nimrod standard syntax' +{&} nl
+{&} '  pretty                    pretty print the inputfile' +{&} nl
+{&} '  gen_depend                generate a DOT file containing the' +{&} nl
+{&} '                            module dependency graph' +{&} nl
+{&} '  list_def                  list all defined conditionals and exit' +{&} nl
+{&} '  rst2html                  converts a reStructuredText file to HTML' +{&} nl
+{&} '  check                     checks the project for syntax and semantic' +{&} nl
+{&} '  parse                     parses a single file (for debugging Nimrod)' +{&} nl
+{&} '  scan                      tokenizes a single file (for debugging Nimrod)' +{&} nl
+{&} '  debugtrans                for debugging the transformation pass' +{&} nl
+{&} 'Advanced options:' +{&} nl
+{&} '  -w, --warnings:on|off     warnings ON|OFF' +{&} nl
+{&} '  --warning[X]:on|off       specific warning X ON|OFF' +{&} nl
+{&} '  --hints:on|off            hints ON|OFF' +{&} nl
+{&} '  --hint[X]:on|off          specific hint X ON|OFF' +{&} nl
+{&} '  --cc:C_COMPILER           set the C/C++ compiler to use' +{&} nl
+{&} '  --lib:PATH                set the system library path' +{&} nl
+{&} '  -c, --compile_only        compile only; do not assemble or link' +{&} nl
+{&} '  --no_linking              compile but do not link' +{&} nl
+{&} '  --gen_script              generate a compile script (in the ''rod_gen''' +{&} nl
+{&} '                            subdirectory named ''compile_$project$scriptext'')' +{&} nl
+{&} '  --os:SYMBOL               set the target operating system (cross-compilation)' +{&} nl
+{&} '  --cpu:SYMBOL              set the target processor (cross-compilation)' +{&} nl
+{&} '  --debuginfo               enables debug information' +{&} nl
+{&} '  -t, --passc:OPTION        pass an option to the C compiler' +{&} nl
+{&} '  -l, --passl:OPTION        pass an option to the linker' +{&} nl
+{&} '  --gen_mapping             generate a mapping file containing' +{&} nl
+{&} '                            (Nimrod, mangled) identifier pairs' +{&} nl
+{&} '  --merge_output            generate only one C output file' +{&} nl
+{&} '  --line_dir:on|off         generation of #line directive ON|OFF' +{&} nl
+{&} '  --checkpoints:on|off      turn on|off checkpoints; for debugging Nimrod' +{&} nl
+{&} '  --skip_cfg                do not read the general configuration file' +{&} nl
+{&} '  --skip_proj_cfg           do not read the project''s configuration file' +{&} nl
+{&} '  --import:MODULE_FILE      import the given module implicitly for each module' +{&} nl
+{&} '  --maxerr:NUMBER           stop compilation after NUMBER errors; broken!' +{&} nl
+{&} '  --ast_cache:on|off        caching of ASTs ON|OFF (default: OFF)' +{&} nl
+{&} '  --c_file_cache:on|off     caching of generated C files ON|OFF (default: OFF)' +{&} nl
+{&} '  --index:FILE              use FILE to generate a documenation index file' +{&} nl
+{&} '  --putenv:key=value        set an environment variable' +{&} nl
+{&} '  --list_cmd                list the commands used to execute external programs' +{&} nl
+{&} '  -v, --verbose             show what Nimrod is doing' +{&} nl
+{&} '  --version                 show detailed version information' +{&} nl
//[[[end]]]
  ;

  VersionInformation = ''
//[[[cog
//for line in file("data/changes.txt"):
//  cog.outl(f(line))
//]]]
+{&} '0.1.0' +{&} nl
+{&} '* new config system' +{&} nl
+{&} '* new build system' +{&} nl
+{&} '* source renderer' +{&} nl
+{&} '* pas2nim integrated' +{&} nl
+{&} '* support for C++' +{&} nl
+{&} '* local variables are always initialized' +{&} nl
+{&} '* Rod file reader and writer' +{&} nl
+{&} '* new --out, -o command line options' +{&} nl
+{&} '* fixed bug in nimconf.pas: we now have several' +{&} nl
+{&} '  string token types' +{&} nl
+{&} '* changed nkIdentDef to nkIdentDefs' +{&} nl
+{&} '* added type(expr) in the parser and the grammer' +{&} nl
+{&} '* added template' +{&} nl
+{&} '* added command calls' +{&} nl
+{&} '* added case in records/objects' +{&} nl
+{&} '* added --skip_proj_cfg switch for nim.dpr' +{&} nl
+{&} '* added missing features to pasparse' +{&} nl
+{&} '* rewrote the source generator' +{&} nl
+{&} '* ``addr`` and ``cast`` are now keywords; grammar updated' +{&} nl
+{&} '* implemented ` notation; grammar updated' +{&} nl
+{&} '* specification replaced by a manual' +{&} nl
//[[[end]]]
  ;

function getCommandLineDesc: string;
var
  v: string;
begin
  // the Pascal version number gets a little star ('*'), the Nimrod version
  // does not! This helps distinguishing the different builds.
{@ignore}
  v := VersionAsString +{&} '*';
{@emit
  v := VersionAsString
}
  result := format(HelpMessage, [v, platform.os[hostOS].name,
    cpu[hostCPU].name]) +{&} Usage
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
    helpWritten := true
  end
end;

procedure writeAdvancedUsage(pass: TCmdLinePass);
begin
  if (pass = passCmd1) and not advHelpWritten then begin
    // BUGFIX 19
    MessageOut(format(HelpMessage, [VersionAsString, platform.os[hostOS].name,
                                    cpu[hostCPU].name]) +{&} AdvancedUsage);
    advHelpWritten := true;
    helpWritten := true;
  end
end;

procedure writeVersionInfo(pass: TCmdLinePass);
begin
  if (pass = passCmd1) and not versionWritten then begin
    versionWritten := true;
    helpWritten := true;
    messageOut(format(HelpMessage, [VersionAsString, platform.os[hostOS].name,
                             cpu[hostCPU].name]) +{&} VersionInformation)
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
    wDebuginfo:
      include(gGlobalOptions, optCDebug);
    wCompileOnly, wC:
      include(gGlobalOptions, optCompileOnly);
    wNoLinking:
      include(gGlobalOptions, optNoLinking);
    wForceBuild, wF:
      include(gGlobalOptions, optForceFullMake);
    wGC: begin
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
    wWarnings, wW:
      ProcessOnOffSwitch({@set}[optWarns], arg, pass, info);
    wWarning:
      ProcessSpecificNote(arg, wWarning, pass, info);
    wHint:
      ProcessSpecificNote(arg, wHint, pass, info);
    wHints:
      ProcessOnOffSwitch({@set}[optHints], arg, pass, info);
    wCheckpoints:
      ProcessOnOffSwitch({@set}[optCheckpoints], arg, pass, info);
    wStackTrace, wS:
      ProcessOnOffSwitch({@set}[optStackTrace], arg, pass, info);
    wLineTrace:
      ProcessOnOffSwitch({@set}[optLineTrace], arg, pass, info);
    wDebugger: begin
      ProcessOnOffSwitch({@set}[optEndb], arg, pass, info);
      if optEndb in gOptions then
        DefineSymbol('endb')
      else
        UndefSymbol('endb')
    end;
    wChecks, wX:
      ProcessOnOffSwitch(checksOptions, arg, pass, info);
    wRangeChecks:
      ProcessOnOffSwitch({@set}[optRangeCheck], arg, pass, info);
    wBoundChecks:
      ProcessOnOffSwitch({@set}[optBoundsCheck], arg, pass, info);
    wOverflowChecks:
      ProcessOnOffSwitch({@set}[optOverflowCheck], arg, pass, info);
    wLineDir:
      ProcessOnOffSwitch({@set}[optLineDir], arg, pass, info);
    wAssertions, wA:
      ProcessOnOffSwitch({@set}[optAssert], arg, pass, info);
    wCFileCache:
      ProcessOnOffSwitchG({@set}[optCFileCache], arg, pass, info);
    wAstCache:
      ProcessOnOffSwitchG({@set}[optAstCache], arg, pass, info);
    wOpt: begin
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
    wListCmd:
      include(gGlobalOptions, optListCmd);
    wGenMapping:
      include(gGlobalOptions, optGenMapping);
    wOS: begin
      if (pass = passCmd1) then begin
        theOS := platform.NameToOS(arg);
        if theOS = osNone then
          liMessage(info, errUnknownOS, arg);
        if theOS <> hostOS then begin
          setTarget(theOS, targetCPU);
          include(gGlobalOptions, optCompileOnly);
          condsyms.InitDefines()
        end
      end
    end;
    wCPU: begin
      if (pass = passCmd1) then begin
        cpu := platform.NameToCPU(arg);
        if cpu = cpuNone then
          liMessage(info, errUnknownCPU, arg);
        if cpu <> hostCPU then begin
          setTarget(targetOS, cpu);
          include(gGlobalOptions, optCompileOnly);
          condsyms.InitDefines()
        end
      end
    end;
    wRun, wR:
      include(gGlobalOptions, optRun);
    wVerbose, wV:
      include(gGlobalOptions, optVerbose);
    wMergeOutput:
      include(gGlobalOptions, optMergeOutput);
    wVersion:
      writeVersionInfo(pass);
    wAdvanced:
      writeAdvancedUsage(pass);
    wHelp, wH:
      helpOnError(pass);
    wCompileSys:
      include(gGlobalOptions, optCompileSys);
    wSkipCfg:
      include(gGlobalOptions, optSkipConfigFile);
    wSkipProjCfg:
      include(gGlobalOptions, optSkipProjConfigFile);
    wGenScript:
      include(gGlobalOptions, optGenScript);
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
    wMaxErr: begin
      expectArg(switch, arg, pass, info);
      gErrorMax := parseInt(arg);
    end;
    else if findSubStr('.', switch) >= strStart then
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
