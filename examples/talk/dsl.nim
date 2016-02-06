
import strutils

template html(name: expr, matter: stmt) {.immediate.} =
  proc name(): string =
    result = "<html>"
    matter
    result.add("</html>")

template nestedTag(tag: expr) {.immediate.} =
  template tag(matter: stmt) {.immediate.} =
    result.add("<" & astToStr(tag) & ">")
    matter
    result.add("</" & astToStr(tag) & ">")

template simpleTag(tag: expr) {.immediate.} =
  template tag(matter: expr) {.immediate.} =
    result.add("<$1>$2</$1>" % [astToStr(tag), matter])

nestedTag body
nestedTag head
nestedTag ul
simpleTag title
simpleTag li

html mainPage:
  head:
    title "now look at this"
  body:
    ul:
      li "Nim is quite capable"

echo mainPage()
