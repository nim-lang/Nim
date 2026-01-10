proc test2() {.raises: [].} =
  raise newException(ValueError, "error")
