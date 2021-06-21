## Helper that is run after Nim's installation.

## We download mirror'ed mingw packages. The originals came from:
##
## https://sourceforge.net/projects/mingw-w64/files/Toolchains%20
##   targetting%20Win32/Personal%20Builds/mingw-builds/6.3.0/threads-win32/
##   dwarf/i686-6.3.0-release-win32-dwarf-rt_v5-rev1.7z/download
## https://sourceforge.net/projects/mingw-w64/files/Toolchains%20
##   targetting%20Win64/Personal%20Builds/mingw-builds/6.3.0/threads-win32/
##   seh/x86_64-6.3.0-release-win32-seh-rt_v5-rev1.7z/download
##


import
  ui, asyncdispatch, httpclient, os, finish, registry, strutils, osproc

type
  Actions = object
    addToPath, startMenu, mingw, aporia: bool
  Controls = object
    apply: Button
    bar: ProgressBar
    lab: Label

const arch = $(sizeof(int)*8)

proc download(pkg: string; c: Controls) {.async.} =
  let z = r"..\dist" / pkg & ".7z"
  if fileExists(z):
    c.lab.text = z & " already exists"
    return
  c.bar.value = 0
  var client = newAsyncHttpClient()
  proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    c.lab.text = "Downloading " & pkg & " " & $(speed div 1000) & "kb/s"
    c.bar.value = clamp(int(progress*100 div total), 0, 100)

  client.onProgressChanged = onProgressChanged
  await client.downloadFile("https://nim-lang.org/download/" & pkg & ".7z", z)
  c.bar.value = 100
  let p = osproc.startProcess("7zG.exe", getCurrentDir() / r"..\dist",
                              ["x", pkg & ".7z"])
  if p.waitForExit != 0:
    c.lab.text = "Unpacking failed: " & z

proc apply(a: Actions; c: Controls) {.async.} =
  if a.mingw:
    await download("mingw" & arch, c)
  if a.aporia:
    await download("aporia-0.4.0", c)

  if a.addToPath:
    let desiredPath = expandFilename(getCurrentDir() / "bin")
    let p = getUnicodeValue(r"Environment", "Path",
      HKEY_CURRENT_USER)
    var alreadyInPath = false
    for x in p.split(';'):
      if x.len == 0: continue
      let y = try: expandFilename(if x[0] == '"' and x[^1] == '"':
                                    substr(x, 1, x.len-2) else: x)
              except: ""
      if y == desiredPath: alreadyInPath = true
    if not alreadyInPath:
      addToPathEnv(desiredPath)

  if a.startMenu:
    createStartMenuEntry()

  c.apply.text = "Quit"

proc main() =
  var mainwin = newWindow("Nim installer", 640, 280, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  let box = newVerticalBox(true)
  mainwin.setChild(box)

  var groupA = newGroup("Actions", true)
  box.add(groupA, false)
  var innerA = newVerticalBox(true)
  groupA.child = innerA

  let cbAddToPath = newCheckbox("Add Nim to PATH")
  innerA.add cbAddToPath
  let cbStartMenu = newCheckbox("Create start menu entry")
  innerA.add cbStartMenu

  var groupB = newGroup("Optional Components", true)
  box.add(groupB, false)
  var innerB = newVerticalBox(true)
  groupB.child = innerB

  let cbMingw = newCheckbox("Download Mingw")
  innerB.add cbMingw

  let cbAporia = newCheckbox("Download Aporia")
  innerB.add cbAporia

  var c = Controls(
    apply: newButton("Apply"),
    bar: newProgressBar(),
    lab: newLabel(""))

  innerB.add c.apply
  innerB.add c.bar
  innerB.add c.lab

  proc apply() =
    c.apply.text = "Abort"
    asyncCheck apply(Actions(addToPath: cbAddToPath.checked,
                  startMenu: cbStartMenu.checked,
                  mingw: cbMingw.checked,
                  aporia: cbAporia.checked), c)

    c.apply.onclick = proc () =
      ui.quit()
      system.quit()

  c.apply.onclick = apply

  show(mainwin)
  pollingMainLoop((proc (timeout: int) =
    if hasPendingOperations(): asyncdispatch.poll(timeout)), 10)

init()
main()
