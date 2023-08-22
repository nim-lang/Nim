# this also doesn't work (even in nims): --outdir:"$nimcache/buildTests"
import os
let buildDir = currentSourcePath().parentDir.parentDir / "buildTests"
switch("outdir", buildDir)
