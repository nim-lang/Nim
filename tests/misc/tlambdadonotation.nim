discard """
output: '''
issue #11812
issue #10899
123
issue #11367
event consumed!
'''
"""

echo "issue #11812"

proc run(a: proc()) = a()

proc main() =
  var test: int
  run(proc() = test = 0)
  run do:
    test = 0

main()


echo "issue #10899"

proc foo(x: proc {.closure.}) =
  x()

proc bar =
  var x = 123
  # foo proc = echo x     #[ ok ]#
  foo: echo x             #[ SIGSEGV: Illegal storage access. (Attempt to read from nil?) ]#

bar()

echo "issue #11367"

type

  EventCB = proc()

  Emitter = object
    cb: EventCB

  Subscriber = object
    discard

proc newEmitter(): Emitter =
  result

proc on_event(self: var Emitter, cb: EventCB) =
  self.cb = cb

proc emit(self: Emitter) =
  self.cb()

proc newSubscriber(): Subscriber =
  result

proc consume(self: Subscriber) =
  echo "event consumed!"

proc main2() =
  var emitter = newEmitter()
  var subscriber = newSubscriber()

  proc foo() =
    subscriber.consume()

  emitter.on_event() do:
    subscriber.consume()

  # this works
  # emitter.on_event(foo)

  emitter.emit()

main2()
