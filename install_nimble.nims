
mode = ScriptMode.Verbose

var id = 0
while dirExists("nimble" & $id) and not dirExists("nimble" & $id & "/.git"):
  inc id

let repoDir = "nimble" & $id

if dirExists(repoDir):
  withDir repoDir:
    exec "git pull origin master"
else:
  exec "git clone https://github.com/nim-lang/nimble.git " & repoDir

withDir repoDir:
  exec "nim c -o:" & "nimble1".toExe & " src/nimble"
  exec "src/nimble1 install -y"
