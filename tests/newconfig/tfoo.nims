
mode = ScriptMode.Whatif

exec "gcc -v"

--forceBuild

task listDirs, "lists every subdirectory":
  for x in listDirs("."):
    echo "DIR ", x

task default, "default target":
  setCommand "c"

