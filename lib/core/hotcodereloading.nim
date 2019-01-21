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

  when not defined(JS):
    template performCodeReload* = hcrPerformCodeReload()
  else:
    template performCodeReload* = discard
else:
  template beforeCodeReload*(body: untyped) = discard
  template afterCodeReload*(body: untyped) = discard
  template hasModuleChanged*(module: typed): bool = false
  proc hasAnyModuleChanged*(): bool = false
  template performCodeReload*() = discard
