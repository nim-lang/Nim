# this config.nims also needs to exist to prevent future regressions, see #9990

when defined(nimHasCppDefine):
  cppDefine "errno"
  cppDefine "unix"

when defined(bsd) and defined(nimSetDefaultUsrPaths):
  switch("cincludes", "/usr/local/include")
  switch("clibdir", "/usr/local/lib")