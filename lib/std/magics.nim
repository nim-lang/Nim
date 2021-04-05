proc getProcname*(): string {.magic: "GetProcname".} =
  ## Returns the names of procs/macros. It cannot be used
  ## in the top level.
