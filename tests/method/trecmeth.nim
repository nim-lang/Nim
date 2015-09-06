# Note: We only compile this to verify that code generation
# for recursive methods works, no code is being executed

type
  Obj = ref object of RootObj

# Mutual recursion

method alpha(x: Obj) {.base.}
method beta(x: Obj) {.base.}

method alpha(x: Obj) =
  beta(x)

method beta(x: Obj) =
  alpha(x)

# Simple recursion

method gamma(x: Obj) {.base.} =
  gamma(x)

