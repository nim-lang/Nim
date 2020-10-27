import dom
import jsffi

let localStorage {.importc, nodecl.}: LocalStorage
let documentDocumentElement {.importc: "document.documentElement",
    nodecl.}: Element
let documentDocumentElementDataset {.importc: "document.documentElement.dataset",
    nodecl.}: JSObject

proc main* {.exportc.} =
  let toggleSwitch = document.querySelector(""".theme-switch input[type="checkbox"]""")
  let currentTheme = localStorage.getItem("theme")


  if (not currentTheme.isNull()):
    documentDocumentElementDataset.theme = currentTheme

    if currentTheme == "dark" and not toggleSwitch.isNull():
      toggleSwitch.checked = true

  if not toggleSwitch.isNull():
    toggleSwitch.addEventListener("change", proc (event: Event) =
      let eventTarget = cast[JSObject](event).target
      let checked: bool = cast[bool](eventTarget.checked)
      let theme = if checked: "dark" else: "light"

      documentDocumentElementDataset.theme = theme
      localStorage.setItem("theme", theme),
      false)

  let pragmaDots = document.getElementsByClassName("pragmadots")

  for item in pragmaDots:
    item.addEventListener("click", proc (event: Event) =
      # Hide tease
      # event.target.parentNode.style.display = "none";
      cast[JSObject](event.target).parentNode.style.display = "none";
      # Show actual
      cast[JSObject](event.target).parentNode.nextElementSibling.style.display = "inline";
    ,
    false)
