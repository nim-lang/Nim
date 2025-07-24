type Foo = tuple[active: bool, index: int]


var f: Foo

# template result type during match stage
# f:var Foo
# a:Foo
# tyVar
# tyTuple
# after change to proc
# f:Foo
# a:Foo
# tyTuple
# tyTuple

template cursor(): var Foo = f
discard cursor()

