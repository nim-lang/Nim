# https://forum.nim-lang.org/t/9762

const foo = "abc"
case 'a'
of foo: echo "should error" #[tt.Error
   ^ type mismatch: got <string> but expected 'char']#
else: discard
