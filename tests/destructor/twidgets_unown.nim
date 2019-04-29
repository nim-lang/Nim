discard """
  cmd: '''nim c --newruntime $file'''
  output: '''button
clicked!
3 3  alloc/dealloc pairs: 0'''
"""

import core / allocators
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
  b.onclick = proc () =
    b.caption = "clicked!"
  w.add b

  w.draw()
  # simulate button click:
  u.onclick()

  w.draw()

main()

let (a, d) = allocCounters()
discard cprintf("%ld %ld  alloc/dealloc pairs: %ld\n", a, d, allocs)
