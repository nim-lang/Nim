# Stores extra data inside the SSL context.
import net

let ctx = newContext()

# Our unique index for storing foos
let fooIndex = ctx.getExtraDataIndex()
# And another unique index for storing foos
let barIndex = ctx.getExtraDataIndex()
echo "got indexes ", fooIndex, " ", barIndex

try:
  discard ctx.getExtraData(fooIndex)
  assert false
except IndexError:
  echo("Success")

type
  FooRef = ref object of RootRef
    foo: int

let foo = FooRef(foo: 5)
ctx.setExtraData(fooIndex, foo)
doAssert ctx.getExtraData(fooIndex).FooRef == foo

ctx.destroyContext()
