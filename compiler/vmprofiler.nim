
import
  options, vmdef, times, lineinfos, strutils, tables,
  msgs

proc enter*(prof: var Profiler, c: PCtx, tos: PStackFrame) {.inline.} =
  if optProfileVM in c.config.globalOptions:
    prof.tEnter = cpuTime()
    prof.tos = tos

proc leaveImpl(prof: var Profiler, c: PCtx) {.noinline.} =
  let tLeave = cpuTime()
  var tos = prof.tos
  var data = c.config.vmProfileData.data
  while tos != nil:
    if tos.prc != nil:
      let li = tos.prc.info
      if li notin data:
        data[li] = ProfileInfo()
      data[li].time += tLeave - prof.tEnter
      if tos == prof.tos:
        inc data[li].count
    tos = tos.next

proc leave*(prof: var Profiler, c: PCtx) {.inline.} =
  if optProfileVM in c.config.globalOptions:
    leaveImpl(prof, c)

proc dump*(conf: ConfigRef, pd: ProfileData): string =
  var data = pd.data
  echo "\nprof:     µs    #instr  location"
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
    result.add  "  " & align($int(infoMax.time * 1e6), 10) &
                       align($int(infoMax.count), 10) & "  " &
                       conf.toFileLineCol(flMax) & "\n"
    data.del flMax
