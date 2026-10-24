discard """
  description: '''IC: consumers of generic type offers track the instantiating module'''
"""

#? metamorphic

# A private body edit used to renumber a generic instance without changing any
# public signature or hook registration. Reusing that instance embeds its
# defining module's type ID, so the consumer needed an implementation edge and
# was rebuilt. Type IDs are content-derived now (`ast2nif.canonicalTypeItem`):
# the edit does not rename the instance, and only the edited module is rebuilt.

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
#!STEP expect: 42 42 42; body-edit; modules: 1
#!STEP expect: 42 42 42; noop

#!FILE producer.nim
import types
proc make*(): int =
  let x = Box[int](value: 42)
  x.value
#!STEP expect: 42 42 42; body-edit; modules: 1
#!STEP expect: 42 42 42; noop
