
# bug #2641

type MyChar = distinct char
const c:MyChar = MyChar('a')

type MyBool = distinct bool
const b:MyBool = MyBool(true)

type MyBoolSet = distinct set[bool]
const bs:MyBoolSet = MyBoolSet({true})

type MyCharSet= distinct set[char]
const cs:MyCharSet = MyCharSet({'a'})

type MyBoolSeq = distinct seq[bool]
const bseq:MyBoolSeq = MyBoolSeq(@[true, false])

type MyBoolArr = distinct array[3, bool]
const barr:MyBoolArr = MyBoolArr([true, false, true])
