
template htmlTag(tag: expr) {.immediate.} =
  proc tag(): string = "<" & astToStr(tag) & ">"

htmlTag(br)
htmlTag(html)

echo br()
