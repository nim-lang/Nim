
mode = ScriptMode.Whatif

exec "gcc -v"

# test that ospaths actually compiles:
import ospaths

--forceBuild
--path: "../friends"

warning("uninit", off)
hint("processing", off)
#--verbosity:2
patchFile("stdlib", "math", "mymath")

task listDirs, "lists every subdirectory":
  for x in listDirs("."):
    echo "DIR ", x

task default, "default target":
  --define: definedefine
  setCommand "c"

# bug #6327
discard existsEnv("dummy")
