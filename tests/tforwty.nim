# Test 13: forward types

type
  PSym = ref TSym

  TSym = record
    next: PSym

var s: PSym
