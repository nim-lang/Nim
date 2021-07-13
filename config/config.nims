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

when (NimMajor, NimMinor) == (1,6) or (NimMajor, NimMinor) <= (1,4):
  # if/when 1.8 comes around, edit this logic as needed individually for each flag.
  # these can be overridden using user/project/cmdline flags using `switch("undef", "nimLegacyX")`
  # other `nimLegacy` switches can go here, as needed.
  switch("define", "nimLegacyHomeDir")
