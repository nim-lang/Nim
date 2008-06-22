//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ntime;

interface

{$include 'config.inc'}

uses
{$ifdef win32}
  windows,
{$else}
  sysutils,
  {$ifdef fpc}
    dos,
  {$endif}
{$endif}
  nsystem, strutils;

function DateAndClock: string;
// returns current date and time (format: YYYY-MM-DD Sec:Min:Hour)

function getDateStr: string;
function getClockStr: string;

implementation

{$ifdef mswindows}
function GetDateStr: string;
var
  st: SystemTime;
begin
  Windows.GetLocalTime({$ifdef fpc} @ {$endif} st);
  result := IntToStr(st.wYear, 4) + '-' + IntToStr(st.wMonth, 2) + '-'
    + IntToStr(st.wDay, 2)
end;

procedure GetDate(var Day, Month, Year: int);
var
  st: SystemTime;
begin
  Windows.GetLocalTime({$ifdef fpc} @ {$endif} st);
  Day := st.wDay;
  Month := st.wMonth;
  Year := st.wYear
end;

procedure GetTime(var Hours, Minutes, Seconds, Millisec: int);
var
  st: SystemTime;
begin
  Windows.GetLocalTime({$ifdef fpc} @ {$endif} st);
  Hours := st.wHour;
  Minutes := st.wMinute;
  Seconds := st.wSecond;
  Millisec := st.wMilliseconds
end;
{$else} // not windows
function GetDateStr: string;
var
  wMonth, wYear, wDay: Word;
begin
  SysUtils.DecodeDate(Date, wYear, wMonth, wDay);
  result := IntToStr(wYear, 4) + '-' + IntToStr(wMonth, 2) + '-'
    + IntToStr(wDay, 2)
end;

procedure GetDate(var Day, Month, Year: int);
var
  wMonth, wYear, wDay: Word;
begin
  SysUtils.DecodeDate(Date, wYear, wMonth, wDay);
  Day := wDay;
  Month := wMonth;
  Year := wYear
end;

procedure GetTime(var Hours, Minutes, Seconds, Millisec: int);
var
  wHour, wMin, wSec, wMSec: Word;
begin
  SysUtils.DecodeTime(Time, wHour, wMin, wSec, wMSec);
  Hours := wHour; Minutes := wMin; Seconds := wSec; Millisec := wMSec;
end;
{$endif}

function GetClockStr: string;
var
  Hour, Min, Sec, MSec: int;
begin
  GetTime(Hour, min, sec, msec);
  result := IntToStr(Hour, 2) + ':' + IntToStr(min, 2) + ':' + IntToStr(Sec, 2)
end;

function DateAndClock: string;
begin
  result := GetDateStr() + ' ' + getClockStr()
end;

end.

