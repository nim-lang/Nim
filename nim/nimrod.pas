//
//
//           The Nimrod Compiler
//        (c) Copyright 2006 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
program nim;

{$include 'config.inc'}
{@ignore}
{$ifdef windows}
{$apptype console}
{$endif}
{@emit}

uses
  nsystem,
  charsets, sysutils, commands, scanner, condsyms, options, msgs, nversion,
  nimconf, ropes, extccomp, strutils, nos, platform, main;

var
  arguments: string = ''; // the arguments to be passed to the program that
                          // should be run

function ProcessCmdLine(pass: TCmdLinePass): string;
var
  i, paramCounter: int;
  param: string;
begin
  i := 1;
  result := '';
  paramCounter := paramCount();
  while i <= paramCounter do begin
    param := ParamStr(i);
    if param[strStart] = '-' then begin
      commands.ProcessCommand(param, pass);
    end
    else if i > 1 then begin
      result := unixToNativePath(param); // BUGFIX for portable build scripts
      options.compilerArgs := i;
      break // do not process the arguments
    end;
    Inc(i)
  end;
  inc(i); // skip program file
  // collect the arguments:
  if pass = passCmd2 then begin
    while i <= paramCounter do begin
      arguments := arguments + ' ' +{&} paramStr(i);
      inc(i)
    end;
    if not (optRun in gGlobalOptions) and (arguments <> '') then
      rawMessage(errArgsNeedRunOption);
  end
end;

procedure HandleCmdLine;
var
  inp: string;
begin
  if paramCount() = 0 then
    writeCommandLineUsage()
  else begin
    // Process command line arguments:
    inp := ProcessCmdLine(passCmd1);
    if inp <> '' then begin
      if gCmd = cmdInterpret then DefineSymbol('interpreting');
      nimconf.LoadConfig(inp); // load the right config file
      // now process command line arguments again, because some options in the
      // command line can overwite the config file's settings
      extccomp.initVars();
      inp := ProcessCmdLine(passCmd2);
    end;
    MainCommand(paramStr(1), inp);
    if (gCmd <> cmdInterpret) and (msgs.gErrorCounter = 0) then
      rawMessage(hintSuccess);
    if optRun in gGlobalOptions then
      execExternalProgram(changeFileExt(inp, '') +{&} arguments)
  end
end;

{@ignore}
var
  Saved8087CW: Word;
{@emit}
begin
{@ignore}
  Saved8087CW := Default8087CW;
  Set8087CW($133f); // Disable all fpu exceptions
{@emit}
  condsyms.InitDefines();
  HandleCmdLine();
{@ignore}
  Set8087CW(Saved8087CW);
{@emit}
  halt(options.gExitcode);
end.
