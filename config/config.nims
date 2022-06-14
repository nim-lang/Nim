# this config.nims also needs to exist to prevent future regressions, see #9990

when defined(nimHasCppDefine):
  cppDefine "errno"
  cppDefine "unix"

# mangle the macro names in nimbase.h
cppDefine "NAN_INFINITY"
cppDefine "INF"
cppDefine "NAN"

when defined(windows) and not defined(booting):
  # Avoid some rare stack corruption while using exceptions with a SEH-enabled
  # toolchain: https://github.com/nim-lang/Nim/pull/19197
  switch("define", "nimRawSetjmp")
