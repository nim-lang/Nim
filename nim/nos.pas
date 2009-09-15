//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit nos;

// This module provides Nimrod's os module in Pascal
// Note: Only implement what is really needed here!

interface

{$include 'config.inc'}

uses
  sysutils,
{$ifdef mswindows}
  windows,
{$else}
  dos,
  unix,
{$endif}
  strutils,
  nsystem;

type
  EOSError = class(exception)
  end;

const
  curdir = '.';
{$ifdef mswindows}
  dirsep = '\'; // seperator within paths
  altsep = '/';
  exeExt = 'exe';
{$else}
  dirsep = '/';
  altsep = #0; // work around fpc bug
  exeExt = '';
{$endif}
  pathSep = ';'; // seperator between paths
  sep = dirsep; // alternative name
  extsep = '.';

function executeShellCommand(const cmd: string): int;
// like exec, but gets a command

function FileNewer(const a, b: string): Boolean;
// returns true if file a is newer than file b
// i.e. a was modified before b
// if a or b does not exist returns false

function getEnv(const name: string): string;
procedure putEnv(const name, val: string);

function JoinPath(const head, tail: string): string; overload;
function JoinPath(const parts: array of string): string; overload;

procedure SplitPath(const path: string; out head, tail: string);

function extractDir(const f: string): string;
function extractFilename(const f: string): string;

function getApplicationDir(): string;
function getApplicationFilename(): string;

function getCurrentDir: string;
function GetConfigDir(): string;


procedure SplitFilename(const filename: string; out name, extension: string);

function ExistsFile(const filename: string): Boolean;
function AppendFileExt(const filename, ext: string): string;
function ChangeFileExt(const filename, ext: string): string;

procedure createDir(const dir: string);
function expandFilename(filename: string): string;

function UnixToNativePath(const path: string): string;

function sameFile(const path1, path2: string): boolean;

implementation

function GetConfigDir(): string;
begin
{$ifdef windows}
  result := getEnv('APPDATA') + '\';
{$else}
  result := getEnv('HOME') + '/.config/';
{$endif}
end;

function getCurrentDir: string;
begin
  result := sysutils.GetCurrentDir();
end;

function UnixToNativePath(const path: string): string;
begin
  if dirSep <> '/' then
    result := replaceStr(path, '/', dirSep)
  else
    result := path;
end;

function expandFilename(filename: string): string;
begin
  result := sysutils.expandFilename(filename)
end;

function sameFile(const path1, path2: string): boolean;
begin
  result := cmpIgnoreCase(expandFilename(UnixToNativePath(path1)),
                          expandFilename(UnixToNativePath(path2))) = 0;
end;

procedure createDir(const dir: string);
var
  i: int;
begin
  for i := 2 to length(dir) do begin
    if dir[i] in [sep, altsep] then sysutils.createDir(ncopy(dir, 1, i-1));
  end;
  sysutils.createDir(dir);
end;

function searchExtPos(const s: string): int;
var
  i: int;
begin
  result := -1;
  for i := length(s) downto 1 do
    if s[i] = extsep then begin
      result := i;
      break
    end
    else if s[i] in [dirsep, altsep] then break
end;

function normExt(const ext: string): string;
begin
  if (ext = '') or (ext[1] = extSep) then
    result := ext // no copy needed here
  else
    result := extSep + ext
end;

function AppendFileExt(const filename, ext: string): string;
var
  extPos: int;
begin
  extPos := searchExtPos(filename);
  if extPos < 0 then
    result := filename + normExt(ext)
  else
    result := filename
end;

function ChangeFileExt(const filename, ext: string): string;
var
  extPos: int;
begin
  extPos := searchExtPos(filename);
  if extPos < 0 then
    result := filename + normExt(ext)
  else
    result := ncopy(filename, strStart, extPos-1) + normExt(ext)
end;

procedure SplitFilename(const filename: string; out name, extension: string);
var
  extPos: int;
begin
  extPos := searchExtPos(filename);
  if extPos > 0 then begin
    name := ncopy(filename, 1, extPos-1);
    extension := ncopy(filename, extPos);
  end
  else begin
    name := filename;
    extension := ''
  end
end;

procedure SplitPath(const path: string; out head, tail: string);
var
  sepPos, i: int;
begin
  sepPos := 0;
  for i := length(path) downto 1 do
    if path[i] in [sep, altsep] then begin
      sepPos := i;
      break
    end;
  if sepPos > 0 then begin
    head := ncopy(path, 1, sepPos-1);
    tail := ncopy(path, sepPos+1)
  end
  else begin
    head := '';
    tail := path
  end
end;

function getApplicationFilename(): string;
{$ifdef darwin}
var
  tail: string;
  p: int;
  paths: TStringSeq;
begin
  // little heuristic that may works on Mac OS X:
  result := ParamStr(0); // POSIX guaranties that this contains the executable
                         // as it has been executed by the calling process
  if (length(result) > 0) and (result[1] <> '/') then begin
    // not an absolute path?
    // iterate over any path in the $PATH environment variable
    paths := split(getEnv('PATH'), [':']);
    for p := 0 to high(paths) do begin
      tail := joinPath(paths[p], result);
      if ExistsFile(tail) then begin result := tail; exit end
    end
  end
end;
{$else}
begin
  result := ParamStr(0);
end;
{$endif}

function getApplicationDir(): string;
begin
  result := extractDir(getApplicationFilename());
end;

function extractDir(const f: string): string;
var
  tail: string;
begin
  SplitPath(f, result, tail)
end;

function extractFilename(const f: string): string;
var
  head: string;
begin
  SplitPath(f, head, result);
end;

function JoinPath(const head, tail: string): string;
begin
  if head = '' then
    result := tail
  else if head[length(head)] in [sep, altsep] then
    if (tail <> '') and (tail[1] in [sep, altsep]) then
      result := head + ncopy(tail, 2)
    else
      result := head + tail
  else
    if (tail <> '') and (tail[1] in [sep, altsep]) then
      result := head + tail
    else
      result := head + sep + tail
end;

function JoinPath(const parts: array of string): string;
var
  i: int;
begin
  result := parts[0];
  for i := 1 to high(parts) do
    result := JoinPath(result, parts[i])
end;

{$ifdef mswindows}
function getEnv(const name: string): string;
var
  len: Cardinal;
begin
  // get the length:
  len := windows.GetEnvironmentVariable(PChar(name), nil, 0);
  if len = 0 then
    result := ''
  else begin
    setLength(result, len-1);
    windows.GetEnvironmentVariable(PChar(name), @result[1], len);
  end
end;

procedure putEnv(const name, val: string);
begin
  windows.SetEnvironmentVariable(PChar(name), PChar(val));
end;

function GetDateStr: string;
var
  st: SystemTime;
begin
  Windows.GetLocalTime({$ifdef fpc} @ {$endif} st);
  result := IntToStr(st.wYear, 4) + '/' + IntToStr(st.wMonth, 2) + '/'
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

function setenv(var_name, new_value: PChar;
                change_flag: Boolean): Integer; cdecl; external 'libc';

type
  TPair = record
    key, val: string;
  end;
  TPairs = array of TPair;
var
  myEnv: TPairs; // this is a horrible fix for Posix systems!

function getMyEnvIdx(const key: string): int;
var
  i: int;
begin
  for i := 0 to high(myEnv) do
    if myEnv[i].key = key then begin result := i; exit end;
  result := -1
end;

function getMyEnv(const key: string): string;
var
  i: int;
begin
  i := getMyEnvIdx(key);
  if i >= 0 then result := myEnv[i].val
  else result := ''
end;

procedure setMyEnv(const key, val: string);
var
  i: int;
begin
  i := getMyEnvIdx(key);
  if i < 0 then begin
    i := length(myEnv);
    setLength(myEnv, i+1);
    myEnv[i].key := key
  end;
  myEnv[i].val := val
end;

procedure putEnv(const name, val: string);
begin
  setEnv(pchar(name), pchar(val), true);
  setMyEnv(name, val);
//  writeln('putEnv() is not supported under this OS');
//  halt(3);
end;

function getEnv(const name: string): string;
begin
  result := getMyEnv(name);
  if result = '' then result := dos.getEnv(name);
end;

function GetDateStr: string;
var
  wMonth, wYear, wDay: Word;
begin
  SysUtils.DecodeDate(Date, wYear, wMonth, wDay);
  result := IntToStr(wYear, 4) + '/' + IntToStr(wMonth, 2) + '/'
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

function GetTimeStr: string;
var
  Hour, Min, Sec, MSec: int;
begin
  GetTime(Hour, min, sec, msec);
  result := IntToStr(Hour, 2) + ':' + IntToStr(min, 2) + ':' + IntToStr(Sec, 2)
end;

function DateAndTime: string;
begin
  result := GetDateStr() + ' ' + getTimeStr()
end;

{$ifdef windows}

function executeShellCommand(const cmd: string): int;
var
  SI: TStartupInfo;
  ProcInfo: TProcessInformation;
  process: THandle;
  L: DWORD;
begin
  FillChar(SI, Sizeof(SI), 0);
  SI.cb := SizeOf(SI);
  SI.hStdError := GetStdHandle(STD_ERROR_HANDLE);
  SI.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
  SI.hStdOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  if not Windows.CreateProcess(nil, PChar(cmd), nil, nil, false,
    NORMAL_PRIORITY_CLASS, nil {Windows.GetEnvironmentStrings()},
    nil, SI, ProcInfo)
  then
    result := getLastError()
  else begin
    Process := ProcInfo.hProcess;
    CloseHandle(ProcInfo.hThread);
    if WaitForSingleObject(Process, INFINITE) <> $ffffffff then begin
      GetExitCodeProcess(Process, L);
      result := int(L)
    end
    else
      result := -1;
    CloseHandle(Process);
  end;
end;

{$else}
  {$ifdef windows}
function executeShellCommand(const cmd: string): int;
begin
  result := dos.Exec(cmd, '')
end;
//C:\Eigenes\compiler\MinGW\bin;
  {$else}
// fpc has a portable function for this
function executeShellCommand(const cmd: string): int;
begin
  result := shell(cmd);
end;
  {$endif}
{$endif}

{$ifdef windows}
type
  TFileAge = packed record
    Low, High: Longword;
  end;
{$else}
type
  TFileAge = dos.DateTime;
  {DateTime = packed record
    Year: Word;
    Month: Word;
    Day: Word;
    Hour: Word;
    Min: Word;
    Sec: Word;
  end;}
{$endif}

function GetLastWriteTime(Filename: PChar): TFileAge;
{$ifdef windows}
var
  Handle: THandle;
  FindRec: Win32_Find_Data;
begin
  Handle := FindFirstFile(Filename, FindRec);
  FindClose(Handle);
  result := TFileAge(FindRec.ftLastWriteTime)
end;
{$else}
var
  f: file;
  time: longint;
begin
  AssignFile(f, AnsiString(Filename));
  Reset(f);
  GetFTime(f, time);
  unpackTime(time, result);
  CloseFile(f);
end;
{$endif}

function Newer(file1, file2: PChar): Boolean;
var
  Time1, Time2: TFileAge;
begin
  Time1 := GetLastWriteTime(file1);
  Time2 := GetLastWriteTime(file2);
{$ifdef windows}
  if Time1.High <> Time2.High then
    result := Time1.High > Time2.High
  else
    result := Time1.Low > Time2.Low
{$else}
  if time1.year <> time2.year then
    result := time1.year > time2.year
  else if time1.month <> time2.month then
    result := time1.month > time2.month
  else if time1.day <> time2.day then
    result := time1.day > time2.day
  else if time1.hour <> time2.hour then
    result := time1.hour > time2.hour
  else if time1.min <> time2.min then
    result := time1.min > time2.min
  else if time1.sec <> time2.sec then
    result := time1.sec > time2.sec
{$endif}
end;

{$ifopt I+} {$define I_on} {$I-} {$endif}
function ExistsFile(const filename: string): Boolean;
var
  txt: TextFile;
begin
  AssignFile(txt, filename);
  Reset(txt);
  if IOResult = 0 then begin
    result := true;
    CloseFile(txt)
  end
  else result := false
end;
{$ifdef I_on} {$I+} {$endif}

function FileNewer(const a, b: string): Boolean;
begin
  if not ExistsFile(PChar(a)) or not ExistsFile(PChar(b)) then
    result := false
  else
    result := newer(PChar(a), PChar(b))
end;

end.
