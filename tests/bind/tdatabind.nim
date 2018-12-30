discard """
  disabled: true
"""

import events
type
  TProperty*[T] = object of TObject
    getProc: proc(property: TProperty[T]): T {.nimcall.}
    setProc: proc(property: var TProperty[T], value: T) {.nimcall.}
    value: T
    ValueChanged*: TEventHandler
    Binders: seq[TProperty[T]]
    EEmitter: TEventEmitter
  # Not a descriptive name but it was that or TPropertyValueChangeEventArgs.
  TValueEventArgs[T] = object of TEventArgs
    Property*: TProperty[T]


proc newProperty*[T](value: T): TProperty[T] =
  var prop: TProperty[T]

  prop.EEmitter = initEventEmitter()
  prop.Binders = @[]
  prop.ValueChanged = initEventHandler("ValueChanged")
  prop.value = value

  proc getter(property: TProperty[T]): T =
   return property.value

  prop.getProc = getter

  proc setter(property: var TProperty[T], v: T) =
    property.value = v

    # fire event here
    var args: TValueEventArgs[T]
    args.Property = property
    property.EEmitter.emit(property.ValueChanged, args)

  prop.setProc = setter

  return prop

proc `prop`[T] (p: TProperty[T]): T =
  # I'm assuming this is trying to get a value from the property.
  # i.e. myVar = myProperty
  return p.getProc(p)

proc `~=`[T] (p: var TProperty[T], v: T) =
  # Assuming this is setting the value.
  p.setProc(p, v)

proc `$`[T] (p: TProperty[T]): string =
  var value = p.getProc(p)
  return $value

proc propertyBind*[T](p1: var TProperty[T], p2: var TProperty[T]) =
  p1.Binders.add(p2)

  # make handler -> handler[T] so trigger even more generics bugs ...
  proc handler(e: TEventArgs) =
    type TEA = TValueEventArgs[T]
    var args = TEA(e)
    var val = args.Property.getProc(p1)
    for i in countup(0, len(e.Property.ValueChanged.Binders) -1):
      var binded = e.Property.ValueChanged.Binders[i]
      binded.setProc(binded, val)

    echo("Property 1 has changed to " & $val)

  if p1.ValueChanged.containsHandler(handler) == false:
    addHandler(p1.ValueChanged, handler)

proc `->`[T](p1: var TProperty[T], p2: var TProperty[T]) =
  propertyBind(p2,p1)

when true:
  # Initial value testing
  var myProp = newProperty(5)

  echo(myProp)

  myProp ~= 7 # Temp operator until overloading of '=' is implemented.
  echo(myProp)

  # Binding testing

  var prop1 = newProperty(9)
  var prop2: TProperty[int]

  prop2 -> prop1 # Binds prop2 to prop1

  prop1 ~= 7
  echo(prop2) # Output: 7

