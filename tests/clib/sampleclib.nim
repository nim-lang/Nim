when compileOption("app", "lib"):
  # dynlib -> dllexport
  proc sampleclibAdd(a, b: int): int {.cdecl, exportc: "sampleclib_add", dynlib.} =
    a + b
elif compileOption("app", "staticlib"):
  proc sampleclibAdd(a, b: int): int {.cdecl, exportc: "sampleclib_add".} =
    a + b
else:
  {.error: "missing --app:lib or --app:staticlib compile option".}
