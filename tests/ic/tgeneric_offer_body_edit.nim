discard """
  description: '''IC: consumers of generic type offers track the instantiating module'''
"""

#? metamorphic

# A private body edit can renumber a generic instance without changing any
# public signature or hook registration. Reusing that instance embeds its
# defining module's type ID, so the consumer needs an implementation edge.

#!FLAGS --mm:arc

#!FILE types.nim
type Box*[T] = object
  value*: T

#!FILE producer.nim
import types
proc make*(): int =
  let x = Box[int](value: 42)
  x.value

#!FILE consumer.nim
import producer, types
proc answer*(): int =
  let x = Box[int](value: make())
  x.value

#!FILE observer.nim
import producer
proc observe*(): int = make()

#!FILE transitive.nim
import observer, types
proc answerIndirectly*(): int =
  let x = Box[int](value: observe())
  x.value

#!FILE main.nim
import consumer, observer, transitive
echo answer(), " ", observe(), " ", answerIndirectly()
#!STEP expect: 42 42 42

#!FILE producer.nim
import types
proc make*(): int =
  let padding = 1000
  discard padding
  let x = Box[int](value: 42)
  x.value
#!STEP expect: 42 42 42; body-edit; modules: 3
#!STEP expect: 42 42 42; noop

#!FILE producer.nim
import types
proc make*(): int =
  let x = Box[int](value: 42)
  x.value
#!STEP expect: 42 42 42; body-edit; modules: 3
#!STEP expect: 42 42 42; noop
