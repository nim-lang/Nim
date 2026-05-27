import std/os

let nimbleDir = currentSourcePath.parentDir / "nimbleDir" / "simplePkgs"

switch("clearNimblePath")
switch("nimblePath", nimbleDir)
switch("path", nimbleDir / "pkgA-0.1.0")
switch("path", nimbleDir / "pkgB-#head")
switch("path", nimbleDir / "pkgC-#head")
