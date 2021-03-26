discard """
  cmd: "nim check --hints:on --experimental:strictFuncs --experimental:views -d:nimExperimentalViews compiler/nim.nim"
  action: "compile"
"""

# xxx pending bug #8644, no need to pass `-d:nimExperimentalViews` and affected
# code will be able to use `compileOption` or compilesettings API.
