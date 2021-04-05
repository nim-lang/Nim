proc getProcname*(): string {.magic: "GetProcname".} =
  ## Returns the name of a proc or a macro. It cannot be used
  ## in the top level.
