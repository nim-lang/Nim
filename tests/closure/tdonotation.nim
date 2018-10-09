discard """
output: '''
click at 10,20
lost focus 1
lost focus 2
registered handler for UserEvent 1
registered handler for UserEvent 2
registered handler for UserEvent 3
registered handler for UserEvent 4
'''
"""

import future

type
  Button = object
  Event = object
    x, y: int

proc onClick(x: Button, handler: proc(x: Event)) =
  handler(Event(x: 10, y: 20))

proc onFocusLost(x: Button, handler: proc()) =
  handler()

proc onUserEvent(x: Button, eventName: string, handler: proc) =
  echo "registered handler for ", eventName

var b = Button()

b.onClick do (e: Event):
  echo "click at ", e.x, ",", e.y

b.onFocusLost:
  echo "lost focus 1"

b.onFocusLost do:
  echo "lost focus 2"

b.onUserEvent("UserEvent 1") do:
  discard

b.onUserEvent "UserEvent 2":
  discard

b.onUserEvent("UserEvent 3"):
  discard

b.onUserEvent("UserEvent 4", () => echo "event 4")

