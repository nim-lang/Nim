# Test 13: forward types

type
  PSym = ref TSym

  TSym = object
    next: PSym

var s: PSym
