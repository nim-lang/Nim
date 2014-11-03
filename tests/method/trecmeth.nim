# Note: We only compile this to verify that code generation
# for recursive methods works, no code is being executed

type
  Obj = ref object of TObject

# Mutual recursion

method alpha(x: Obj)
method beta(x: Obj)

method alpha(x: Obj) =
  beta(x)

method beta(x: Obj) =
  alpha(x)

# Simple recursion

method gamma(x: Obj) =
  gamma(x)

