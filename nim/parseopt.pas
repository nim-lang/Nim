//
//
//            Nimrod's Runtime Library
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit parseopt;

// A command line parser; the Nimrod version of this file
// will become part of the standard library.

interface

{$include 'config.inc'}

uses
  nsystem, charsets, nos, strutils;

type
  TCmdLineKind = (
    cmdEnd,          // end of command line reached
    cmdArgument,     // argument detected
    cmdLongoption,   // a long option ``--option`` detected
    cmdShortOption   // a short option ``-c`` detected
  );
  TOptParser = object(NObject)
    cmd: string;
    pos: int;
    inShortState: bool;
    kind: TCmdLineKind;
    key, val: string;
  end;

function init(const cmdline: string = ''): TOptParser;
procedure next(var p: TOptParser);

function getRestOfCommandLine(const p: TOptParser): string;

implementation

function init(const cmdline: string = ''): TOptParser;
var
  i: int;
begin
  result.pos := strStart;
  result.inShortState := false;
  if cmdline <> '' then
    result.cmd := cmdline
  else begin
    result.cmd := '';
    for i := 1 to ParamCount() do
      result.cmd := result.cmd +{&} quoteIfContainsWhite(paramStr(i)) +{&} ' ';
  {@ignore}
    result.cmd := result.cmd + #0;
  {@emit}
  end;
  result.kind := cmdEnd;
  result.key := '';
  result.val := '';
end;

function parseWord(const s: string; const i: int; var w: string;
          const delim: TCharSet = {@set}[#9, ' ', #0]): int;
begin
  result := i;
  if s[result] = '"' then begin
    inc(result);
    while not (s[result] in [#0, '"']) do begin
      addChar(w, s[result]);
      inc(result);
    end;
    if s[result] = '"' then inc(result)
  end
  else begin
    while not (s[result] in delim) do begin
      addChar(w, s[result]);
      inc(result);
    end
  end
end;

procedure handleShortOption(var p: TOptParser);
var
  i: int;
begin
  i := p.pos;
  p.kind := cmdShortOption;
  addChar(p.key, p.cmd[i]);
  inc(i);
  p.inShortState := true;
  while p.cmd[i] in [#9, ' '] do begin
    inc(i);
    p.inShortState := false;
  end;
  if p.cmd[i] in [':', '='] then begin
    inc(i); p.inShortState := false;
    while p.cmd[i] in [#9, ' '] do inc(i);
    i := parseWord(p.cmd, i, p.val);
  end;
  if p.cmd[i] = #0 then p.inShortState := false;
  p.pos := i;
end;

procedure next(var p: TOptParser);
var
  i: int;
begin
  i := p.pos;
  while p.cmd[i] in [#9, ' '] do inc(i);
  p.pos := i;
  setLength(p.key, 0);
  setLength(p.val, 0);
  if p.inShortState then begin
    handleShortOption(p); exit
  end;
  case p.cmd[i] of
    #0: p.kind := cmdEnd;
    '-': begin
      inc(i);
      if p.cmd[i] = '-' then begin
        p.kind := cmdLongOption;
        inc(i);
        i := parseWord(p.cmd, i, p.key, {@set}[#0, ' ', #9, ':', '=']);
        while p.cmd[i] in [#9, ' '] do inc(i);
        if p.cmd[i] in [':', '='] then begin
          inc(i);
          while p.cmd[i] in [#9, ' '] do inc(i);
          p.pos := parseWord(p.cmd, i, p.val);
        end
        else
          p.pos := i;
      end
      else begin
        p.pos := i;
        handleShortOption(p)
      end
    end;
    else begin
      p.kind := cmdArgument;
      p.pos := parseWord(p.cmd, i, p.key);
    end
  end
end;

function getRestOfCommandLine(const p: TOptParser): string;
begin
  result := strip(ncopy(p.cmd, p.pos+strStart, length(p.cmd)-1))
  // always -1, because Pascal version uses a trailing zero here
end;

end.
