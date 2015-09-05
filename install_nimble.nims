
mode = ScriptMode.Verbose

var id = 0
while dirExists("nimble" & $id):
  inc id

exec "git clone https://github.com/nim-lang/nimble.git nimble" & $id

withDir "nimble" & $id & "/src":
  exec "nim c nimble"

mvFile "nimble" & $id & "/src/nimble".toExe, "bin/nimble".toExe
