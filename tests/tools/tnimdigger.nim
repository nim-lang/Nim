import tools/nimdigger {.all.}

block: # parseNimGitTag
  doAssert parseNimGitTag("v1.4.2") == (1, 4, 2)
  doAssertRaises(ValueError): discard parseNimGitTag("v1.4")
  doAssertRaises(ValueError): discard parseNimGitTag("v1.4.2a")
  doAssertRaises(ValueError): discard parseNimGitTag("av1.4.2")

block: # isGitNimTag
  doAssert isGitNimTag("v1.4.2")
  doAssert not isGitNimTag("v1.4.2a")
