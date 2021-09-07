discard """
  cmd: '''nim c --newruntime $file'''
  errormsg: "'=copy' is not available for type <owned Button>; requires a copy because it's not the last read of ':envAlt.b1'; another read is done here: tuse_ownedref_after_move.nim(52, 4)"
  line: 48
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
  proc draw2(self: Widget) = # draw2=>draw would run into #18785 with nimLazySemcheck
    let b = Button(self)
    echo b.caption

  result = Button(drawImpl: draw2, caption: caption, onclick: onclick)

proc newWindow(): owned Window =
  proc draw2(self: Widget) =
    let w = Window(self)
    for e in w.elements:
      if not e.drawImpl.isNil: e.drawImpl(e)

  result = Window(drawImpl: draw2, elements: @[])

proc draw(w: Widget) =
  if not w.drawImpl.isNil: w.drawImpl(w)

proc add*(w: Window; elem: owned Widget) =
  w.elements.add elem

proc main =
  var w = newWindow()

  var b = newButton("button", nil)
  b.onclick = proc () =
    b.caption = "clicked!"
  w.add b

  w.draw()
  # simulate button click:
  b.onclick()

  w.draw()

main()

