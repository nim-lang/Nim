discard """
  action: run
  cmd: "nim $target --nimblePath:$fileDir/nimbleDir/linkedPkgs $options $file"
"""
import pkgA/module as A
import pkgB/module as B

doAssert pkgATest() == 1, "Simple linked pkgA-0.1.0 wasn't added to path correctly."
doAssert pkgBTest() == 0xDEADBEEF, "linked pkgB-#head wasn't picked over pkgB-0.1.0"