
import ospaths

mode = ScriptMode.Verbose

if not dirExists"dist/nimble":
  echo "[Error] This script only works for the tarball."
else:
  let nimbleExe = "./bin/nimble".toExe
  selfExec "c --noNimblePath -p:compiler -o:" & nimbleExe &
      " dist/nimble/src/nimble.nim"

  let nimsugExe = "./bin/nimsuggest".toExe
  selfExec "c --noNimblePath -p:compiler -o:" & nimsugExe &
      " dist/nimsuggest/nimsuggest.nim"

  let nimgrepExe = "./bin/nimgrep".toExe
  selfExec "c -o:./bin/nimgrep tools/nimgrep.nim"
