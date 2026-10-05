# Monitor a client process and shutdown the current process, if the client
# process is found to be dead

import os

when defined(posix):
  import posix_utils
  import posix
  import std/[strutils, files]

when defined(windows):
  import winlean

when defined(windows):
  type
    PROCESS_MEMORY_COUNTERS {.pure.} = object
      cb, pageFaultCount: DWORD
      peakWorkingSetSize, workingSetSize, quotaPeakPagedPoolUsage,
        quotaPagedPoolUsage, quotaPeakNonPagedPoolUsage,
        quotaNonPagedPoolUsage, pagefileUsage, peakPagefileUsage: int

  proc getProcessMemoryInfo*(
    process: Handle, ppsmemCounters: ptr PROCESS_MEMORY_COUNTERS, cb: DWORD
  ): WINBOOL {.
    stdcall, dynlib: "psapi", importc: "GetProcessMemoryInfo"
  .}

  proc monitorMemoryThreadProc(maxKb: int) {.thread.} =
    # Resident memory watchdog, Windows flavour: the working set is the
    # equivalent of the resident set size on POSIX.
    while true:
      sleep(2000)
      var pmc: PROCESS_MEMORY_COUNTERS
      pmc.cb = sizeof(pmc).DWORD
      if getProcessMemoryInfo(getCurrentProcess(), addr pmc, pmc.cb) != 0:
        let rssKb = pmc.workingSetSize div 1024
        if rssKb > maxKb:
          stderr.writeLine(
            "nimsuggest: resident memory ", rssKb, " kB exceeded the ",
            maxKb, " kB cap, quitting")
          quit(1)

when defined(macosx):
  # /proc does not exist on macOS: read the resident size via libproc instead.
  type
    ProcTaskInfo {.pure.} = object
      pti_virtual_size, pti_resident_size: uint64
      pti_total_user, pti_total_system: uint64
      pti_threads_user, pti_threads_system: uint64
      pti_policy, pti_faults, pti_pageins, pti_cow_faults: int32
      pti_messages_sent, pti_messages_received: int32
      pti_syscalls_mach, pti_syscalls_unix, pti_csw: int32
      pti_threadnum, pti_numrunning, pti_priority: int32

  const PROC_PIDTASKINFO = 4

  proc proc_pidinfo(pid: cint, flavor: cint, arg: uint64,
                    buffer: pointer, buffersize: cint): cint {.
    importc, header: "libproc.h"
  .}

when defined(posix):
  proc residentMemoryKb(): int =
    ## The resident set size of the current process in kB, or -1 when it
    ## cannot be read on this platform.
    result = -1
    when defined(linux):
      try:
        let statm = readFile("/proc/self/statm").split()
        if statm.len > 1:
          result = parseInt(statm[1]) * 4
      except:
        discard
    elif defined(macosx):
      var info: ProcTaskInfo
      if proc_pidinfo(getpid(), PROC_PIDTASKINFO, 0, addr info,
                      cint sizeof(info)) == cint sizeof(info):
        result = int(info.pti_resident_size div 1024)

  proc monitorMemoryThreadProc(maxKb: int) {.thread.} =
    # Resident memory watchdog: quit before taking the whole machine down.
    # ORC frees to the allocator, so a GC-level cap like nimMaxHeap (refc
    # only) is not available; polling the resident size works with any GC.
    while true:
      sleep(2000)
      let rssKb = residentMemoryKb()
      if rssKb > maxKb: # -1 (unreadable) never triggers: maxKb > 0
        stderr.writeLine(
          "nimsuggest: resident memory ", rssKb, " kB exceeded the ",
          maxKb, " kB cap, quitting")
        quit(1)

when defined(posix):
  proc monitorClientProcessIdThreadProc(pid: int) {.thread.} =
    while true:
      sleep(1000)
      try:
        sendSignal(Pid(pid), 0)
      except:
        discard kill(Pid(getCurrentProcessId()), cint(SIGTERM))

when defined(windows):
  proc monitorClientProcessIdThreadProc(pid: int) {.thread.} =
    var process = openProcess(SYNCHRONIZE, 0, DWORD(pid))
    if process != 0:
      discard waitForSingleObject(process, INFINITE)
      discard closeHandle(process)
    quit(0)

var tid: Thread[int]
var memTid: Thread[int]

proc hookProcMonitor*(pid: int) =
  when defined(posix) or defined(windows):
    createThread(tid, monitorClientProcessIdThreadProc, pid)

proc hookMemMonitor*(maxKb: int) =
  ## Quit the process when its resident memory exceeds ``maxKb``.
  ## ``maxKb == 0`` disables the watchdog.
  when defined(posix) or defined(windows):
    if maxKb > 0:
      createThread(memTid, monitorMemoryThreadProc, maxKb)
