import exposed

proc testSuspendAndResume*() =
  suspend() # will raise
  echo "resumed"
