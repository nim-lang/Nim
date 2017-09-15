{.boundchecks: on.}
type Unchecked {.unchecked.} = array[0, char]

var x = cast[ptr Unchecked](alloc(100))
x[5] = 'x'
