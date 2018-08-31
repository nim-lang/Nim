
template htmlTag(tag: untyped) =
  proc tag(): string = "<" & astToStr(tag) & ">"

htmlTag(br)
htmlTag(html)

echo br()
echo html()