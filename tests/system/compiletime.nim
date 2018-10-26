import macros

# Verify that compile time commands do not change behavior when assigned to a constant

when defined(posix):
  # Note that we need an invalid command as per #9176
  const cmd = "it_is_unlikely_that_this_is_a_valid_command_on_any_system" 
  var ret1 = staticExec(cmd)
  const tmp = staticExec(cmd)
  var ret2 = tmp
  doAssert ret1 == ret2

  # Similar test for getProjectPath
  const path1 = getProjectPath()
  var path2 = getProjectPath()
  doAssert path1 == path2
