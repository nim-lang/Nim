import
  sfml, sfml_colors,
  input_helpers, sg_packets
from strutils import countlines

type
  PGuiContainer* = ref TGuiContainer
  TGuiContainer* = object of RootObj
    position: TVector2f
    activeEntry: PTextEntry
    widgets: seq[PGuiObject]
    buttons: seq[PButton]
  PGuiObject* = ref TGuiObject
  TGuiObject* = object of RootObj
  PButton* = ref TButton
  TButton* = object of TGuiObject
    enabled: bool
    bg*: sfml.PRectangleShape
    text*: PText
    onClick*: TButtonClicked
    bounds: TFloatRect
  PButtonCollection* = ref TButtonCollection
  TButtonCollection* = object of TGuiContainer
  PTextEntry* = ref TTextEntry
  TTextEntry* = object of TButton
    inputClient: input_helpers.PTextInput
  PMessageArea* = ref TMessageArea
  TMessageArea* = object of TGuiObject
    pos: TVector2f
    messages: seq[TMessage]
    texts: seq[PText]
    scrollBack*: int
    sizeVisible*: int
    direction*: int
  TMessage = object
    color: TColor
    text: string
    lines: int
  TButtonClicked = proc(button: PButton)
var
  guiFont* = newFont("data/fnt/LiberationMono-Regular.ttf")
  messageProto* = newText("", guiFont, 16)
let
  vectorZeroF* = vec2f(0.0, 0.0)

proc newGuiContainer*(): PGuiContainer
proc newGuiContainer*(pos: TVector2f): PGuiContainer {.inline.}
proc free*(container: PGuiContainer)
proc add*(container: PGuiContainer; widget: PGuiObject)
proc clearButtons*(container: PGuiContainer)
proc click*(container: PGuiContainer; position: TVector2f)
proc setActive*(container: PGuiContainer; entry: PTextEntry)
proc setPosition*(container: PGuiContainer; position: TVector2f)

proc update*(container: PGuiContainer; dt: float)
proc draw*(window: PRenderWindow; container: PGuiContainer) {.inline.}

proc newMessageArea*(container: PGuiContainer; position: TVector2f): PMessageArea {.discardable.}
proc add*(m: PMessageArea; msg: ScChat)

proc draw*(window: PRenderWindow; b: PButton) {.inline.}
proc click*(b: PButton; p: TVector2f)
proc setPosition*(b: PButton; p: TVector2f)
proc setString*(b: PButton; s: string) {.inline.}

proc newButton*(container: PGuiContainer; text: string; position: TVector2f;
  onClick: TButtonClicked; startEnabled: bool = true): PButton {.discardable.}
proc init(b: PButton; text: string; position: TVector2f; onClick: TButtonClicked)
proc setEnabled*(b: PButton; enabled: bool)
proc disable*(b: PButton) {.inline.}
proc enable*(b: PButton) {.inline.}

proc newTextEntry*(container: PGuiContainer; text: string;
                    position: TVector2f; onEnter: TInputFinishedProc = nil): PTextEntry {.discardable.}
proc init(t: PTextEntry; text: string; onEnter: TInputFinishedProc)
proc draw*(window: PRenderWindow, t: PTextEntry) {.inline.}
proc setActive*(t: PTextEntry) {.inline.}
proc clearText*(t: PTextEntry) {.inline.}
proc getText*(t: PTextEntry): string {.inline.}

proc update*(m: PMessageArea)

if guiFont == nil:
  echo("Could not load font, crying softly to myself.")
  quit(1)

proc newGuiContainer*(): PGuiContainer =
  new(result, free)
  result.widgets = @[]
  result.buttons = @[]
proc newGuiContainer*(pos: TVector2f): PGuiContainer =
  result = newGuiContainer()
  result.setPosition pos
proc free*(container: PGuiContainer) =
  container.widgets = @[]
  container.buttons = @[]
proc add*(container: PGuiContainer; widget: PGuiObject) =
  container.widgets.add(widget)
proc add*(container: PGuiContainer; button: PButton) =
  if container.isNil: return
  container.buttons.add(button)
proc clearButtons*(container: PGuiContainer) =
  container.buttons.setLen 0
proc click*(container: PGuiContainer; position: TVector2f) =
  for b in container.buttons:
    click(b, position)
proc setActive*(container: PGuiContainer; entry: PTextEntry) =
  container.activeEntry = entry
  setActive(entry)
proc setPosition*(container: PGuiContainer; position: TVector2f) =
  container.position = position


proc update*(container: PGuiContainer; dt: float) =
  if not container.activeEntry.isNil:
    container.activeEntry.setString(container.activeEntry.getText())
proc draw*(window: PRenderWindow; container: PGuiContainer) =
  for b in container.buttons:
    window.draw b

proc free(c: PButton) =
  c.bg.destroy()
  c.text.destroy()
  c.bg = nil
  c.text = nil
  c.onClick = nil
proc newButton*(container: PGuiContainer; text: string;
                 position: TVector2f; onClick: TButtonClicked;
                 startEnabled: bool = true): PButton =
  new(result, free)
  init(result,
       text,
       if not container.isNil: position + container.position else: position,
       onClick)
  container.add result
  if not startEnabled: disable(result)

proc init(b: PButton; text: string; position: TVector2f; onClick: TButtonClicked) =
  b.bg = newRectangleShape()
  b.bg.setSize(vec2f(80.0, 16.0))
  b.bg.setFillColor(color(20, 30, 15))
  b.text = newText(text, guiFont, 16)
  b.onClick = onClick
  b.setPosition(position)
  b.enabled = true
proc copy*(c: PButton): PButton =
  new(result, free)
  result.bg = c.bg.copy()
  result.text = c.text.copy()
  result.onClick = c.onClick
  result.setPosition(result.bg.getPosition())

proc setEnabled*(b: PButton; enabled: bool) =
  b.enabled = enabled
  if enabled:
    b.text.setColor(White)
  else:
    b.text.setColor(Gray)
proc enable*(b: PButton) = setEnabled(b, true)
proc disable*(b: PButton) = setEnabled(b, false)

proc draw*(window: PRenderWindow; b: PButton) =
  window.draw b.bg
  window.draw b.text
proc setPosition*(b: PButton, p: TVector2f) =
  b.bg.setPosition(p)
  b.text.setPosition(p)
  b.bounds = b.text.getGlobalBounds()
proc setString*(b: PButton; s: string) =
  b.text.setString(s)
proc click*(b: PButton, p: TVector2f) =
  if b.enabled and (addr b.bounds).contains(p.x, p.y):
    b.onClick(b)

proc free(obj: PTextEntry) =
  free(PButton(obj))
proc newTextEntry*(container: PGuiContainer; text: string;
                    position: TVector2F; onEnter: TInputFinishedProc = nil): PTextEntry =
  new(result, free)
  init(PButton(result), text, position + container.position, proc(b: PButton) =
    setActive(container, PTextEntry(b)))
  init(result, text, onEnter)
  container.add result
proc init(t: PTextEntry; text: string; onEnter: TInputFinishedProc) =
  t.inputClient = newTextInput(text, text.len, onEnter)
proc draw(window: PRenderWindow; t: PTextEntry) =
  window.draw PButton(t)
proc clearText*(t: PTextEntry) =
  t.inputClient.clear()
proc getText*(t: PTextEntry): string =
  return t.inputClient.text
proc setActive*(t: PTextEntry) =
  if not t.isNil and not t.inputClient.isNil:
    input_helpers.setActive(t.inputClient)

when false:
  proc newMessageArea*(container: PGuiContainer; position: TVector2f): PMessageArea =
    new(result)
    result.messages = @[]
    result.pos = position
    container.add(result)
  proc add*(m: PMessageArea, text: string): PText =
    result = messageProto.copy()
    result.setString(text)
    m.messages.add(result)
    let nmsgs = len(m.messages)
    var pos   = vec2f(m.pos.x, m.pos.y)
    for i in countdown(nmsgs - 1, max(nmsgs - 30, 0)):
      setPosition(m.messages[i], pos)
      pos.y -= 16.0

  proc draw*(window: PRenderWindow; m: PMessageArea) =
    let nmsgs = len(m.messages)
    if nmsgs == 0: return
    for i in countdown(nmsgs - 1, max(nmsgs - 30, 0)):
      window.draw(m.messages[i])

proc newMessageArea*(container: PGuiContainer; position: TVector2f): PMessageArea =
  new(result)
  result.messages = @[]
  result.texts = @[]
  result.pos = position + container.position
  result.sizeVisible = 10
  result.scrollBack = 0
  result.direction = -1 ## to push old messages up
  container.add(result)

proc add*(m: PMessageArea, msg: ScChat) =
  const prependName = {CPub, CPriv}
  var mmm: TMessage
  if msg.kind in prependName:
    mmm.text = "<"
    mmm.text.add msg.fromPlayer
    mmm.text.add "> "
    mmm.text.add msg.text
  else:
    mmm.text = msg.text
  case msg.kind
  of CPub:  mmm.color = RoyalBlue
  of CPriv, CSystem: mmm.color = Green
  of CError: mmm.color = Red

  mmm.lines = countLines(mmm.text)

  m.messages.add mmm
  update m
proc add*(m: PMessageArea, msg: string) {.inline.} =
  var chat = newScChat(kind = CSystem, text = msg)
  add(m, chat)

proc proctor*(m: PText; msg: ptr TMessage; pos: ptr TVector2f) =
  m.setString msg.text
  m.setColor msg.color
  m.setPosition pos[]
proc update*(m: PMessageArea) =
  if m.texts.len < m.sizeVisible:
    echo "adding ", m.sizeVisible - m.texts.len, " fields"
    for i in 1..m.sizeVisible - m.texts.len:
      var t = messageProto.copy()
      m.texts.add messageProto.copy()
  elif m.texts.len > m.sizeVisible:
    echo "cutting ", m.texts.len - m.sizeVisible, " fields"
    for i in m.sizeVisible ..< m.texts.len:
      m.texts.pop().destroy()
  let nmsgs = m.messages.len()
  if m.sizeVisible == 0 or nmsgs == 0:
    echo "no messages? ", m.sizeVisible, ", ", nmsgs
    return
  var pos = vec2f(m.pos.x, m.pos.y)
  for i in 0.. min(m.sizeVisible, nmsgs)-1:
    ##echo nmsgs - i - 1 - m.scrollBack
    let msg = addr m.messages[nmsgs - i - 1 - m.scrollBack]
    proctor(m.texts[i], msg, addr pos)
    pos.y += (16 * m.direction * msg.lines).cfloat

proc draw*(window: PRenderWindow; m: PMessageArea) =
  let nmsgs = len(m.texts)
  if nmsgs == 0: return
  for i in countdown(nmsgs - 1, max(nmsgs - m.sizeVisible, 0)):
    window.draw m.texts[i]

