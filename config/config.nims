# this config.nims also needs to exist to prevent future regressions, see #9990

cppDefine "errno"
cppDefine "unix"

# mangle the macro names in nimbase.h
cppDefine "NAN_INFINITY"
cppDefine "INF"
cppDefine "NAN"

when defined(nimStrictMode):
  # xxx add more flags here, and use `-d:nimStrictMode` in more contexts in CI.

  # pending bug #14246, enable this:
  # when defined(nimHasWarningAsError):
  #   switch("warningAsError", "UnusedImport")

  when defined(nimHasHintAsError):
    # switch("hint", "ConvFromXtoItselfNotNeeded")
    switch("hintAsError", "ConvFromXtoItselfNotNeeded")
    # future work: XDeclaredButNotUsed

when defined(windows) and not defined(booting):
  # Avoid some rare stack corruption while using exceptions with a SEH-enabled
  # toolchain: https://github.com/nim-lang/Nim/pull/19197
  switch("define", "nimRawSetjmp")

switch("define", "nimVersion:" & NimVersion)
