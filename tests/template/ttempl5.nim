
import mtempl5

echo templ()

#bug #892

proc parse_to_close(value: string, index: int, open='(', close=')'): int =
    discard

# Call parse_to_close
template get_next_ident: typed =
    discard "{something}".parse_to_close(0, open = '{', close = '}')

get_next_ident()


#identifier expected, but found '(open|open|open)'

#bug #880 (also example in the manual!)

template typedef(name: untyped, typ: typedesc) =
  type
    `T name`* {.inject.} = typ
    `P name`* {.inject.} = ref `T name`

typedef(myint, int)
var x: PMyInt
