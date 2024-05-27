import std/winlean


type
  JOBOBJECT_BASIC_LIMIT_INFORMATION* = object
    perProcessUserTimeLimit*: uint64
    perJobUserTimeLimit*: uint64
    limitFlags*: DWORD
    minimumWorkingSetSize*: WinSizeT
    maximumWorkingSetSize*: WinSizeT
    activeProcessLimit*: DWORD
    affinity*: ULONG_PTR
    priorityClass*: DWORD
    schedulingClass*: DWORD

  IO_COUNTERS* = object
    readOperationCount*: uint64
    writeOperationCount*: uint64
    otherOperationCount*: uint64
    readTransferCount*: uint64
    writeTransferCount*: uint64
    otherTransferCount*: uint64

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION* = object
    basicLimitInformation*: JOBOBJECT_BASIC_LIMIT_INFORMATION
    ioInfo*: IO_COUNTERS
    processMemoryLimit*: WinSizeT
    jobMemoryLimit*: WinSizeT
    peakProcessMemoryUsed*: WinSizeT
    peakJobMemoryUsed*: WinSizeT

const
  JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE* = 0x2000

  ERROR_ALREADY_EXISTS* = 0xB7

  jJobObjectBasicLimitInformation* = 2
  jJobObjectExtendedLimitInformation* = 9

proc createJobObject*(lpJobAttributes: ptr SECURITY_ATTRIBUTES, lpName: WideCString): Handle
     {.stdcall, dynlib: "kernel32", importc: "CreateJobObjectW".}

proc assignProcessToJobObject*(hJob, hProcess: Handle): bool
     {.stdcall, dynlib: "kernel32", importc: "AssignProcessToJobObject".}

proc setInformationJobObject*(hJob: Handle, JobObjectInformationClass: cint, lpJobObjectInformation: pointer, cbJobObjectInformationLength: DWORD): bool
     {.stdcall, dynlib: "kernel32", importc: "SetInformationJobObject".}

proc terminateJobObject*(hJob: Handle, uExitCode: cuint): bool
     {.stdcall, dynlib: "kernel32", importc: "TerminateJobObject".}
