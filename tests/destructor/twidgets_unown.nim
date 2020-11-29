discard """
  cmd: '''nim c -d:nimAllocStats --newruntime $file'''
  output: '''button
clicked!
(allocCount: 6, deallocCount: 6)'''
"""

import system / ansi_c

type
  Widget* = ref object of RootObj
    drawImpl: owned(proc (self: Widget))

  Button* = ref object of Widget
    caption: string
    onclick: owned(proc())

  Window* = ref object of Widget
    elements: seq[owned Widget]


proc newButton(caption: string; onclick: owned(proc())): owned Button =
  proc draw(self: Widget) =
    let b = Button(self)
    echo b.caption

  #result = Button(drawImpl: draw, caption: caption, onclick: onclick)
  new(result)
  result.drawImpl = draw
  result.caption = caption
  result.onclick = onclick

proc newWindow(): owned Window =
  proc windraw(self: Widget) =
    let w = Window(self)
    for e in unown(w.elements):
      let d = unown e.drawImpl
      if not d.isNil: d(e)

  result = Window(drawImpl: windraw, elements: @[])

proc draw(w: Widget) =
  let d = unown w.drawImpl
  if not d.isNil: d(w)

proc add*(w: Window; elem: owned Widget) =
  w.elements.add elem

proc main =
  var w = newWindow()

  var b = newButton("button", nil)
  let u = unown b
  var clicked = "clicked"
  b.onclick = proc () =
    clicked.add "!"
    u.caption = clicked
  w.add b

  w.draw()
  # simulate button click:
  u.onclick()

  w.draw()

  # bug #11257
  var a: owned proc()
  if a != nil:
    a()

dumpAllocStats:
  main()
