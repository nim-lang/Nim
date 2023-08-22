
import nimblepkg/tools

when isMainModule:
  let current_version = doCmdEx("nim -v").output
  echo $current_version