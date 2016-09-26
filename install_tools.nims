
import ospaths

mode = ScriptMode.Verbose

let nimbleExe = "./bin/nimble".toExe
selfExec "c --noNimblePath -p:compiler -o:" & nimbleExe &
    " dist/nimble/src/nimble.nim"

let nimsugExe = "./bin/nimsuggest".toExe
selfExec "c --noNimblePath -p:compiler -o:" & nimsugExe &
    " dist/nimsuggest/nimsuggest.nim"

let nimgrepExe = "./bin/nimgrep".toExe
selfExec "c -o:./bin/nimgrep tools/nimgrep.nim"
