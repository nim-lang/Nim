
import
  options, vmdef, times, std/private/miscdollars, lineinfos, strutils, tables,
  msgs
  
proc enter*(prof: var Profiler, c: PCtx, tos: PStackFrame) {.inline.} =
  if optProfileVM in c.config.globalOptions:
    prof.tEnter = cpuTime()
    prof.tos = tos

proc leave*(prof: var Profiler, c: PCtx) {.inline.} =
  if optProfileVM in c.config.globalOptions:
    let tLeave = cpuTime()
    var tos = prof.tos
    while tos != nil:
      if tos.prc != nil:
        let li = TLineInfo(fileIndex: tos.prc.info.fileIndex, line: tos.prc.info.line)
        if li notin c.profiler.data:
          c.profiler.data[li] = ProfileInfo()
        c.profiler.data[li].time += tLeave - prof.tEnter
        inc c.profiler.data[li].count
      tos = tos.next

proc dump*(p: var Profiler, c: PCtx) =
  if optProfileVM in c.config.globalOptions:
    echo "\nprof:     µs     count  location"
    var data = c.profiler.data
    for i in 0..<32:
      var tMax: float
      var infoMax: ProfileInfo
      var flMax: TLineInfo
      for fl, info in data:
        if info.time > infoMax.time:
          infoMax = info
          flMax = fl
      if infoMax.count == 0:
        break
      var msg = "  " & align($int(infoMax.time * 1e6), 10) &
                       align($int(infoMax.count), 10) & "  "
      toLocation(msg, c.config.toMsgFilename(flMax.fileIndex), flMax.line.int, 0)
      echo msg
      data.del flMax
