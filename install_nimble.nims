
import ospaths

mode = ScriptMode.Verbose

var id = 0
while dirExists("nimble" & $id):
  inc id

exec "git clone https://github.com/nim-lang/nimble.git nimble" & $id

withDir "nimble" & $id & "/src":
  exec "nim c nimble"

mkDir "bin/nimblepkg"
for file in listFiles("nimble" & $id & "/src/nimblepkg/"):
  cpFile file, "bin/nimblepkg/" & file.extractFilename

mvFile "nimble" & $id & "/src/nimble".toExe, "bin/nimble".toExe
