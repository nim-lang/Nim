//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit osproc;

// This module provides Nimrod's osproc module in Pascal
// Note: Only implement what is really needed here!

interface

{$include 'config.inc'}

uses
  nsystem, nos;

type
  TProcessOption = (poEchoCmd, poUseShell, poStdErrToStdOut, poParentStreams);
  TProcessOptions = set of TProcessOption;

function execCmd(const cmd: string): int;
function execProcesses(const cmds: array of string;
                       options: TProcessOptions;
                       n: int): int;

function countProcessors(): int;

implementation

function execCmd(const cmd: string): int;
begin
  writeln(output, cmd);
  result := executeShellCommand(cmd);
end;

function execProcesses(const cmds: array of string;
                       options: TProcessOptions;
                       n: int): int;
var
  i: int;
begin
  result := 0;
  for i := 0 to high(cmds) do begin
    //if poEchoCmd in options then writeln(output, cmds[i]);
    result := max(result, execCmd(cmds[i]))
  end
end;

function countProcessors(): int;
begin
  result := 1;
end;

end.
