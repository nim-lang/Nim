
import ospaths

mode = ScriptMode.Verbose

echo "This script is deprecated. Use 'koch tools' instead."

if not dirExists"dist/nimble":
  echo "[Error] This script only works for the tarball."
else:
  let nimbleExe = "./bin/nimble".toExe
  selfExec "c --noNimblePath -p:compiler -o:" & nimbleExe &
      " dist/nimble/src/nimble.nim"

  let nimsugExe = "./bin/nimsuggest".toExe
  selfExec "c --noNimblePath -d:release -p:compiler -o:" & nimsugExe &
      " dist/nimsuggest/nimsuggest.nim"

  let nimgrepExe = "./bin/nimgrep".toExe
  selfExec "c -d:release -o:" & nimgrepExe & " tools/nimgrep.nim"
