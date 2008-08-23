//
//
//           The Nimrod Compiler
//        (c) Copyright 2006 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
program nimrod;

{$include 'config.inc'}
{@ignore}
{$ifdef windows}
{$apptype console}
{$endif}
{@emit}

uses
  nsystem,
  charsets, sysutils, commands, scanner, condsyms, options, msgs, nversion,
  nimconf, ropes, extccomp, strutils, nos, platform, main, parseopt;

var
  arguments: string = ''; // the arguments to be passed to the program that
                          // should be run
  cmdLineInfo: TLineInfo;

procedure ProcessCmdLine(pass: TCmdLinePass; var command, filename: string);
var
  p: TOptParser;
begin
  p := parseopt.init();
  while true do begin
    parseopt.next(p);
    case p.kind of
      cmdEnd: break;
      cmdLongOption, cmdShortOption:
        ProcessSwitch(p.key, p.val, pass, cmdLineInfo);
      cmdArgument: begin
        if command = '' then command := p.key
        else if filename = '' then begin
          filename := unixToNativePath(p.key);
          // BUGFIX for portable build scripts
          break
        end
      end
    end
  end;
  // collect the arguments:
  if pass = passCmd2 then begin
    arguments := getRestOfCommandLine(p);
    if not (optRun in gGlobalOptions) and (arguments <> '') then
      rawMessage(errArgsNeedRunOption);
  end
end;

procedure HandleCmdLine;
var
  command, filename: string;
begin
  if paramCount() = 0 then
    writeCommandLineUsage()
  else begin
    // Process command line arguments:
    command := '';
    filename := '';
    ProcessCmdLine(passCmd1, command, filename);
    if filename <> '' then begin
      if gCmd = cmdInterpret then DefineSymbol('interpreting');
      nimconf.LoadConfig(filename); // load the right config file
      // now process command line arguments again, because some options in the
      // command line can overwite the config file's settings
      extccomp.initVars();
      command := '';
      filename := '';
      ProcessCmdLine(passCmd2, command, filename);
    end;
    MainCommand(command, filename);
    if (gCmd <> cmdInterpret) and (msgs.gErrorCounter = 0) then
      rawMessage(hintSuccess);
    if optRun in gGlobalOptions then
      execExternalProgram(changeFileExt(filename, '') +{&} ' ' +{&} arguments)
  end
end;

begin
  cmdLineInfo := newLineInfo('command line', -1, -1);
  condsyms.InitDefines();
  HandleCmdLine();
  halt(options.gExitcode);
end.
