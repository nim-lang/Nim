block: # bug #26069
  type
    ConditionalField[T] = object
      when not (T is object):
        value: int
      else:
        value: string

    Obj = object
      value: int

  var objectField: ConditionalField[Obj]
  var nonObjectField: ConditionalField[int]

  doAssert typeof(objectField.value) is string
  doAssert typeof(nonObjectField.value) is int
