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

switch("define", "nimVersion:" & NimVersion)

when defined(solo5):
  const solo5tender {.strdefine.}: string = "hvt"
    # Select the tender type. This is does not affect the build, only the link.

  proc isFlags(s: string): bool = s.len > 0 and s[0] == '-'
  block:
    let passC = staticExec("pkg-config --cflags solo5-bindings-" & solo5tender)
    if not passC.isFlags: quit(passC)
    switch("passC", passC)
  block:
    let passL = staticExec("pkg-config --variable=ldflags solo5-bindings-" & solo5tender)
    if not passL.isFlags: quit(passL)
    switch("passL", passL)
