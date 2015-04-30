
# bug #2229

type Type1 = object
        id: int

type Type2 = object
    id: int

proc init(self: var Type1, a: int, b: ref Type2) =
    echo "1"

proc init(self: var Type2, a: int) =
    echo """
        Works when this proc commented out
        Otherwise error:
        test.nim(14, 4) Error: ambiguous call; both test.init(self: var Type1, a: int, b: ref Type2) and test.init(self: var Type1, a: int, b: ref Type2) match for: (Type1, int literal(1), ref Type2)
    """

var a: Type1
init(a, 1, (
    var b = new(Type2);
    b
))
