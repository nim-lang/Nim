# bug #9371: a concept type passed to a `type Concept` parameter
type Concept = concept x
func foo(T: type Concept): int = 1
doAssert Concept.foo == 1
