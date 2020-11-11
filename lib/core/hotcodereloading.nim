#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Unstable API.

when defined(hotcodereloading):
  import
    macros

  template beforeCodeReload*(body: untyped) =
    hcrAddEventHandler(true, proc = body) {.executeOnReload.}

  template afterCodeReload*(body: untyped) =
    hcrAddEventHandler(false, proc = body) {.executeOnReload.}

  macro hasModuleChanged*(module: typed): untyped =
    if module.kind != nnkSym or module.symKind != nskModule:
      error "hasModuleChanged expects a module symbol", module
    return newCall(bindSym"hcrHasModuleChanged", newLit(module.signatureHash))

  proc hasAnyModuleChanged*(): bool = hcrReloadNeeded()

  when not defined(js):
    template performCodeReload* =
      when isMainModule:
        {.warning: "Code residing in the main module will not be changed from calling a code-reload".}
      hcrPerformCodeReload()
  else:
    template performCodeReload* = discard
else:
  template beforeCodeReload*(body: untyped) = discard
  template afterCodeReload*(body: untyped) = discard
  template hasModuleChanged*(module: typed): bool = false
  proc hasAnyModuleChanged*(): bool = false
  template performCodeReload*() = discard
