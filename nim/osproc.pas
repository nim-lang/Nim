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

function executeCommand(const cmd: string): int;

implementation

function executeCommand(const cmd: string): int;
begin
  result := executeShellCommand(cmd);
end;

end.
