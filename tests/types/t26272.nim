# `when` expressions are valid type definition values.

template V: typedesc =
  when true: bool else: int

type Works = V()
type Works2 = (when true: bool else: int)
type Broken = when true: bool else: int

static:
  doAssert Works is bool
  doAssert Works2 is bool
  doAssert Broken is bool
