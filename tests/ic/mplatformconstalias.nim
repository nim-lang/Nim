# A guard the dependency scanner cannot decide before sem: an imported const
# whose value comes from a call.
proc windowsGateProbe(): bool {.compileTime.} = true

const WindowsHostIsEnabled* = defined(windows) and windowsGateProbe()
