# this config.nims also needs to exist to prevent future regressions, see #9990

when defined(nimHasCppDefine):
  cppDefine "errno"
  cppDefine "unix"

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

  let vccWarnings = "4005 4100 4101 4189 4191 4200 4244 4293 4296 4309 4310 4365 4456 4477 4514 4574 4611 4668 4702 4706 4710 4711 4774 4800 4809 4820 4996 4090 4297"

  switch("vcc.options.warnings", vccWarnings)

  for cc in ["clang", "gcc"]:
    switch(cc & ".options.warnings", clangWarningsC)
    switch(cc & ".cpp.options.warnings", clangWarningsCpp)
