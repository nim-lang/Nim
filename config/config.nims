# this config.nims also needs to exist to prevent future regressions, see #9990

when defined(nimHasCppDefine):
  cppDefine "errno"
  cppDefine "unix"

when false:
 block: # warnings
  #[
  ## ignore typical warnings in Nim-generated files

  ## reference:
  https://clang.llvm.org/docs/DiagnosticsReference.html

  ## useful warnings:
    -Wunknown-warning-option
    -Weverything

  ## To pass the test suite, `-Werror` would require the following adjustments:
  -Werror -Wno-error=parentheses -Wno-error=deprecated-declarations -Wno-error=int-to-void-pointer-cast -Wno-error=ignored-attributes -Wno-error=incompatible-pointer-types -Wno-error=compare-distinct-pointer-types -Wno-error=incompatible-library-redeclaration

  ## suspicious warnings for which we should fix code instead of ignoring warning:
  -Wno-tautological-constant-out-of-range-compare
  -Wno-switch-bool: occurs for object variants with bool switch, eg btrees.Node
  -Wno-incompatible-pointer-types-discards-qualifiers: will prevent 
    `--passC:-Wwrite-strings` from giving warning for `char*s = "foo"
    which can indicate a real bug, but cgen also generates a lot of these
  ]#

  let clangWarningsCommon = "-Wno-logical-op-parentheses -Wno-invalid-noreturn -Wno-tautological-constant-out-of-range-compare -Wno-switch-bool"

  let clangWarningsC = clangWarningsCommon & " -Wno-incompatible-pointer-types-discards-qualifiers"

  let clangWarningsCpp = clangWarningsCommon & " -Wno-writable-strings -Wno-invalid-offsetof"

  let gccWarnings = " "

  for cc in ["clang"]:
    switch(cc & ".options.warnings", clangWarningsC)
    switch(cc & ".cpp.options.warnings", clangWarningsCpp)

  block: # vcc
    let vccWarnings = "/wd4005 /wd4100 /wd4101 /wd4189 /wd4191 /wd4200 /wd4244 /wd4293 /wd4296 /wd4309 /wd4310 /wd4365 /wd4456 /wd4477 /wd4514 /wd4574 /wd4611 /wd4668 /wd4702 /wd4706 /wd4710 /wd4711 /wd4774 /wd4800 /wd4809 /wd4820 /wd4996 /wd4090 /wd4297"
    switch("vcc.options.warnings", vccWarnings)

    when defined(vcc):
      switch("passc", "/w")
    else:
      switch("passc", "-w")
