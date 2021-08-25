# this config.nims also needs to exist to prevent future regressions, see #9990

cppDefine "errno"
cppDefine "unix"

when defined(nimStrictMode):
  # xxx add more flags here, and use `-d:nimStrictMode` in more contexts in CI.

  # pending bug #14246, enable this:
  # when defined(nimHasWarningAsError):
  #   switch("warningAsError", "UnusedImport")

  when defined(nimHasHintAsError):
    # switch("hint", "ConvFromXtoItselfNotNeeded")
    switch("hintAsError", "ConvFromXtoItselfNotNeeded")
    # future work: XDeclaredButNotUsed

when (NimMajor, NimMinor) >= (1, 7):
  # consider using instead: `when (NimMajor, NimMinor) > (1,4) and (NimMajor, NimMinor) != (1,6)`
  # to make those flags available in devel but not 1.6.
  # These flags be overridden using user/project/cmdline flags using `switch("undef", "nimPreviewX")`
  # other `nimPreview` switches can go here, as needed.
  switch("define", "nimPreviewFloatRoundtrip")
