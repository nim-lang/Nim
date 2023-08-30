block: # issue #15760
  type
    Banana = object
    SpecialBanana = object
    
  proc getName(_: type Banana): string = "Banana"
  proc getName(_: type SpecialBanana): string = "SpecialBanana"

  proc x[T](): string = 
    const n = getName(T) # this one works
    result = n
    
  proc y(T: type): string =
    const n = getName(T) # this one failed to compile
    result = n

  doAssert x[SpecialBanana]() == "SpecialBanana"
  doAssert y(SpecialBanana) == "SpecialBanana"
