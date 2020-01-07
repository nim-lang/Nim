template getExportcName*(): string =
  ## returns at runtime the exportc name; there may be a better way (that also works at CT)
  # TODO: add to stdlib
  block:
    var name {.inject.}: cstring
    {.emit: "`name` = __func__;".}
    $name

template myfoo2* = {.exportc.}
template myfoo3* = {.exportc: "myfoo3_in_c", discardable.}
template myfoo4* = {.discardable, myfoo2.}
template myfoo5 = {. .}

{.pragma: myfoo0a, exportc: "myfoo0_in_c".}
# export myfoo0a # works even if not exported
template myfoo0b* = {.cdecl.}

template myfoo6* = {.myfoo0a, myfoo0b, discardable.}

# this won't be hijacked
template myfooHijacked = {.exportc: "myfooHijacked_orig".}
template myfooHijacked_wrap* = {.myfooHijacked.}

export myfoo5
