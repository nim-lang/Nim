import nake
nakeImports

task "install", "compile and install nake binary":
  if shell("nim", "c", "nake") == 0:
    let path = getEnv("PATH").split(PathSep)
    for index, dir in pairs(path):
      echo "  ", index, ". ", dir
    echo "Where to install nake binary? (quit with ^C or quit or exit)"
    let ans = stdin.readLine().toLowerAscii
    var index = 0
    case ans
    of "q", "quit", "x", "exit":
      quit 0
    else:
      index = parseInt(ans)
    if index > path.len or index < 0:
      echo "Invalid index."
      quit 1
    moveFile "nake", path[index]/"nake"
    echo "Great success!"


