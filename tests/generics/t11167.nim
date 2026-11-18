# bug #11167: a `for` loop in a generic sees the `items` iterators of the
# module that declares the generic
import m11167

doAssert p(1) == 1
doAssert q(2) == 2
doAssert sum(Bag(data: @[3, 4])) == 10
