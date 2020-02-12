discard """
  cmd: '''nim c -d:nimAllocStats --newruntime $file'''
  output: '''button
clicked!
(allocCount: 4, deallocCount: 4)'''
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

iterator unitems*[T](a: seq[owned T]): T {.inline.} =
  ## Iterates over each item of `a`.
  var i = 0
  let L = len(a)
  while i < L:
    yield a[i]
    inc(i)
    assert(len(a) == L, "the length of the seq changed while iterating over it")

proc newWindow(): owned Window =
  proc windraw(self: Widget) =
    let w = Window(self)
    for i in 0..<len(w.elements):
      let e = Widget(w.elements[i])
      let d = (proc(self: Widget))e.drawImpl
      if not d.isNil: d(e)

  result = Window(drawImpl: windraw, elements: @[])

proc draw(w: Widget) =
  let d = (proc(self: Widget))w.drawImpl
  if not d.isNil: d(w)

proc add*(w: Window; elem: owned Widget) =
  w.elements.add elem

proc main =
  var w = newWindow()

  var b = newButton("button", nil)
  let u: Button = b
  b.onclick = proc () =
    u.caption = "clicked!"
  w.add b

  w.draw()
  # simulate button click:
  u.onclick()

  w.draw()

dumpAllocstats:
  main()

