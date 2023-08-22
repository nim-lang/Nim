discard """
  output: "<html><head><title>now look at this</title></head><body><ul><li>Nim is quite capable</li></ul></body></html>"
"""

import strutils

template html(name, matter: untyped) =
  proc name(): string =
    result = "<html>"
    matter
    result.add("</html>")

template nestedTag(tag: untyped) =
  template tag(matter: untyped) =
    result.add("<" & astToStr(tag) & ">")
    matter
    result.add("</" & astToStr(tag) & ">")

template simpleTag(tag: untyped) =
  template tag(matter: untyped) =
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
