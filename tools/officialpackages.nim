import std/[strformat, paths, dirs, envvars]
from std/os import execShellCmd

proc exec*(cmd: string, errorcode: int = QuitFailure, additionalPath = "") =
  let prevPath = getEnv("PATH")
  if additionalPath.len > 0:
    var absolute = Path(additionalPath)
    if not absolute.isAbsolute:
      absolute = getCurrentDir() / absolute
    echo("Adding to $PATH: ", string(absolute))
    putEnv("PATH", (if prevPath.len > 0: prevPath & PathSep else: "") & string(absolute))
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

proc gitClonePackages*(names: seq[string]) =
  if not dirExists(Path"pkgs"):
    createDir(Path"pkgs")
  for name in names:
    if not dirExists(Path"pkgs" / Path(name)):
      exec fmt"git clone https://github.com/nim-lang/{name} pkgs/{name}"
