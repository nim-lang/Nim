discard """
  msg: '''true
true
true
true
true
true'''
  output: '''true
true
true
true
true
true
R
R
R
R'''
"""

# bug #5360
import macros

type
  Order = enum
    R
  OrderAlias = Order

template getOrderTypeA(): typedesc = Order
template getOrderTypeB(): typedesc = OrderAlias

type
  OrderR    = getOrderTypeA()
  OrderG    = getOrderTypeB()

macro typeRep(a, b: typed): untyped =
  if sameType(a, b):
    echo "true"
  else:
    echo "false"

template test(a, b: typedesc) =
  when a is b:
    echo "true"
  else:
    echo "false"

test(OrderAlias, Order)
test(OrderR, Order)
test(OrderG, Order)

test(OrderR, OrderG)
test(OrderR, OrderAlias)
test(OrderG, OrderAlias)

typeRep(OrderAlias.R, Order.R)  # true
typeRep(OrderR.R, Order.R)      # true
typeRep(OrderG.R, Order.R)      # true

typeRep(OrderR.R, OrderAlias.R) # true
typeRep(OrderG.R, OrderAlias.R) # true
typeRep(OrderR.R, OrderG.R)     # true

echo OrderR.R      # R
echo OrderG.R      # R
echo OrderAlias.R  # R
echo Order.R       # R