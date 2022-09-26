import typetraits

proc contained_type(s: typedesc): string = $genericParams(s)

doAssert contained_type(seq[int]) == "(int,)"
