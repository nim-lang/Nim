# ensure template pragma handling doesn't eagerly attempt to add an implicit
# 'pushed' pragma to the evaluation of any intermediate AST prior to
# substitution.
 
# bug #18113

import sequtils

{.push raises: [Defect].}

var a = toSeq([1, 2, 3, 5, 10]).filterIt(it > 5)

doAssert a.len == 1
doAssert a[0] == 10
