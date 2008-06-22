#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


interface

type
  TProcess = opaque

proc
  open(out p: TProcess, command, workingDir: string,

implementation


Uses Classes,
     pipes,
     SysUtils;

Type
  TProcessOption = (poRunSuspended,poWaitOnExit,
                    poUsePipes,poStderrToOutPut,
                    poNoConsole,poNewConsole,
                    poDefaultErrorMode,poNewProcessGroup,
                    poDebugProcess,poDebugOnlyThisProcess);

  TShowWindowOptions = (swoNone,swoHIDE,swoMaximize,swoMinimize,swoRestore,swoShow,
                        swoShowDefault,swoShowMaximized,swoShowMinimized,
                        swoshowMinNOActive,swoShowNA,swoShowNoActivate,swoShowNormal);

  TStartupOption = (suoUseShowWindow,suoUseSize,suoUsePosition,
                    suoUseCountChars,suoUseFillAttribute);

  TProcessPriority = (ppHigh,ppIdle,ppNormal,ppRealTime);

  TProcessOptions = Set of TPRocessOption;
  TstartUpoptions = set of TStartupOption;


Type
  TProcess = Class (TComponent)
  Private
    FProcessOptions : TProcessOptions;
    FStartupOptions : TStartupOptions;
    FProcessID : Integer;
    FThreadID : Integer;
    FProcessHandle : Thandle;
    FThreadHandle : Thandle;
    FFillAttribute : Cardinal;
    FApplicationName : string;
    FConsoleTitle : String;
    FCommandLine : String;
    FCurrentDirectory : String;
    FDeskTop : String;
    FEnvironment : Tstrings;
    FExitCode : Cardinal;
    FShowWindow : TShowWindowOptions;
    FInherithandles : Boolean;
    FInputSTream  : TOutputPipeStream;
    FOutputStream : TInPutPipeStream;
    FStdErrStream : TInputPipeStream;
    FRunning : Boolean;
    FPRocessPriority : TProcessPriority;
    dwXCountchars,
    dwXSize,
    dwYsize,
    dwx,
    dwYcountChars,
    dwy : Cardinal;
    Procedure FreeStreams;
    Function  GetExitStatus : Integer;
    Function  GetRunning : Boolean;
    Function  GetWindowRect : TRect;
    Procedure SetWindowRect (Value : TRect);
    Procedure SetShowWindow (Value : TShowWindowOptions);
    Procedure SetWindowColumns (Value : Cardinal);
    Procedure SetWindowHeight (Value : Cardinal);
    Procedure SetWindowLeft (Value : Cardinal);
    Procedure SetWindowRows (Value : Cardinal);
    Procedure SetWindowTop (Value : Cardinal);
    Procedure SetWindowWidth (Value : Cardinal);
    Procedure CreateStreams(InHandle,OutHandle,Errhandle : Longint);
    procedure SetApplicationname(const Value: String);
    procedure SetProcessOptions(const Value: TProcessOptions);
    procedure SetActive(const Value: Boolean);
    procedure SetEnvironment(const Value: TStrings);
    function  PeekExitStatus: Boolean;
    procedure CloseProcessHandles;
  Public
    Constructor Create (AOwner : TComponent);override;
    Destructor Destroy; override;
    Procedure Execute; virtual;
    Function Resume : Integer; virtual;
    Function Suspend : Integer; virtual;
    Function Terminate (AExitCode : Integer): Boolean; virtual;
    Function WaitOnExit : DWord;
    Property WindowRect : Trect Read GetWindowRect Write SetWindowRect;
    Property Handle : THandle Read FProcessHandle;
    Property ProcessHandle : THandle Read FProcessHandle;
    Property ThreadHandle : THandle Read FThreadHandle;
    Property ProcessID : Integer Read FProcessID;
    Property ThreadID : Integer Read FThreadID;
    Property Input  : TOutPutPipeStream Read FInPutStream;
    Property OutPut : TInputPipeStream  Read FOutPutStream;
    Property StdErr : TinputPipeStream  Read FStdErrStream;
    Property ExitStatus : Integer Read GetExitStatus;
    Property InheritHandles : Boolean Read FInheritHandles Write FInheritHandles;
  Published
    Property Active : Boolean Read Getrunning Write SetActive;
    Property ApplicationName : String Read FApplicationname Write SetApplicationname;
    Property CommandLine : String Read FCommandLine Write FCommandLine;
    Property ConsoleTitle : String Read FConsoleTitle Write FConsoleTitle;
    Property CurrentDirectory : String Read FCurrentDirectory Write FCurrentDirectory;
    Property DeskTop : String Read FDeskTop Write FDeskTop;
    Property Environment : TStrings Read FEnvironment Write SetEnvironment;
    Property Options : TProcessOptions Read FProcessOptions Write SetPRocessOptions;
    Property Priority : TProcessPriority Read FProcessPriority Write FProcessPriority;
    Property StartUpOptions : TStartUpOptions Read FStartUpOptions Write FStartupOptions;
    Property Running : Boolean Read GetRunning;
    Property ShowWindow : TShowWindowOptions Read FShowWindow Write SetShowWindow;
    Property WindowColumns : Cardinal Read dwXCountchars Write SetWindowColumns;
    Property WindowHeight : Cardinal Read dwYsize Write SetWindowHeight;
    Property WindowLeft : Cardinal Read dwx Write SetWindowLeft;
    Property WindowRows : Cardinal Read dwYcountChars Write SetWindowRows;
    Property WindowTop : Cardinal Read dwy Write SetWindowTop ;
    Property WindowWidth : Cardinal Read dwXsize Write SetWindowWidth;
    Property FillAttribute : Cardinal read FFillAttribute Write FFillAttribute;
  end;

implementation

{
  Win32 Process .inc.
}

uses Windows;

Const
  PriorityConstants : Array [TProcessPriority] of Cardinal =
                      (HIGH_PRIORITY_CLASS,IDLE_PRIORITY_CLASS,
                       NORMAL_PRIORITY_CLASS,REALTIME_PRIORITY_CLASS);

procedure TProcess.CloseProcessHandles;
begin
  if (FProcessHandle<>0) then
    CloseHandle(FProcessHandle);
  if (FThreadHandle<>0) then
    CloseHandle(FThreadHandle);
end;

Function TProcess.PeekExitStatus : Boolean;

begin
  GetExitCodeProcess(ProcessHandle,FExitCode);
  Result:=(FExitCode<>Still_Active);
end;

Function GetStartupFlags (P : TProcess): Cardinal;

begin
  With P do
    begin
    Result:=0;
    if poUsePipes in FProcessOptions then
       Result:=Result or Startf_UseStdHandles;
    if suoUseShowWindow in FStartupOptions then
      Result:=Result or startf_USESHOWWINDOW;
    if suoUSESIZE in FStartupOptions then
      Result:=Result or startf_usesize;
    if suoUsePosition in FStartupOptions then
      Result:=Result or startf_USEPOSITION;
    if suoUSECOUNTCHARS in FStartupoptions then
      Result:=Result or startf_usecountchars;
    if suoUsefIllAttribute in FStartupOptions then
      Result:=Result or startf_USEFILLATTRIBUTE;
    end;
end;

Function GetCreationFlags(P : TProcess) : Cardinal;

begin
  With P do
    begin
    Result:=0;
    if poNoConsole in FProcessOptions then
      Result:=Result or Detached_Process;
    if poNewConsole in FProcessOptions then
      Result:=Result or Create_new_console;
    if poNewProcessGroup in FProcessOptions then
      Result:=Result or CREATE_NEW_PROCESS_GROUP;
    If poRunSuspended in FProcessOptions Then
      Result:=Result or Create_Suspended;
    if poDebugProcess in FProcessOptions Then
      Result:=Result or DEBUG_PROCESS;
    if poDebugOnlyThisProcess in FProcessOptions Then
      Result:=Result or DEBUG_ONLY_THIS_PROCESS;
    if poDefaultErrorMode in FProcessOptions Then
      Result:=Result or CREATE_DEFAULT_ERROR_MODE;
    result:=result or PriorityConstants[FProcessPriority];
    end;
end;

Function StringsToPChars(List : TStrings): pointer;

var
  EnvBlock: string;
  I: Integer;

begin
  EnvBlock := '';
  For I:=0 to List.Count-1 do
    EnvBlock := EnvBlock + List[i] + #0;
  EnvBlock := EnvBlock + #0;
  GetMem(Result, Length(EnvBlock));
  CopyMemory(Result, @EnvBlock[1], Length(EnvBlock));
end;

Procedure InitProcessAttributes(P : TProcess; Var PA : TSecurityAttributes);

begin
  FillChar(PA,SizeOf(PA),0);
  PA.nLength := SizeOf(PA);
end;

Procedure InitThreadAttributes(P : TProcess; Var TA : TSecurityAttributes);

begin
  FillChar(TA,SizeOf(TA),0);
  TA.nLength := SizeOf(TA);
end;

Procedure InitStartupInfo(P : TProcess; Var SI : STARTUPINFO);

Const
  SWC : Array [TShowWindowOptions] of Cardinal =
             (0,SW_HIDE,SW_Maximize,SW_Minimize,SW_Restore,SW_Show,
             SW_ShowDefault,SW_ShowMaximized,SW_ShowMinimized,
               SW_showMinNOActive,SW_ShowNA,SW_ShowNoActivate,SW_ShowNormal);

begin
  FillChar(SI,SizeOf(SI),0);
  With SI do
    begin
    dwFlags:=GetStartupFlags(P);
    if P.FShowWindow<>swoNone then
     dwFlags:=dwFlags or Startf_UseShowWindow
    else
      dwFlags:=dwFlags and not Startf_UseShowWindow;
    wShowWindow:=SWC[P.FShowWindow];
    if (poUsePipes in P.Options) then
      begin
      dwFlags:=dwFlags or Startf_UseStdHandles;
      end;
    if P.FillAttribute<>0 then
      begin
      dwFlags:=dwFlags or Startf_UseFillAttribute;
      dwFillAttribute:=P.FillAttribute;
      end;
     dwXCountChars:=P.WindowColumns;
     dwYCountChars:=P.WindowRows;
     dwYsize:=P.WindowHeight;
     dwXsize:=P.WindowWidth;
     dwy:=P.WindowTop;
     dwX:=P.WindowLeft;
     end;
end;

Procedure CreatePipes(Var HI,HO,HE : Thandle; Var SI : TStartupInfo; CE : Boolean);

  Procedure DoCreatePipeHandles(Var H1,H2 : THandle);

  Var
    I,O : Longint;

  begin
    CreatePipeHandles(I,O);
    H1:=Thandle(I);
    H2:=THandle(O);
  end;




begin
  DoCreatePipeHandles(SI.hStdInput,HI);
  DoCreatePipeHandles(HO,Si.hStdOutput);
  if CE then
    DoCreatePipeHandles(HE,SI.hStdError)
  else
    begin
    SI.hStdError:=SI.hStdOutput;
    HE:=HO;
    end;
end;


Procedure TProcess.Execute;


Var
  PName,PDir,PCommandLine : PChar;
  FEnv: pointer;
  FCreationFlags : Cardinal;
  FProcessAttributes : TSecurityAttributes;
  FThreadAttributes : TSecurityAttributes;
  FProcessInformation : TProcessInformation;
  FStartupInfo : STARTUPINFO;
  HI,HO,HE : THandle;

begin
  FInheritHandles:=True;
  PName:=Nil;
  PCommandLine:=Nil;
  PDir:=Nil;
  If FApplicationName<>'' then
    PName:=Pchar(FApplicationName);
  If FCommandLine<>'' then
    PCommandLine:=Pchar(FCommandLine);
  If FCurrentDirectory<>'' then
    PDir:=Pchar(FCurrentDirectory);
  if FEnvironment.Count<>0 then
    FEnv:=StringsToPChars(FEnvironment)
  else
    FEnv:=Nil;
  Try
    FCreationFlags:=GetCreationFlags(Self);
    InitProcessAttributes(Self,FProcessAttributes);
    InitThreadAttributes(Self,FThreadAttributes);
    InitStartupInfo(Self,FStartUpInfo);
    If poUsePipes in FProcessOptions then
      CreatePipes(HI,HO,HE,FStartupInfo,Not(poStdErrToOutPut in FProcessOptions));
    Try
      If Not CreateProcess (PName,PCommandLine,@FProcessAttributes,@FThreadAttributes,
                   FInheritHandles,FCreationFlags,FEnv,PDir,FStartupInfo,
                   fProcessInformation) then
        Raise Exception.CreateFmt('Failed to execute %s : %d',[FCommandLine,GetLastError]);
      FProcessHandle:=FProcessInformation.hProcess;
      FThreadHandle:=FProcessInformation.hThread;
      FProcessID:=FProcessINformation.dwProcessID;
    Finally
      if POUsePipes in FProcessOptions then
        begin
        FileClose(FStartupInfo.hStdInput);
        FileClose(FStartupInfo.hStdOutput);
        if Not (poStdErrToOutPut in FProcessOptions) then
          FileClose(FStartupInfo.hStdError);
        CreateStreams(HI,HO,HE);
        end;
    end;
    FRunning:=True;
  Finally
    If FEnv<>Nil then
      FreeMem(FEnv);
  end;
  if not (csDesigning in ComponentState) and // This would hang the IDE !
     (poWaitOnExit in FProcessOptions) and
      not (poRunSuspended in FProcessOptions) then
    WaitOnExit;
end;

Function TProcess.WaitOnExit : Dword;

begin
  Result:=WaitForSingleObject (FProcessHandle,Infinite);
  If Result<>Wait_Failed then
    GetExitStatus;
  FRunning:=False;
end;

Function TProcess.Suspend : Longint;

begin
  Result:=SuspendThread(ThreadHandle);
end;

Function TProcess.Resume : LongInt;

begin
  Result:=ResumeThread(ThreadHandle);
end;

Function TProcess.Terminate(AExitCode : Integer) : Boolean;

begin
  Result:=False;
  If ExitStatus=Still_active then
    Result:=TerminateProcess(Handle,AexitCode);
end;

Procedure TProcess.SetShowWindow (Value : TShowWindowOptions);


begin
  FShowWindow:=Value;
end;

// ---------------------------- end of platform dependant code --------------

{
  Unix Process .inc.
}

uses
   Unix,
   Baseunix;



Const
  PriorityConstants : Array [TProcessPriority] of Integer =
                      (20,20,0,-20);

Const
  GeometryOption : String = '-geometry';
  TitleOption : String ='-title';



procedure TProcess.CloseProcessHandles;

begin
 // Do nothing. Win32 call.
end;

Function TProcess.PeekExitStatus : Boolean;

begin
  Result:=fpWaitPid(Handle,@FExitCode,WNOHANG)=Handle;
  If Result then
    FExitCode:=wexitstatus(FExitCode)
  else
    FexitCode:=0;
end;

Type
  TPCharArray = Array[Word] of pchar;
  PPCharArray = ^TPcharArray;

Function StringsToPCharList(List : TStrings) : PPChar;

Var
  I : Integer;
  S : String;

begin
  I:=(List.Count)+1;
  GetMem(Result,I*sizeOf(PChar));
  PPCharArray(Result)^[List.Count]:=Nil;
  For I:=0 to List.Count-1 do
    begin
    S:=List[i];
    Result[i]:=StrNew(PChar(S));
    end;
end;

Procedure FreePCharList(List : PPChar);

Var
  I : integer;

begin
  I:=0;
  While List[i]<>Nil do
    begin
    StrDispose(List[i]);
    Inc(I);
    end;
  FreeMem(List);
end;


Procedure CommandToList(S : String; List : TStrings);

  Function GetNextWord : String;

  Const
    WhiteSpace = [' ',#8,#10];
    Literals = ['"',''''];

  Var
    Wstart,wend : Integer;
    InLiteral : Boolean;
    LastLiteral : char;

  begin
    WStart:=1;
    While (WStart<=Length(S)) and (S[WStart] in WhiteSpace) do
      Inc(WStart);
    WEnd:=WStart;
    InLiteral:=False;
    LastLiteral:=#0;
    While (Wend<=Length(S)) and (Not (S[Wend] in WhiteSpace) or InLiteral) do
      begin
      if S[Wend] in Literals then
        If InLiteral then
          InLiteral:=Not (S[Wend]=LastLiteral)
        else
          begin
          InLiteral:=True;
          LastLiteral:=S[Wend];
          end;
       inc(wend);
       end;
     Result:=Copy(S,WStart,WEnd-WStart);
     Result:=StringReplace(Result,'"','',[rfReplaceAll]);
     Result:=StringReplace(Result,'''','',[rfReplaceAll]);
     While (WEnd<=Length(S)) and (S[Wend] in WhiteSpace) do
       inc(Wend);
     Delete(S,1,WEnd-1);

  end;

Var
  W : String;

begin
  While Length(S)>0 do
    begin
    W:=GetNextWord;
    If (W<>'') then
      List.Add(W);
    end;
end;


Function MakeCommand(P : TProcess) : PPchar;

Const
  SNoCommandLine = 'Cannot execute empty command-line';

Var
  Cmd : String;
  S  : TStringList;
  G : String;

begin
  if (P.ApplicationName='') then
    begin
    If (P.CommandLine='') then
      Raise Exception.Create(SNoCommandline);
    Cmd:=P.CommandLine;
    end
  else
    begin
    If (P.CommandLine='') then
      Cmd:=P.ApplicationName
    else
      Cmd:=P.CommandLine;
    end;
  S:=TStringList.Create;
  try
    CommandToList(Cmd,S);
    if poNewConsole in P.Options then
      begin
      S.Insert(0,'-e');
      If (P.ApplicationName<>'') then
        begin
        S.Insert(0,P.ApplicationName);
        S.Insert(0,'-title');
        end;
      if suoUseCountChars in P.StartupOptions then
        begin
        S.Insert(0,Format('%dx%d',[P.dwXCountChars,P.dwYCountChars]));
        S.Insert(0,'-geometry');
        end;
      S.Insert(0,'xterm');
      end;
    if (P.ApplicationName<>'') then
      begin
      S.Add(TitleOption);
      S.Add(P.ApplicationName);
      end;
    G:='';
    if (suoUseSize in P.StartupOptions) then
      g:=format('%dx%d',[P.dwXSize,P.dwYsize]);
    if (suoUsePosition in P.StartupOptions) then
      g:=g+Format('+%d+%d',[P.dwX,P.dwY]);
    if G<>'' then
      begin
      S.Add(GeometryOption);
      S.Add(g);
      end;
    Result:=StringsToPcharList(S);
  Finally
    S.free;
  end;
end;

Function GetLastError : Integer;

begin
  Result:=-1;
end;

Type
  TPipeEnd = (peRead,peWrite);
  TPipePair = Array[TPipeEnd] of Integer;

Procedure CreatePipes(Var HI,HO,HE : TPipePair; CE : Boolean);

  Procedure CreatePair(Var P : TPipePair);

   begin
    If not CreatePipeHandles(P[peRead],P[peWrite]) then
      Raise Exception.Create('Failed to create pipes');
   end;

  Procedure ClosePair(Var P : TPipePair);

  begin
    if (P[peRead]<>-1) then
      FileClose(P[peRead]);
    if (P[peWrite]<>-1) then
      FileClose(P[peWrite]);
  end;

begin
  HO[peRead]:=-1;HO[peWrite]:=-1;
  HI[peRead]:=-1;HI[peWrite]:=-1;
  HE[peRead]:=-1;HE[peWrite]:=-1;
  Try
    CreatePair(HO);
    CreatePair(HI);
    If CE then
      CreatePair(HE);
  except
    ClosePair(HO);
    ClosePair(HI);
    If CE then
      ClosePair(HE);
    Raise;
  end;
end;

Procedure TProcess.Execute;

Var
  HI,HO,HE : TPipePair;
  PID      : Longint;
  FEnv     : PPChar;
  Argv     : PPChar;
  fd       : Integer;
  PName    : String;

begin
  If (poUsePipes in FProcessOptions) then
    CreatePipes(HI,HO,HE,Not (poStdErrToOutPut in FProcessOptions));
  Try
    if FEnvironment.Count<>0 then
      FEnv:=StringsToPcharList(FEnvironment)
    else
      FEnv:=Nil;
    Try
      Argv:=MakeCommand(Self);
      Try
        If (Argv<>Nil) and (ArgV[0]<>Nil) then
          PName:=StrPas(Argv[0])
        else
          begin
          // This should never happen, actually.
          PName:=ApplicationName;
          If (PName='') then
            PName:=CommandLine;
          end;
        if (pos('/',PName)<>1) then
          PName:=FileSearch(Pname,fpgetenv('PATH'));
        Pid:=fpfork;
        if Pid<0 then
          Raise Exception.Create('Failed to Fork process');
        if (PID>0) then
          begin
          // Parent process. Copy process information.
          FProcessHandle:=PID;
          FThreadHandle:=PID;
          FProcessId:=PID;
          //FThreadId:=PID;
          end
        else
          begin
          { We're in the child }
          if (FCurrentDirectory<>'') then
             ChDir(FCurrentDirectory);
          if PoUsePipes in Options then
            begin
            fpdup2(HI[peRead],0);
            fpdup2(HO[peWrite],1);
            if (poStdErrToOutPut in Options) then
              fpdup2(HO[peWrite],2)
            else
              fpdup2(HE[peWrite],2);
            end
          else if poNoConsole in Options then
            begin
            fd:=FileOpen('/dev/null',fmOpenReadWrite);
            fpdup2(fd,0);
            fpdup2(fd,1);
            fpdup2(fd,2);
            end;
          if (poRunSuspended in Options) then
            sigraise(SIGSTOP);
          if FEnv<>Nil then
            fpexecve(PName,Argv,Fenv)
          else
            fpexecv(PName,argv);
          Halt(127);
          end
      Finally
        FreePcharList(Argv);
      end;
    Finally
      If (FEnv<>Nil) then
        FreePCharList(FEnv);
    end;
  Finally
    if POUsePipes in FProcessOptions then
      begin
      FileClose(HO[peWrite]);
      FileClose(HI[peRead]);
      if Not (poStdErrToOutPut in FProcessOptions) then
        FileClose(HE[peWrite]);
      CreateStreams(HI[peWrite],HO[peRead],HE[peRead]);
      end;
  end;
  FRunning:=True;
  if not (csDesigning in ComponentState) and // This would hang the IDE !
     (poWaitOnExit in FProcessOptions) and
      not (poRunSuspended in FProcessOptions) then
    WaitOnExit;
end;

Function TProcess.WaitOnExit : Dword;

begin
  Result:=fpWaitPid(Handle,@FExitCode,0);
  If Result=Handle then
    FExitCode:=WexitStatus(FExitCode);
  FRunning:=False;
end;

Function TProcess.Suspend : Longint;

begin
  If fpkill(Handle,SIGSTOP)<>0 then
    Result:=-1
  else
    Result:=1;
end;

Function TProcess.Resume : LongInt;

begin
  If fpKill(Handle,SIGCONT)<>0 then
    Result:=-1
  else
    Result:=0;
end;

Function TProcess.Terminate(AExitCode : Integer) : Boolean;

begin
  Result:=False;
  Result:=fpkill(Handle,SIGTERM)=0;
  If Result then
    begin
    If Running then
      Result:=fpkill(Handle,SIGKILL)=0;
    end;
  GetExitStatus;
end;

Procedure TProcess.SetShowWindow (Value : TShowWindowOptions);

begin
  FShowWindow:=Value;
end;

// ---------------------------------------------------------------------------


Constructor TProcess.Create (AOwner : TComponent);
begin
  Inherited;
  FProcessPriority:=ppNormal;
  FShowWindow:=swoNone;
  FInheritHandles:=True;
  FEnvironment:=TStringList.Create;
end;

Destructor TProcess.Destroy;

begin
  FEnvironment.Free;
  FreeStreams;
  CloseProcessHandles;
  Inherited Destroy;
end;

Procedure TProcess.FreeStreams;

  procedure FreeStream(var S: THandleStream);

  begin
    if (S<>Nil) then
      begin
      FileClose(S.Handle);
      FreeAndNil(S);
      end;
  end;

begin
  If FStdErrStream<>FOutputStream then
    FreeStream(FStdErrStream);
  FreeStream(FOutputStream);
  FreeStream(FInputStream);
end;


Function TProcess.GetExitStatus : Integer;

begin
  If FRunning then
    PeekExitStatus;
  Result:=FExitCode;
end;


Function TProcess.GetRunning : Boolean;

begin
  IF FRunning then
    FRunning:=Not PeekExitStatus;
  Result:=FRunning;
end;


Procedure TProcess.CreateStreams(InHandle,OutHandle,Errhandle : Longint);

begin
  FreeStreams;
  FInputStream:=TOutputPipeStream.Create (InHandle);
  FOutputStream:=TInputPipeStream.Create (OutHandle);
  if Not (poStdErrToOutPut in FProcessOptions) then
    FStdErrStream:=TInputPipeStream.Create(ErrHandle);
end;


Procedure TProcess.SetWindowColumns (Value : Cardinal);

begin
  if Value<>0 then
    Include(FStartUpOptions,suoUseCountChars);
  dwXCountChars:=Value;
end;


Procedure TProcess.SetWindowHeight (Value : Cardinal);

begin
  if Value<>0 then
    include(FStartUpOptions,suoUsePosition);
  dwYSize:=Value;
end;

Procedure TProcess.SetWindowLeft (Value : Cardinal);

begin
  if Value<>0 then
    Include(FStartUpOptions,suoUseSize);
  dwx:=Value;
end;

Procedure TProcess.SetWindowTop (Value : Cardinal);

begin
  if Value<>0 then
    Include(FStartUpOptions,suoUsePosition);
  dwy:=Value;
end;

Procedure TProcess.SetWindowWidth (Value : Cardinal);
begin
  If (Value<>0) then
    Include(FStartUpOptions,suoUseSize);
  dwXSize:=Value;
end;

Function TProcess.GetWindowRect : TRect;
begin
  With Result do
    begin
    Left:=dwx;
    Right:=dwx+dwxSize;
    Top:=dwy;
    Bottom:=dwy+dwysize;
    end;
end;

Procedure TProcess.SetWindowRect (Value : Trect);
begin
  Include(FStartupOptions,suouseSize);
  Include(FStartupOptions,suoUsePosition);
  With Value do
    begin
    dwx:=Left;
    dwxSize:=Right-Left;
    dwy:=Top;
    dwySize:=Bottom-top;
    end;
end;


Procedure TProcess.SetWindowRows (Value : Cardinal);

begin
  if Value<>0 then
    Include(FStartUpOptions,suoUseCountChars);
  dwYCountChars:=Value;
end;

procedure TProcess.SetApplicationname(const Value: String);
begin
  FApplicationname := Value;
  If (csdesigning in ComponentState) and
     (FCommandLine='') then
    FCommandLine:=Value;
end;

procedure TProcess.SetProcessOptions(const Value: TProcessOptions);
begin
  FProcessOptions := Value;
  If poNewConsole in FPRocessOptions then
    Exclude(FProcessoptions,poNoConsole);
  if poRunSuspended in FProcessOptions then
    Exclude(FPRocessoptions,poWaitOnExit);
end;

procedure TProcess.SetActive(const Value: Boolean);
begin
  if (Value<>GetRunning) then
    If Value then
      Execute
    else
      Terminate(0);
end;

procedure TProcess.SetEnvironment(const Value: TStrings);
begin
  FEnvironment.Assign(Value);
end;

function CallProcess(const command: string): string;
const
  READ_BYTES = 2048;
// executes the command and returns the program's output
var
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
begin
  // We cannot use poWaitOnExit here since we don't
  // know the size of the output. On Linux the size of the
  // output pipe is 2 kB. If the output data is more, we
  // need to read the data. This isn't possible since we are
  // waiting. So we get a deadlock here.
  //
  // A temp Memorystream is used to buffer the output

  M := TMemoryStream.Create;
  BytesRead := 0;

  P := TProcess.Create(nil);
  P.CommandLine := Command;
  P.Options := [poUsePipes];
  P.Execute;
  while P.Running do begin
    // make sure we have room
    M.SetSize(BytesRead + READ_BYTES);

    // try reading it
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then
      Inc(BytesRead, n)
    else
      // no data, wait 100 ms
      Sleep(100)
  end;
  // read last part
  repeat
    // make sure we have room
    M.SetSize(BytesRead + READ_BYTES);
    // try reading it
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then Inc(BytesRead, n)
  until n <= 0;
  M.SetSize(BytesRead);

  setLength(result, bytesRead);
  m.read(result[1], bytesRead);
  P.Free; M.Free;
end;

end.
