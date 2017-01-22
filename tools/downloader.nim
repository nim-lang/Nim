
# Test & show the new high level wrapper

import
  "../ui", asyncdispatch, httpclient, zip/zipfiles, os

type
  Actions = object
    addToPath, startMenu, mingw, aporia: bool
  Controls = object
    apply: Button
    bar: ProgressBar
    lab: Label

const arch = $(sizeof(int)*8)

proc download(pkg: string; c: Controls) {.async.} =
  c.bar.value = 0
  var client = newAsyncHttpClient()
  proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    c.lab.text = "Downloading " & pkg & " " & $(speed div 1000) & "kb/s"
    c.bar.value = clamp(int(progress*100 div total), 0, 100)

  client.onProgressChanged = onProgressChanged
  # XXX give a destination filename instead
  let contents = await client.getContent("http://nim-lang.org/download/" & pkg & ".zip")
  let z = "dist" / pkg & ".zip"
  # XXX make this async somehow:
  writeFile(z, contents)
  c.bar.value = 100
  when false:
    var a: ZipArchive
    if open(a, z, fmRead):
      extractAll(a, "dist")
      close(a)
    else:
      c.lab.text = "Error: cannot open: " & z

proc apply(a: Actions; c: Controls) {.async.} =
  if a.mingw:
    await download("mingw" & arch, c)
  if a.aporia:
    await download("aporia-0.4.0", c)
    if a.startMenu:
      discard "add start menu entry"

  c.apply.text = "Quit"

proc main() =
  var mainwin = newWindow("Nim installer", 640, 480, true)
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
