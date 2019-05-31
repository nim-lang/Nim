# this config.nims also needs to exist to prevent future regressions, see #9990

when defined(nimHasCppDefine):
  cppDefine "errno"
