

proc p*(f = (proc(): string = "hi")) =
  echo f()

