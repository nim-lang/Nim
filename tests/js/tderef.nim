discard """
  output: '''true
'''
"""

import tables

type EventStore = Table[string, seq[proc ()]]

proc newEventStore(): EventStore =
  initTable[string, seq[proc ()]]()

proc register(store: var EventStore, name: string, callback: proc ()) =
  if not store.hasKey(name):
    store[name] = @[]
  store[name].add(callback)

var store = newEventStore()
store.register("test", proc () = echo "true")
store["test"][0]()
