# Stores extra data inside the SSL context.
import net

# Our unique index for storing foos
let fooIndex = getSslContextExtraDataIndex()
# And another unique index for storing foos
let barIndex = getSslContextExtraDataIndex()
echo "got indexes ", fooIndex, " ", barIndex

let ctx = newContext()
assert ctx.getExtraData(fooIndex) == nil
let foo: int = 5
ctx.setExtraData(fooIndex, cast[pointer](foo))
assert cast[int](ctx.getExtraData(fooIndex)) == foo
