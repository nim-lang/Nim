import nake
nakeimports

const
  ServerDefines = "-d:NoSFML --forceBuild"

task "server", "build the server":
  if shell("nim", ServerDefines, "-r", "compile", "enet_server") != 0:
    quit "Failed to build"
task "gui", "build the server GUI mode":
  if shell("nim", "--app:gui", ServerDefines, "-r", "compile", "enet_server") != 0:
    quit "Failed to build"

