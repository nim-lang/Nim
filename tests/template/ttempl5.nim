
import mtempl5

echo templ()

#bug #892

proc parse_to_close(value: string, index: int, open='(', close=')'): int =
    discard

# Call parse_to_close
template get_next_ident: stmt =
    discard "{something}".parse_to_close(0, open = '{', close = '}')

get_next_ident()


#identifier expected, but found '(open|open|open)'
