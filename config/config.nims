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

when (NimMajor, NimMinor) >= (1, 5) and (NimMinor mod 2) == 1:
  # We enable these in devel; the stable release in which these will be enabled is not yet specified.
  # These flags be overridden using user/project/cmdline flags using `switch("undef", "nimPreviewX")`
  # other `nimPreview` switches can go here, as needed.
  switch("define", "nimPreviewFloatRoundtrip")
  switch("define", "nimPreviewDotLikeOps")
